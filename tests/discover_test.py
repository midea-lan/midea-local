"""Midea local discover test."""

from unittest.mock import MagicMock, patch

import pytest

from midealocal.discover import (
    _extract_mac,
    _parse_discover_response,
    bytes2port,
    discover,
    enum_all_broadcast,
    get_device_info,
    get_id_from_response,
)
from midealocal.exceptions import ElementMissing
from midealocal.security import LocalSecurity

SSID = b"net_ac_XXXX"
SN_TYPE1 = b"000000000" + b"12345678" + b"abbccddeeff" + b"0000"
DEVICE_ID = 12345
DEVICE_IP = "192.168.1.100"
DEVICE_PORT = 6444


def _build_reply(
    ssid: bytes = SSID,
    sn: bytes = SN_TYPE1,
    mac: bytes = bytes.fromhex("aabbccddeeff"),
) -> bytes:
    """Build a decrypted v2/v3 discover reply payload."""
    return (
        b"\x00" * 4
        + bytes([0x2C, 0x19, 0x00, 0x00])  # port 6444 little endian
        + sn
        + bytes([len(ssid)])
        + ssid
        + b"\x00" * 22  # pad up to mac_start = 63 + ssid_len
        + mac
    )


def _build_v2_packet(
    device_id: int = DEVICE_ID,
    encrypt_data: bytes | None = None,
) -> bytes:
    """Build a v2 discover response packet."""
    if encrypt_data is None:
        encrypt_data = bytes(LocalSecurity().aes_encrypt(_build_reply()))
    header = bytearray(40)
    header[0:2] = b"\x5a\x5a"
    header[20:26] = device_id.to_bytes(6, "little")
    return bytes(header) + encrypt_data + b"\x00" * 16


def _build_v3_packet(device_id: int = DEVICE_ID) -> bytes:
    """Build a v3 discover response packet wrapping a v2 packet."""
    return b"\x83\x70" + b"\x00" * 6 + _build_v2_packet(device_id) + b"\x00" * 16


def _mock_sock_with(data: bytes, ip: str = DEVICE_IP) -> MagicMock:
    """Return a socket mock whose recvfrom yields the given datagram."""
    sock = MagicMock()
    sock.recvfrom.return_value = (data, (ip, 6445))
    return sock


V1_XML = (
    b'<?xml version="1.0" encoding="utf-8"?><root><body>'
    b'<device port="6444" apc_sn="%s" apc_type="172"><pad/></device>'
    b"</body></root>"
)
ID_XML = (
    b'<?xml version="1.0" encoding="utf-8"?><root>'
    b'<smartDevice devId="12345678"><pad/></smartDevice></root>'
)


def _build_id_response(xml: bytes = ID_XML) -> bytearray:
    """Build a get_device_info response embedding an XML document."""
    return bytearray(b"\x00" * 64 + xml + b"\x00" * 16)


@pytest.mark.parametrize(
    ("reply", "ssid_len", "sn", "expected"),
    [
        # MAC taken from the reply bytes
        (_build_reply(), len(SSID), SN_TYPE1.decode(), "aabbccddeeff"),
        # Reply too short, 32-char serial: MAC from sn[16:28]
        (b"", 0, SN_TYPE1.decode(), "8abbccddeeff"),
        # Reply too short, 22-char serial: MAC not reported
        (b"", 0, "0" * 22, None),
        # Unknown serial number format
        (b"", 0, "bad_sn", None),
        # Extracted MAC is not a valid hex string
        (b"", 0, "0" * 16 + "ZZZZZZZZZZZZ" + "0000", None),
    ],
)
def test_extract_mac(
    reply: bytes,
    ssid_len: int,
    sn: str,
    expected: str | None,
) -> None:
    """Test _extract_mac branches."""
    assert _extract_mac(reply, ssid_len, sn) == expected


class TestParseDiscoverResponse:
    """_parse_discover_response test case."""

    @pytest.mark.parametrize(
        ("data", "protocol"),
        [
            (_build_v2_packet(), 2),
            (_build_v3_packet(), 3),
        ],
    )
    def test_parse_v2_v3(self, data: bytes, protocol: int) -> None:
        """Test parsing valid v2 and v3 responses."""
        device_id, device = _parse_discover_response(_mock_sock_with(data), {})
        assert device_id == DEVICE_ID
        assert device == {
            "device_id": DEVICE_ID,
            "type": 0xAC,
            "ip_address": DEVICE_IP,
            "port": DEVICE_PORT,
            "model": "12345678",
            "sn": SN_TYPE1.decode(),
            "protocol": protocol,
            "mac": "aabbccddeeff",
        }

    def test_parse_duplicate_device(self) -> None:
        """Test a device already in found_devices is skipped."""
        sock = _mock_sock_with(_build_v2_packet())
        assert _parse_discover_response(sock, {DEVICE_ID: {}}) == (0, None)

    def test_parse_unknown_header(self) -> None:
        """Test 5a5a at offset 8 but unknown leading bytes."""
        data = b"\xff" * 8 + _build_v2_packet()
        assert _parse_discover_response(_mock_sock_with(data), {}) == (0, None)

    def test_parse_decrypt_failure(self) -> None:
        """Test undecryptable encrypt_data is reported as unsupported."""
        data = _build_v2_packet(encrypt_data=b"\xde\xad" * 40)
        assert _parse_discover_response(_mock_sock_with(data), {}) == (0, None)

    def test_parse_garbage(self) -> None:
        """Test a datagram matching no known protocol."""
        data = b"\xff" * 120
        assert _parse_discover_response(_mock_sock_with(data), {}) == (0, None)

    @pytest.mark.parametrize(
        ("sn", "model"),
        [
            (SN_TYPE1.decode(), "12345678"),
            ("ABC" + "12345678" + "00000000000", "12345678"),
            ("odd_length_sn", ""),
        ],
    )
    def test_parse_v1(self, sn: str, model: str) -> None:
        """Test parsing a v1 XML broadcast response."""
        data = V1_XML % sn.encode()
        sock = _mock_sock_with(data)
        with patch(
            "midealocal.discover.get_device_info",
            return_value=_build_id_response(),
        ) as mock_info:
            device_id, device = _parse_discover_response(sock, {})
        mock_info.assert_called_once_with(DEVICE_IP, DEVICE_PORT)
        assert device_id == 0x78563412
        assert device == {
            "device_id": 0x78563412,
            "type": 0xAC,
            "ip_address": DEVICE_IP,
            "port": DEVICE_PORT,
            "model": model,
            "sn": sn,
            "protocol": 1,
            "mac": "8abbccddeeff" if len(sn) == 32 else None,
        }

    def test_parse_v1_missing_element(self) -> None:
        """Test a v1 XML response without a body/device element."""
        data = b'<?xml version="1.0" encoding="utf-8"?><root><body/></root>'
        with pytest.raises(ElementMissing):
            _parse_discover_response(_mock_sock_with(data), {})

    def test_parse_v1_childless_device_element(self) -> None:
        """Test a `<device .../>` element with no subelements is found.

        The element is present (root.find() does not return None) even
        though it has no subelements of its own, so it must be parsed
        successfully rather than raising ElementMissing.
        """
        data = (
            b'<?xml version="1.0" encoding="utf-8"?><root><body>'
            b'<device port="6444" apc_sn="%s" apc_type="172"/>'
            b"</body></root>" % SN_TYPE1
        )
        with patch(
            "midealocal.discover.get_device_info",
            return_value=_build_id_response(),
        ):
            device_id, device = _parse_discover_response(_mock_sock_with(data), {})
        assert device_id == 0x78563412
        assert device is not None
        assert device["sn"] == SN_TYPE1.decode()


class TestDiscover:
    """discover test case."""

    def test_discover_found_devices(self) -> None:
        """Test discovery finding one supported device then timing out."""
        sock = MagicMock()
        sock.recvfrom.side_effect = [
            (_build_v2_packet(), (DEVICE_IP, 6445)),
            (_build_v2_packet(), (DEVICE_IP, 6445)),  # duplicate: parsed as None
            TimeoutError,
        ]
        mock_socket = MagicMock()
        mock_socket.__enter__.return_value = sock
        with (
            patch("midealocal.discover.socket.socket", return_value=mock_socket),
            patch(
                "midealocal.discover.enum_all_broadcast",
                return_value=["192.168.1.255"],
            ),
        ):
            result = discover()
        assert list(result) == [DEVICE_ID]
        assert result[DEVICE_ID]["type"] == 0xAC
        assert sock.sendto.call_count == 2

    def test_discover_type_filter(self) -> None:
        """Test a device with a non-matching type is not returned."""
        sock = MagicMock()
        sock.recvfrom.side_effect = [
            (_build_v2_packet(), (DEVICE_IP, 6445)),
            TimeoutError,
        ]
        mock_socket = MagicMock()
        mock_socket.__enter__.return_value = sock
        with patch("midealocal.discover.socket.socket", return_value=mock_socket):
            result = discover(discover_type=[0xFF], ip_address=["192.168.1.255"])
        assert result == {}

    def test_discover_send_and_socket_errors(self) -> None:
        """Test sendto OSError and recvfrom OSError are survived."""
        sock = MagicMock()
        sock.sendto.side_effect = OSError("network unreachable")
        sock.recvfrom.side_effect = [OSError("bad recv"), TimeoutError]
        mock_socket = MagicMock()
        mock_socket.__enter__.return_value = sock
        with patch("midealocal.discover.socket.socket", return_value=mock_socket):
            result = discover(ip_address=["192.168.1.255"])
        assert result == {}


class TestGetIdFromResponse:
    """get_id_from_response test case."""

    def test_get_id(self) -> None:
        """Test extracting the device ID from an XML response."""
        assert get_id_from_response(_build_id_response()) == 0x78563412

    def test_get_id_missing_element(self) -> None:
        """Test an XML response without a smartDevice element."""
        xml = b'<?xml version="1.0" encoding="utf-8"?><root><other/></root>'
        with pytest.raises(ElementMissing):
            get_id_from_response(_build_id_response(xml))

    def test_get_id_childless_smartdevice_element(self) -> None:
        """Test a `<smartDevice devId="..."/>` element with no subelements.

        Mirrors test_parse_v1_childless_device_element: the element is
        present even though it has no subelements of its own, so the
        device ID must be extracted rather than raising ElementMissing.
        """
        xml = (
            b'<?xml version="1.0" encoding="utf-8"?><root>'
            b'<smartDevice devId="12345678"/></root>'
        )
        assert get_id_from_response(_build_id_response(xml)) == 0x78563412

    def test_get_id_not_xml(self) -> None:
        """Test a response without an embedded XML document."""
        assert get_id_from_response(bytearray(120)) == 0


@pytest.mark.parametrize(
    ("value_bytes", "expected"),
    [
        (None, 0),
        (b"", 0),
        (b"\x2c\x19", 6444),
        (bytes([0x2C, 0x19, 0x00, 0x00]), 6444),
        (bytearray([0x01, 0x00, 0x00, 0x01]), 0x01000001),
    ],
)
def test_bytes2port(value_bytes: bytes | bytearray | None, expected: int) -> None:
    """Test bytes2port."""
    assert bytes2port(value_bytes) == expected


class TestGetDeviceInfo:
    """get_device_info test case."""

    def test_get_device_info(self) -> None:
        """Test a successful device info exchange."""
        sock = MagicMock()
        sock.recv.return_value = b"\x12\x34"
        mock_socket = MagicMock()
        mock_socket.__enter__.return_value = sock
        with patch("midealocal.discover.socket.socket", return_value=mock_socket):
            assert get_device_info(DEVICE_IP, DEVICE_PORT) == bytearray(b"\x12\x34")
        sock.connect.assert_called_once_with((DEVICE_IP, DEVICE_PORT))
        sock.sendall.assert_called_once()

    @pytest.mark.parametrize("exception", [TimeoutError, OSError])
    def test_get_device_info_errors(self, exception: type[Exception]) -> None:
        """Test timeout and socket errors return an empty response."""
        sock = MagicMock()
        sock.connect.side_effect = exception
        mock_socket = MagicMock()
        mock_socket.__enter__.return_value = sock
        with patch("midealocal.discover.socket.socket", return_value=mock_socket):
            assert get_device_info(DEVICE_IP, DEVICE_PORT) == bytearray(0)


def _mock_ip(
    ip: str,
    network_prefix: int = 24,
    *,
    is_ipv4: bool = True,
) -> MagicMock:
    """Build an ifaddr IP mock."""
    mock = MagicMock()
    mock.is_IPv4 = is_ipv4
    mock.ip = ip
    mock.network_prefix = network_prefix
    return mock


def test_enum_all_broadcast() -> None:
    """Test enumerating broadcast addresses of all adapters."""
    adapter = MagicMock()
    adapter.ips = [
        _mock_ip("192.168.1.5"),  # valid
        _mock_ip("192.168.1.6"),  # same network: duplicate broadcast
        _mock_ip("10.0.0.1", network_prefix=8),  # valid
        _mock_ip("127.0.0.1", network_prefix=8),  # loopback
        _mock_ip("169.254.1.1", network_prefix=16),  # link local
        _mock_ip("8.8.8.8"),  # not private
        _mock_ip("192.168.2.1", network_prefix=32),  # prefix too long
        _mock_ip("fe80::1", is_ipv4=False),  # not IPv4
    ]
    with patch(
        "midealocal.discover.ifaddr.get_adapters",
        return_value=[adapter],
    ):
        assert enum_all_broadcast() == ["192.168.1.255", "10.255.255.255"]
