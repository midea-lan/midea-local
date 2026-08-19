"""Midea Local device test."""

from collections.abc import Callable
from types import SimpleNamespace
from typing import Any, ClassVar
from unittest.mock import MagicMock, patch

import pytest

from midealocal.cloud import DEFAULT_KEYS
from midealocal.const import DeviceType, ProtocolVersion
from midealocal.device import (
    MESSAGE_TYPE_INDEX,
    QUERY_TIMEOUT,
    RESPONSE_TIMEOUT,
    SKIP_ATTRIBUTE,
    AuthException,
    MessageResult,
    MideaDevice,
    NoSupportedProtocol,
    dict_translator,
    list_translator,
    multiplier_translator,
    precision_halves_translator,
    sentinel_translator,
)
from midealocal.exceptions import SocketException
from midealocal.message import MessageType


class _DictDevice(MideaDevice):
    """MideaDevice subclass exposing a class-level dict for lookup tests."""

    modes: ClassVar[dict[int, str]] = {1: "auto", 2: "cool"}


def _skip_attribute_translator(_: int) -> Any:  # noqa: ANN401
    return SKIP_ATTRIBUTE


@pytest.mark.parametrize(
    ("values", "kwargs", "index", "expected"),
    [
        pytest.param(["a", "b", "c"], {}, 1, "b", id="in_range"),
        pytest.param(["a", "b", "c"], {}, 5, None, id="out_of_range_defaults_to_none"),
        pytest.param(
            ["a", "b", "c"],
            {},
            -1,
            None,
            id="negative_index_does_not_wrap",
        ),
        pytest.param(
            ["a", "b", "c"],
            {"default": "unknown"},
            5,
            "unknown",
            id="custom_default",
        ),
        pytest.param(
            ["a", "b", "c"],
            {"offset": 1},
            1,
            "a",
            id="offset_shifts_raw_value",
        ),
        pytest.param(
            ["a", "b", "c"],
            {"min_index": 1},
            0,
            None,
            id="min_index_excludes_low_index",
        ),
        pytest.param(
            ["a", "b", "c"],
            {"key": lambda v: v // 10},
            20,
            "c",
            id="key_transforms_raw_value_first",
        ),
    ],
)
def test_list_translator(
    values: list[str],
    kwargs: dict[str, Any],
    index: int,
    expected: str | None,
) -> None:
    """Test list_translator's offset, min_index, default, and key arguments."""
    assert list_translator(values, **kwargs)(index) == expected


def test_dict_translator_found_returns_mapped_value() -> None:
    """Test dict_translator looks up a present key in the mapping."""
    assert dict_translator({1: "a", 2: "b"})(1) == "a"


def test_dict_translator_not_found_passes_value_through_by_default() -> None:
    """Test dict_translator with no default passes an absent key through."""
    assert dict_translator({1: "a"})(99) == 99


@pytest.mark.parametrize(
    "default",
    [
        pytest.param("unknown", id="explicit_string_default"),
        pytest.param(None, id="explicit_none_default_distinct_from_unset"),
    ],
)
def test_dict_translator_not_found_uses_explicit_default(
    default: Any,  # noqa: ANN401
) -> None:
    """Test dict_translator returns an explicit default for an absent key."""
    assert dict_translator({1: "a"}, default=default)(99) == default


@pytest.mark.parametrize(
    ("precision_halves", "value", "expected"),
    [
        pytest.param(True, 10, 5, id="halves_when_enabled"),
        pytest.param(False, 10, 10, id="passes_through_when_disabled"),
        pytest.param(None, 10, 10, id="passes_through_when_unset"),
    ],
)
def test_precision_halves_translator(
    precision_halves: bool | None,
    value: float,
    expected: float,
) -> None:
    """Test precision_halves_translator's enabled, disabled, and unset states."""
    assert precision_halves_translator(precision_halves)(value) == expected


@pytest.mark.parametrize(
    ("multiplier", "value", "expected"),
    [
        pytest.param(3.0, 2, 6, id="scales_and_rounds"),
        pytest.param(1.0, 2, 2, id="no_op_multiplier_skips_rounding"),
        pytest.param(3.0, None, None, id="none_value_passes_through"),
    ],
)
def test_multiplier_translator(
    multiplier: float,
    value: float | None,
    expected: float | None,
) -> None:
    """Test multiplier_translator's scaling, no-op, and None-value arguments."""
    assert multiplier_translator(multiplier)(value) == expected


@pytest.mark.parametrize(
    ("sentinel", "replacement", "value", "expected"),
    [
        pytest.param(0xFF, None, 0xFF, None, id="sentinel_value_is_replaced"),
        pytest.param(0xFF, None, 5, 5, id="other_values_pass_through"),
    ],
)
def test_sentinel_translator(
    sentinel: int,
    replacement: Any,  # noqa: ANN401
    value: int,
    expected: Any,  # noqa: ANN401
) -> None:
    """Test sentinel_translator's replacement and passthrough arguments."""
    assert sentinel_translator(sentinel, replacement)(value) == expected


def test_get_dict_key_by_value() -> None:
    """Test get_dict_key_by_value found, not-found and missing-dict cases."""
    assert _DictDevice.get_dict_key_by_value("modes", "cool") == 2
    assert _DictDevice.get_dict_key_by_value("modes", "unknown") is None
    with pytest.raises(ValueError, match="does not have a dict named 'missing'"):
        _DictDevice.get_dict_key_by_value("missing", "cool")


def test_fetch_v2_message() -> None:
    """Test fetch v2 message."""
    assert MideaDevice.fetch_v2_message(bytes([])) == ([], bytes([]))
    assert MideaDevice.fetch_v2_message(bytes([0x1])) == ([], bytes([0x1]))
    assert MideaDevice.fetch_v2_message(bytes([0x1] * 5 + [0x0] + [0x1] * 7)) == (
        [bytes([0x1])],
        bytes([0x1] * 4 + [0x0] + [0x1] * 7),
    )


def test_pre_process_message_short_message() -> None:
    """Test pre process message ignores messages shorter than the header."""
    # Some devices answer a query with fewer bytes than the 10-byte header
    # (observed: a 4-byte `01000000` from a 0xFA tower fan). Indexing the
    # message-type byte blindly raises IndexError, which aborts the whole
    # status parse, so short messages must be ignored instead.
    device = MideaDevice(
        name="Test Device",
        device_id=1,
        device_type=DeviceType.AC,
        ip_address="192.168.1.100",
        port=6444,
        token=DEFAULT_KEYS[99]["token"],
        key=DEFAULT_KEYS[99]["key"],
        device_protocol=ProtocolVersion.V3,
        model="test_model",
        subtype=1,
        attributes={},
        mac="1234567890ab",
    )
    for length in range(MESSAGE_TYPE_INDEX + 1):
        assert device.pre_process_message(bytearray([0x0] * length)) is False
        assert device._appliance_query is True


def test_parse_message_short_appliance_query_message_skips_process_message() -> None:
    """Test short appliance query messages are not processed as device status."""
    device = MideaDevice(
        name="Test Device",
        device_id=1,
        device_type=DeviceType.AC,
        ip_address="192.168.1.100",
        port=6444,
        token=DEFAULT_KEYS[99]["token"],
        key=DEFAULT_KEYS[99]["key"],
        device_protocol=ProtocolVersion.V3,
        model="test_model",
        subtype=1,
        attributes={},
        mac="1234567890ab",
    )
    encrypted_message = bytearray([0x0] * 72)
    encrypted_message[4] = 72
    with (
        patch.object(
            device._security,
            "decode_8370",
            return_value=([encrypted_message], b""),
        ),
        patch.object(
            device._security,
            "aes_decrypt",
            return_value=bytearray([0x01, 0x00, 0x00, 0x00]),
        ),
        patch.object(device, "process_message") as process_message_mock,
    ):
        assert device.parse_message(bytes([])) == MessageResult.SUCCESS

    process_message_mock.assert_not_called()
    assert device._appliance_query is True


class TestMideaDevice:
    """Midea device test case."""

    device: MideaDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea A1 Device setup."""
        self.device = MideaDevice(
            name="Test Device",
            device_id=1,
            device_type=DeviceType.AC,
            ip_address="192.168.1.100",
            port=6444,
            token=DEFAULT_KEYS[99]["token"],
            key=DEFAULT_KEYS[99]["key"],
            device_protocol=ProtocolVersion.V3,
            model="test_model",
            subtype=1,
            attributes={},
            mac="1234567890ab",
            serial_number="test_serial",
        )

    def test_initial_attributes(self) -> None:
        """Test initial attributes."""
        assert len(self.device.attributes) == 0
        assert self.device.name == "Test Device"
        assert self.device.device_id == 1
        assert self.device.device_type == 0xAC
        assert self.device.model == "test_model"
        assert self.device.subtype == 1
        assert self.device.mac == "1234567890ab"
        assert self.device.serial_number == "test_serial"

    def test_get_attribute(self) -> None:
        """Test get_attribute reads from the internal attributes dict."""
        self.device._attributes["power"] = True
        assert self.device.get_attribute("power") is True
        assert self.device.get_attribute("missing") is None

    def test_attributes_property(self) -> None:
        """Test attributes property stringifies keys from the internal dict."""
        self.device._attributes[DeviceType.AC] = True
        assert self.device.attributes == {str(DeviceType.AC): True}

    @pytest.mark.parametrize(
        (
            "initial_value",
            "message_kwargs",
            "translators",
            "default_transform",
            "expected_status",
            "expected_attribute",
        ),
        [
            pytest.param(
                None,
                {"mode": 2},
                {"mode": lambda v: f"translator-{v}"},
                lambda v: f"default-{v}",
                {"mode": "translator-2"},
                "translator-2",
                id="translator_wins_over_default_transform",
            ),
            pytest.param(
                None,
                {"mode": 2},
                None,
                lambda v: f"default-{v}",
                {"mode": "default-2"},
                "default-2",
                id="default_transform_used_when_no_translator",
            ),
            pytest.param(
                "previous",
                {},
                None,
                None,
                {},
                "previous",
                id="missing_field_is_ignored",
            ),
            pytest.param(
                None,
                {"mode": 2},
                None,
                None,
                {"mode": 2},
                2,
                id="status_and_attributes_stay_synchronized",
            ),
            pytest.param(
                "previous",
                {"mode": 2},
                {"mode": _skip_attribute_translator},
                None,
                {},
                "previous",
                id="skip_attribute_preserves_stored_value",
            ),
        ],
    )
    def test_update_attributes_from_message(
        self,
        initial_value: Any,  # noqa: ANN401
        message_kwargs: dict[str, Any],
        translators: dict[str, Callable[[Any], Any]] | None,
        default_transform: Callable[[Any], Any] | None,
        expected_status: dict[str, Any],
        expected_attribute: Any,  # noqa: ANN401
    ) -> None:
        """Test translator precedence, defaults, missing fields, and SKIP_ATTRIBUTE."""
        self.device._attributes = {"mode": initial_value}
        message = SimpleNamespace(**message_kwargs)
        new_status = self.device.update_attributes_from_message(
            message,
            translators=translators,
            default_transform=default_transform,
        )
        assert new_status == expected_status
        assert self.device._attributes["mode"] == expected_attribute

    def test_celsius_to_fahrenheit(self) -> None:
        """Test celsius_to_fahrenheit conversion and pass-through branches."""
        assert self.device.celsius_to_fahrenheit(20, is_fahrenheit=True) == 68
        assert self.device.celsius_to_fahrenheit(20, is_fahrenheit=False) == 20
        # is_fahrenheit=None falls back to the class default (False), so the
        # value passes through unconverted.
        assert self.device.celsius_to_fahrenheit(20) == 20

    def test_fahrenheit_to_celsius(self) -> None:
        """Test fahrenheit_to_celsius conversion and pass-through branches."""
        assert self.device.fahrenheit_to_celsius(68, is_fahrenheit=True) == 20
        assert self.device.fahrenheit_to_celsius(68, is_fahrenheit=False) == 68
        assert self.device.fahrenheit_to_celsius(68) == 68

    @pytest.mark.parametrize(
        ("exc", "result", "socket_is_none"),
        [
            (TimeoutError, False, True),
            (OSError, False, True),
            (AuthException, False, True),
            (NoSupportedProtocol, False, True),
            (SocketException, False, True),
            (None, True, False),
        ],
    )
    def test_connect(
        self,
        exc: Exception,
        result: bool,
        socket_is_none: bool,
    ) -> None:
        """Test connect."""
        # Pre-populate buffer to confirm the failure path runs close_socket(),
        # which clears it (the old code only nulled _socket).
        self.device._buffer = b"stale"
        with (
            patch("socket.socket.connect", side_effect=exc),
            patch.object(self.device, "authenticate"),
            patch.object(self.device, "refresh_status"),
        ):
            assert self.device.connect(check_protocol=True) is result
            assert self.device.available is result
            assert (self.device._socket is None) is socket_is_none
            if socket_is_none:
                # close_socket() was invoked: it also resets the buffer.
                assert self.device._buffer == b""

    def test_connect_generic_exception(self) -> None:
        """Test connect with generic exception."""
        self.device._buffer = b"stale"
        with patch("socket.socket.connect") as connect_mock:
            connect_mock.side_effect = Exception()

            assert self.device.connect() is False
            assert self.device.available is False
            assert self.device._socket is None
            assert self.device._buffer == b""

    def test_authenticate(self) -> None:
        """Test authenticate."""
        socket_mock = MagicMock()
        with patch.object(
            socket_mock,
            "recv",
            side_effect=[
                bytearray(),
                bytearray(
                    [0x00] * (8 + 32)
                    + [
                        0xCE,
                        0x8C,
                        0xFB,
                        0xF1,
                        0x65,
                        0x90,
                        0xD1,
                        0x07,
                        0x6D,
                        0xF8,
                        0x3A,
                        0x3B,
                        0x67,
                        0xCC,
                        0x6B,
                        0xB6,
                        0x80,
                        0xF6,
                        0x0E,
                        0x3D,
                        0xFF,
                        0xE7,
                        0x74,
                        0x92,
                        0x14,
                        0x4D,
                        0xE9,
                        0xD2,
                        0xD5,
                        0x74,
                        0x7E,
                        0x6F,
                    ],
                ),
            ],
        ):
            self.device._socket = None
            with pytest.raises(SocketException):
                self.device.authenticate()

            self.device._socket = socket_mock
            with pytest.raises(AuthException):
                self.device.authenticate()

            self.device.authenticate()

    def test_send_message(self) -> None:
        """Test send message."""
        socket_mock = MagicMock()
        with patch.object(
            socket_mock,
            "recv",
            side_effect=[
                bytearray(
                    [0x00] * (8 + 32)
                    + [
                        0xCE,
                        0x8C,
                        0xFB,
                        0xF1,
                        0x65,
                        0x90,
                        0xD1,
                        0x07,
                        0x6D,
                        0xF8,
                        0x3A,
                        0x3B,
                        0x67,
                        0xCC,
                        0x6B,
                        0xB6,
                        0x80,
                        0xF6,
                        0x0E,
                        0x3D,
                        0xFF,
                        0xE7,
                        0x74,
                        0x92,
                        0x14,
                        0x4D,
                        0xE9,
                        0xD2,
                        0xD5,
                        0x74,
                        0x7E,
                        0x6F,
                    ],
                ),
            ],
        ):
            self.device._socket = socket_mock
            self.device.authenticate()
            self.device.send_message(bytes([0x0] * 20))
            self.device._device_protocol_version = ProtocolVersion.V2
            self.device.send_message(bytes([0x0] * 20))

    def test_send_message_v2_socket_none(self) -> None:
        """Test send_message_v2 raises SocketException when socket is None."""
        self.device._socket = None
        with pytest.raises(SocketException):
            self.device.send_message_v2(bytes([0x0] * 20))

    def test_send_message_v2_query_sets_timeout(self) -> None:
        """Test send_message_v2 sets QUERY_TIMEOUT when query is True."""
        socket_mock = MagicMock()
        self.device._socket = socket_mock
        self.device.send_message_v2(bytes([0x0] * 20), query=True)
        socket_mock.settimeout.assert_called_once_with(QUERY_TIMEOUT)
        socket_mock.send.assert_called_once()

    @pytest.mark.parametrize(
        "exc",
        [TimeoutError, ConnectionResetError, OSError, ValueError],
    )
    def test_send_message_v2_send_errors_reraised(self, exc: type[Exception]) -> None:
        """Test send_message_v2 logs and re-raises every socket.send failure."""
        socket_mock = MagicMock()
        socket_mock.send.side_effect = exc("boom")
        self.device._socket = socket_mock
        with pytest.raises(exc):
            self.device.send_message_v2(bytes([0x0] * 20))

    def test_build_send(self) -> None:
        """Test build_send serializes, packages and sends the command."""
        cmd = MagicMock()
        cmd.serialize.return_value = bytes([0x01, 0x02])
        with patch.object(self.device, "send_message") as send_mock:
            self.device.build_send(cmd, query=True)
        cmd.serialize.assert_called_once()
        send_mock.assert_called_once()
        assert send_mock.call_args.kwargs["query"] is True

    def test_refresh_status(self) -> None:
        """Test refresh status."""
        with pytest.raises(NotImplementedError):
            self.device.refresh_status()  # build_query not implemented

        socket_mock = MagicMock()
        with (
            patch.object(self.device, "build_query", return_value=[]),
            patch.object(
                socket_mock,
                "recv",
                side_effect=[
                    bytearray([]),
                    bytearray([0x0]),
                    bytearray([0x0]),
                    bytearray([0x0]),
                    bytearray([0x0]),
                    TimeoutError(),
                ],
            ),
            patch.object(self.device, "build_send", return_value=None),
            patch.object(
                self.device,
                "parse_message",
                side_effect=[
                    MessageResult.SUCCESS,
                    MessageResult.PADDING,
                    MessageResult.SUCCESS,
                    MessageResult.ERROR,
                ],
            ),
        ):
            self.device._socket = None
            with pytest.raises(SocketException):
                self.device.refresh_status(True)

            self.device._socket = socket_mock
            with pytest.raises(OSError, match=r"Connection closed by peer\."):
                self.device.refresh_status(True)

            self.device.refresh_status(True)  # SUCCESS
            self.device.refresh_status(True)  # PADDING

            with pytest.raises(NoSupportedProtocol):
                self.device.refresh_status(True)  # ERROR
            with pytest.raises(NoSupportedProtocol):
                self.device.refresh_status(True)  # Timeout
            with pytest.raises(NoSupportedProtocol):
                self.device.refresh_status(True)  # Unsupported protocol

    def test_parse_message(self) -> None:
        """Test parse message."""
        with (
            patch.object(self.device._security, "decode_8370", return_value=([], b"")),
            patch.object(
                self.device._security,
                "aes_decrypt",
                return_value=bytearray([0x1] * 16),
            ),
            patch.object(
                self.device,
                "fetch_v2_message",
                side_effect=[
                    ([b"ERROR"], b""),
                    (
                        [
                            bytearray([0x0, 0x0, 0x01, 0x10, 0x0, 0x0]),
                            bytearray([0x0] * 4 + [0x8, 0x1] + [0x1] * 56),
                            bytearray([0x0] * 4 + [0x8, 0x1] + [0x1] * 56),
                            bytearray([0x0] * 4 + [0x8, 0x1] + [0x1] * 56),
                            bytearray([0x0] * 4 + [0x2, 0x1] + [0x1] * 56),
                            bytearray([0x1] * 50),
                        ],
                        b"",
                    ),
                ],
            ),
        ):
            assert self.device.parse_message(bytes([])) == MessageResult.PADDING
            self.device._device_protocol_version = ProtocolVersion.V2
            assert self.device.parse_message(bytes([])) == MessageResult.ERROR
            with patch.object(
                self.device,
                "process_message",
                side_effect=[{"power": True}, {}, NotImplementedError()],
            ):
                assert self.device.parse_message(bytes([])) == MessageResult.SUCCESS

    def test_pre_process_message(self) -> None:
        """Test pre process message."""
        assert self.device.pre_process_message(bytearray([0x0] * 10)) is True
        assert (
            self.device.pre_process_message(
                bytearray([0x0] * 9 + [MessageType.query_appliance] + [0x1] * 10),
            )
            is False
        )
        assert self.device._appliance_query is False

    def test_process_message(self) -> None:
        """Test process message."""
        with pytest.raises(NotImplementedError):
            self.device.process_message(bytes([]))

    def test_send_command(self) -> None:
        """Test send command."""
        with patch.object(self.device, "build_send", side_effect=[None, OSError()]):
            self.device.send_command(MessageType.query, bytearray([0x1] * 10))
            self.device.send_command(MessageType.query, bytearray([0x1] * 10))

    def test_send_heartbeat(self) -> None:
        """Test send heartbeat."""
        with patch.object(self.device, "send_message"):
            self.device.send_heartbeat()

    def test_register_update(self) -> None:
        """Test register update."""
        upd = MagicMock()
        assert len(self.device._updates) == 0
        self.device.register_update(upd)
        assert len(self.device._updates) == 1
        self.device.update_all({"status": True})
        upd.assert_called()

    def test_unregister_update(self) -> None:
        """Test unregister update."""
        upd = MagicMock()
        other_upd = MagicMock()

        # Unregistering a callback that was never registered is a no-op
        self.device.unregister_update(upd)
        assert len(self.device._updates) == 0

        # Register two callbacks, then unregister one
        self.device.register_update(upd)
        self.device.register_update(other_upd)
        assert len(self.device._updates) == 2

        self.device.unregister_update(upd)
        assert len(self.device._updates) == 1
        assert upd not in self.device._updates
        assert other_upd in self.device._updates

        # Remaining callback is still called on update_all
        self.device.update_all({"status": True})
        upd.assert_not_called()
        other_upd.assert_called_once_with({"status": True})

        # Unregister the last callback
        self.device.unregister_update(other_upd)
        assert len(self.device._updates) == 0

    def test_update_all_isolates_callback_errors(self) -> None:
        """Test a failing callback does not prevent others from being called."""
        failing_upd = MagicMock(side_effect=RuntimeError("event loop is closed"))
        ok_upd = MagicMock()
        self.device.register_update(failing_upd)
        self.device.register_update(ok_upd)
        self.device.update_all({"status": True})
        failing_upd.assert_called_once_with({"status": True})
        ok_upd.assert_called_once_with({"status": True})

    def test_parse_message_skips_update_all_when_not_running(self) -> None:
        """Test parse_message does not propagate status once device is closed.

        A message can already be in flight when close() is called from
        another thread; propagating it further (e.g. into a callback that
        touches an asyncio loop the consumer is tearing down) must be
        avoided.
        """
        upd = MagicMock()
        self.device.register_update(upd)
        self.device._device_protocol_version = ProtocolVersion.V2
        with (
            patch.object(
                self.device._security,
                "aes_decrypt",
                return_value=bytearray([0x1] * 16),
            ),
            patch.object(
                self.device,
                "fetch_v2_message",
                return_value=(
                    [bytearray([0x0] * 4 + [0x8, 0x1] + [0x1] * 56)],
                    b"",
                ),
            ),
            patch.object(
                self.device,
                "process_message",
                return_value={"power": True},
            ),
        ):
            self.device._is_run = False
            assert self.device.parse_message(bytes([])) == MessageResult.SUCCESS
            upd.assert_not_called()

            self.device._is_run = True
            assert self.device.parse_message(bytes([])) == MessageResult.SUCCESS
            upd.assert_called_once_with({"power": True})

    def test_open(self) -> None:
        """Test open."""
        with (
            patch.object(self.device, "connect", return_value=False),
            patch.object(self.device, "run"),
        ):
            self.device.open()
            assert self.device._is_run is True

    def test_close(self) -> None:
        """Test close."""
        with patch.object(self.device, "_socket") as socket_mock:
            self.device._is_run = True
            self.device.close()
            assert self.device._is_run is False
            socket_mock.close.assert_called()

    def test_close_socket_close_oserror(self) -> None:
        """Test close_socket swallows OSError raised by socket.close()."""
        socket_mock = MagicMock()
        socket_mock.close.side_effect = OSError("already closed")
        self.device._socket = socket_mock
        self.device.close_socket()
        socket_mock.close.assert_called_once()
        assert self.device._socket is None

    def test_set_ip(self) -> None:
        """Test set ip."""
        with patch.object(self.device, "_socket") as socket_mock:
            assert self.device._ip_address == "192.168.1.100"
            self.device.set_ip_address("10.0.0.1")
            socket_mock.close.assert_called()
            assert self.device._ip_address == "10.0.0.1"

    def test_set_mac(self) -> None:
        """Test set mac."""
        assert self.device.mac == "1234567890ab"
        self.device.set_mac("9234567890ab")
        assert self.device.mac == "9234567890ab"

    def test_enable_device(self) -> None:
        """Test deprecated enable_device delegates to set_available."""
        with pytest.warns(DeprecationWarning, match="enable_device"):
            self.device.enable_device(True)
        assert self.device.available is True
        with pytest.warns(DeprecationWarning, match="enable_device"):
            self.device.enable_device(False)
        assert self.device.available is False

    def test_should_run(self) -> None:
        """Test _should_run reflects _is_run."""
        self.device._is_run = True
        assert self.device._should_run() is True
        self.device._is_run = False
        assert self.device._should_run() is False

    def test_set_refresh_interval(self) -> None:
        """Test set_refresh_interval."""
        self.device.set_refresh_interval(60)
        assert self.device._refresh_interval == 60

    def test_check_refresh(self) -> None:
        """Test _check_refresh triggers refresh_status once the interval elapses."""
        self.device._refresh_interval = 30
        self.device._previous_refresh = 0.0
        with patch.object(self.device, "refresh_status") as refresh_mock:
            # Not enough time elapsed yet: no refresh.
            self.device._check_refresh(10.0)
            refresh_mock.assert_not_called()
            assert self.device._previous_refresh == 0.0

            # Interval elapsed: refresh triggered and previous_refresh updated.
            self.device._check_refresh(30.0)
            refresh_mock.assert_called_once()
            assert self.device._previous_refresh == 30.0

    def test_check_heartbeat(self) -> None:
        """Test _check_heartbeat triggers send_heartbeat once the interval elapses."""
        self.device._heartbeat_interval = 10
        self.device._previous_heartbeat = 0.0
        with patch.object(self.device, "send_heartbeat") as heartbeat_mock:
            self.device._check_heartbeat(5.0)
            heartbeat_mock.assert_not_called()
            assert self.device._previous_heartbeat == 0.0

            self.device._check_heartbeat(10.0)
            heartbeat_mock.assert_called_once()
            assert self.device._previous_heartbeat == 10.0

    def test_connect_loop(self) -> None:
        """Test _connect_loop retries with backoff and stops when told to."""
        self.device._is_run = True
        self.device._socket = None
        sleep_calls: list[float] = []

        def fake_sleep(seconds: float) -> None:
            sleep_calls.append(seconds)
            # Simulate close() happening concurrently during the backoff sleep.
            self.device._is_run = False

        with (
            patch.object(self.device, "connect", return_value=False),
            patch("time.sleep", side_effect=fake_sleep),
        ):
            self.device._connect_loop()

        assert sleep_calls == [1]
        assert self.device._socket is None

    def test_run_breaks_when_stopped_during_connect_loop(self) -> None:
        """Test run exits immediately if closed while _connect_loop runs."""
        self.device._is_run = True
        with patch.object(
            self.device,
            "_connect_loop",
            side_effect=lambda: setattr(self.device, "_is_run", False),
        ):
            self.device.run()
        assert self.device._is_run is False

    def test_run_socket_none_raises_socket_exception(self) -> None:
        """Test run treats a None socket mid-loop as a SocketException."""
        self.device._is_run = True
        self.device._socket = None
        with (
            patch.object(self.device, "_connect_loop"),
            patch.object(
                self.device,
                "close_socket",
                side_effect=lambda: setattr(self.device, "_is_run", False),
            ) as close_mock,
        ):
            self.device.run()
        close_mock.assert_called_once()

    def test_run_message_loop_branches(self) -> None:
        """Test run's recv/parse result handling and every exception branch."""
        self.device._is_run = True
        self.device._socket = MagicMock()

        connect_loop_calls = {"n": 0}

        def fake_connect_loop() -> None:
            connect_loop_calls["n"] += 1
            if connect_loop_calls["n"] > 5:
                self.device._is_run = False

        check_refresh_side_effect = (
            [None, None, None, None]  # passes 1-4: no refresh due
            + [NoSupportedProtocol()]  # pass 5, iter a: continue
            + [None]  # pass 5, iter b: refresh ok, then SUCCESS recv
            + [None] * RESPONSE_TIMEOUT  # pass 5, iters c..: timeouts
        )
        recv_side_effect = [
            b"",  # pass 1: empty -> ConnectionResetError
            b"\x01",  # pass 2: parsed as ERROR
            OSError("boom"),  # pass 3
            ValueError("boom"),  # pass 4
            b"\x01",  # pass 5, iter b: parsed as SUCCESS
            *([TimeoutError()] * RESPONSE_TIMEOUT),  # pass 5: hits the threshold
        ]
        parse_message_side_effect = [MessageResult.ERROR, MessageResult.SUCCESS]

        with (
            patch.object(self.device, "_connect_loop", side_effect=fake_connect_loop),
            patch.object(self.device, "close_socket"),
            patch.object(
                self.device,
                "_check_refresh",
                side_effect=check_refresh_side_effect,
            ),
            patch.object(self.device, "_check_heartbeat"),
            patch.object(self.device._socket, "recv", side_effect=recv_side_effect),
            patch.object(
                self.device,
                "parse_message",
                side_effect=parse_message_side_effect,
            ),
            patch("time.sleep"),
        ):
            self.device.run()

        assert connect_loop_calls["n"] == 6
        assert self.device._is_run is False

    def test_set_attribute(self) -> None:
        """Test set_attribute raises NotImplementedError."""
        with pytest.raises(NotImplementedError):
            self.device.set_attribute("power", True)

    @staticmethod
    def _make_device(serial_number: str | None) -> MideaDevice:
        return MideaDevice(
            name="Test Device",
            device_id=1,
            device_type=DeviceType.AC,
            ip_address="192.168.1.100",
            port=6444,
            token=DEFAULT_KEYS[99]["token"],
            key=DEFAULT_KEYS[99]["key"],
            device_protocol=ProtocolVersion.V3,
            model="test_model",
            subtype=1,
            attributes={},
            mac="1234567890ab",
            serial_number=serial_number,
        )

    def test_serial_number_normalization(self) -> None:
        """Test serial_number normalization in __init__."""
        assert self._make_device("another_serial").serial_number == "another_serial"
        # Empty, NUL-padded or None serials normalize to None (mirrors mac).
        assert self._make_device("").serial_number is None
        assert self._make_device("\x00" * 32).serial_number is None
        assert self._make_device(None).serial_number is None
        assert self._make_device("ABC123\x00\x00").serial_number == "ABC123"
