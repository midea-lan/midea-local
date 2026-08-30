"""Midea local security test."""

from hashlib import md5, sha256

import pytest
from Crypto.Util.strxor import strxor

from midealocal.const import MAX_DOUBLE_BYTE_VALUE
from midealocal.exceptions import (
    CannotAuthenticate,
    DataSignDoesntMatch,
    DataSignWrongType,
    DataUnexpectedLength,
    MessageWrongFormat,
)
from midealocal.security import (
    MSGTYPE_ENCRYPTED_REQUEST,
    MSGTYPE_HANDSHAKE_REQUEST,
    CloudSecurity,
    LocalSecurity,
    MeijuCloudSecurity,
    MideaAirSecurity,
    MSmartCloudSecurity,
)


class TestCloudSecurity:
    """Test CloudSecurity."""

    def test_sign_without_hmac_key(self) -> None:
        """Test sign returns None when no hmac key is set."""
        security = CloudSecurity("login_key", None, None)
        assert security.sign("http://url", "data", "random") is None

    def test_sign_with_hmac_key(self) -> None:
        """Test sign returns an HMAC-SHA256 digest when a hmac key is set."""
        security = CloudSecurity("login_key", "iot_key", "hmac_key")
        assert (
            security.sign("http://url", {"a": 1}, "random")
            == "b38fc0eb59f2e81489420451ffeb61bc264db68e94bd84e527b888232c2261c7"
        )

    def test_encrypt_password(self) -> None:
        """Test encrypt_password returns the double SHA256 digest."""
        security = CloudSecurity("login_key", None, None)
        assert (
            security.encrypt_password("login_id", "password")
            == "00ddd4c28473e3982eba98c7817a115f28ff8b81f210a1afcdb225daa85b1694"
        )

    def test_get_deviceid(self) -> None:
        """Test get_deviceid derives a stable id from the username."""
        assert CloudSecurity.get_deviceid("user") == "aab054edd91d7082"

    def test_encrypt_iam_password_unimplemented(self) -> None:
        """Test encrypt_iam_password is not implemented in base class."""
        security = CloudSecurity("login_key", None, None)
        with pytest.raises(NotImplementedError):
            security.encrypt_iam_password("login_id", "password")

    def test_get_udp_id(self) -> None:
        """Test get_udp_id for every method."""
        assert (
            CloudSecurity.get_udp_id(123456789, 0) == "c0df1eef309df487f3061c8189f35c79"
        )
        assert (
            CloudSecurity.get_udp_id(123456789, 1) == "505407553cbc909df7d36b82967ace2e"
        )
        assert (
            CloudSecurity.get_udp_id(123456789, 2) == "8011a3aa5116c19f17161815770eb6e4"
        )
        assert CloudSecurity.get_udp_id(123456789, 3) is None

    def test_aes_encrypt_decrypt_empty_data(self) -> None:
        """Test AES encrypt/decrypt with empty data."""
        security = CloudSecurity("login_key", None, None)
        assert security.aes_encrypt(b"") == b""
        assert security.aes_decrypt(b"") == ""

    def test_aes_encrypt_decrypt_missing_key(self) -> None:
        """Test AES encrypt/decrypt raise when no key is available."""
        security = CloudSecurity("login_key", None, None)
        security._aes_key = None  # type: ignore[assignment]
        security._aes_iv = None  # type: ignore[assignment]
        with pytest.raises(ValueError, match="Encrypt need a key"):
            security.aes_encrypt(b"data")
        with pytest.raises(ValueError, match="Encrypt need a key"):
            security.aes_decrypt(b"data")

    def test_aes_encrypt_decrypt_instance_keys(self) -> None:
        """Test AES CBC round trip with instance keys set from strings."""
        security = CloudSecurity("login_key", None, None)
        security.set_aes_keys("0123456789abcdef", "fedcba9876543210")
        encrypted = security.aes_encrypt(b"hello world")
        assert security.aes_decrypt(encrypted) == "hello world"

    def test_aes_ecb_with_fixed_key(self) -> None:
        """Test AES ECB round trip with a fixed key and no IV."""
        security = CloudSecurity(
            "login_key",
            None,
            None,
            fixed_key=10864842703515613082,
        )
        encrypted = security.aes_encrypt_with_fixed_key(b"hello world")
        assert security.aes_decrypt_with_fixed_key(encrypted.hex()) == "hello world"

    def test_aes_encrypt_hex_string_data(self) -> None:
        """Test AES encrypt accepts hex string data."""
        security = CloudSecurity(
            "login_key",
            None,
            None,
            fixed_key=10864842703515613082,
        )
        from_string = security.aes_encrypt(
            b"hello world".hex(),
            key=security._fixed_key,
        )
        from_bytes = security.aes_encrypt_with_fixed_key(b"hello world")
        assert from_string == from_bytes


class TestMeijuCloudSecurity:
    """Test MeijuCloudSecurity."""

    def test_encrypt_iam_password(self) -> None:
        """Test encrypt_iam_password returns the double MD5 digest."""
        security = MeijuCloudSecurity("login_key", "iot_key", "hmac_key")
        assert (
            security.encrypt_iam_password("login_id", "password")
            == "696d29e0940a4957748fe3fc9efd22a3"
        )


class TestMSmartCloudSecurity:
    """Test MSmartCloudSecurity."""

    def test_encrypt_iam_password(self) -> None:
        """Test encrypt_iam_password combines MD5 and SHA256 digests."""
        security = MSmartCloudSecurity("login_key", "iot_key", "hmac_key")
        assert (
            security.encrypt_iam_password("login_id", "password")
            == "81d4397408a49d9c17345197932e141110671cbb27961a6d733c0f5843b50571"
        )

    def test_set_aes_keys(self) -> None:
        """Test set_aes_keys decrypts key and iv with login key material."""
        security = MSmartCloudSecurity("login_key", "iot_key", "hmac_key")
        key_digest = sha256(b"login_key").hexdigest()
        tmp_key = key_digest[:16].encode("ascii")
        tmp_iv = key_digest[16:32].encode("ascii")
        encrypted_key = security.aes_encrypt(b"secret_aes_key00", tmp_key, tmp_iv).hex()
        encrypted_iv = security.aes_encrypt(b"secret_aes_iv000", tmp_key, tmp_iv).hex()
        security.set_aes_keys(encrypted_key, encrypted_iv)
        assert security._aes_key == b"secret_aes_key00"
        assert security._aes_iv == b"secret_aes_iv000"


class TestMideaAirSecurity:
    """Test MideaAirSecurity."""

    def test_sign_wrong_type(self) -> None:
        """Test sign raises with a string payload."""
        security = MideaAirSecurity("login_key")
        with pytest.raises(DataSignWrongType):
            security.sign("http://url", "data", "random")

    def test_sign_valid(self) -> None:
        """Test sign hashes the url path with the sorted payload."""
        security = MideaAirSecurity("login_key")
        assert (
            security.sign("http://host/v1/path", {"b": "2", "a": "1"}, "random")
            == "caf39a6385856d05eeb52e12657c753c95199834960a6b8ffdd69cd2c0b9c195"
        )

    def test_decrypt_appliance_lua(self) -> None:
        """Test the legacy lua blob decrypts with the md5(app_key) ECB key."""
        security = MideaAirSecurity("login_key")
        # md5 mirrors the production key derivation; not used for security here.
        key = md5(b"login_key").hexdigest()[:16].encode("ascii")  # noqa: S324
        encrypted = security.aes_encrypt(b"function test() return 1 end", key).hex()
        assert (
            security.decrypt_appliance_lua(encrypted) == "function test() return 1 end"
        )


class TestLocalSecurity:
    """Test LocalSecurity."""

    security: LocalSecurity

    @pytest.fixture(autouse=True)
    def _setup_security(self) -> None:
        """Create security object for test."""
        self.security = LocalSecurity()

    def _authenticate(self) -> None:
        """Set the TCP key via a valid handshake response."""
        key = bytes(range(32))
        plain = bytes(range(32, 64))
        response = self.security.aes_cbc_encrypt(plain, key) + sha256(plain).digest()
        assert self.security.tcp_key(response, key) == strxor(plain, key)

    def test_aes_encrypt_decrypt_roundtrip(self) -> None:
        """Test AES ECB encrypt/decrypt round trip."""
        raw = bytes(range(24))
        encrypted = self.security.aes_encrypt(raw)
        assert self.security.aes_decrypt(encrypted) == bytearray(raw)

    def test_aes_decrypt_invalid_data(self) -> None:
        """Test AES decrypt with malformed data returns an empty result."""
        assert self.security.aes_decrypt(bytes(10)) == bytearray(0)

    def test_aes_cbc_roundtrip(self) -> None:
        """Test AES CBC encrypt/decrypt round trip."""
        key = bytes(range(16))
        raw = bytes(range(32))
        encrypted = self.security.aes_cbc_encrypt(raw, key)
        assert self.security.aes_cbc_decrypt(encrypted, key) == raw

    def test_encode32_data(self) -> None:
        """Test encode32_data returns the salted MD5 digest."""
        assert (
            self.security.encode32_data(b"hello").hex()
            == "09a02ba1291000b060665e186676fc7a"
        )

    def test_tcp_key_error_response(self) -> None:
        """Test tcp_key with an error response."""
        with pytest.raises(CannotAuthenticate):
            self.security.tcp_key(b"ERROR", bytes(32))

    def test_tcp_key_wrong_length(self) -> None:
        """Test tcp_key with an unexpected response length."""
        with pytest.raises(DataUnexpectedLength):
            self.security.tcp_key(bytes(10), bytes(32))

    def test_tcp_key_sign_mismatch(self) -> None:
        """Test tcp_key with a wrong signature."""
        key = bytes(range(32))
        plain = bytes(range(32, 64))
        response = self.security.aes_cbc_encrypt(plain, key) + bytes(32)
        with pytest.raises(DataSignDoesntMatch):
            self.security.tcp_key(response, key)

    def test_tcp_key_valid(self) -> None:
        """Test tcp_key with a valid handshake response."""
        self._authenticate()
        assert self.security._request_count == 0
        assert self.security._response_count == 0

    def test_encode_decode_8370_handshake(self) -> None:
        """Test 8370 round trip for an unencrypted handshake message."""
        data = bytes(range(10))
        packet = self.security.encode_8370(data, MSGTYPE_HANDSHAKE_REQUEST)
        packets, incomplete = self.security.decode_8370(packet)
        assert packets == [data]
        assert incomplete == b""

    def test_encode_decode_8370_encrypted(self) -> None:
        """Test 8370 round trip for an encrypted message with padding."""
        self._authenticate()
        data = bytes(range(20))
        packet = self.security.encode_8370(data, MSGTYPE_ENCRYPTED_REQUEST)
        packets, incomplete = self.security.decode_8370(packet)
        assert packets == [data]
        assert incomplete == b""
        assert self.security._request_count == 1
        assert self.security._response_count == 0

    def test_encode_8370_request_count_rollover(self) -> None:
        """Test the request count rolls over at the maximum value."""
        self._authenticate()
        self.security._request_count = MAX_DOUBLE_BYTE_VALUE - 1
        self.security.encode_8370(bytes(range(20)), MSGTYPE_ENCRYPTED_REQUEST)
        assert self.security._request_count == 0

    def test_decode_8370_multiple_packets_and_incomplete(self) -> None:
        """Test decoding two concatenated packets plus an incomplete tail."""
        self._authenticate()
        data1 = bytes(range(20))
        data2 = bytes(range(20, 45))
        packet1 = self.security.encode_8370(data1, MSGTYPE_ENCRYPTED_REQUEST)
        packet2 = self.security.encode_8370(data2, MSGTYPE_ENCRYPTED_REQUEST)
        packets, incomplete = self.security.decode_8370(packet1 + packet2 + b"\x83")
        assert packets == [data1, data2]
        assert incomplete == b"\x83"
        assert self.security._response_count == 1

    def test_decode_8370_short_data(self) -> None:
        """Test decoding data shorter than the minimum length."""
        assert self.security.decode_8370(b"\x83\x70") == ([], b"\x83\x70")

    def test_decode_8370_incomplete_packet(self) -> None:
        """Test decoding a packet shorter than its declared size."""
        self._authenticate()
        packet = self.security.encode_8370(bytes(range(20)), MSGTYPE_ENCRYPTED_REQUEST)
        truncated = packet[:-4]
        assert self.security.decode_8370(truncated) == ([], truncated)

    def test_decode_8370_wrong_header(self) -> None:
        """Test decoding a message without the 8370 header."""
        with pytest.raises(MessageWrongFormat, match="not an 8370 message"):
            self.security.decode_8370(bytes(8))

    def test_decode_8370_wrong_byte_4(self) -> None:
        """Test decoding a message with a wrong 4th header byte."""
        packet = bytes([0x83, 0x70, 0x00, 0x00, 0x21, 0x00, 0x00, 0x00])
        with pytest.raises(MessageWrongFormat, match="missing byte 4"):
            self.security.decode_8370(packet)

    def test_decode_8370_sign_mismatch(self) -> None:
        """Test decoding an encrypted message with a tampered signature."""
        self._authenticate()
        packet = bytearray(
            self.security.encode_8370(bytes(range(20)), MSGTYPE_ENCRYPTED_REQUEST),
        )
        packet[-1] ^= 0xFF
        with pytest.raises(DataSignDoesntMatch):
            self.security.decode_8370(bytes(packet))
