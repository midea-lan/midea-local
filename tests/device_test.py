"""Midea Lan device test."""

import contextlib
import threading
from typing import Any, ClassVar
from unittest.mock import MagicMock, patch

import pytest

from midealan.cloud import DEFAULT_KEYS
from midealan.const import DeviceType, ProtocolVersion
from midealan.device import (
    MESSAGE_TYPE_INDEX,
    QUERY_TIMEOUT,
    RESPONSE_TIMEOUT,
    AuthException,
    MessageResult,
    MideaDevice,
    NoSupportedProtocol,
)
from midealan.exceptions import SocketException
from midealan.message import MessageType


class _DictDevice(MideaDevice):
    """MideaDevice subclass exposing a class-level dict for lookup tests."""

    modes: ClassVar[dict[int, str]] = {1: "auto", 2: "cool"}


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

    def test_connect_failure_only_closes_its_own_socket(self) -> None:
        """Test failed connect cleanup does not close a replaced socket."""
        old_socket = MagicMock()
        new_socket: Any = MagicMock()

        def fail_after_socket_replaced(*_args: object) -> None:
            self.device._socket = new_socket
            raise OSError("connect failed")

        old_socket.connect.side_effect = fail_after_socket_replaced
        self.device._buffer = b"active"
        self.device._unsupported_protocol = ["new"]
        with (
            patch("socket.socket", return_value=old_socket),
            patch.object(self.device, "authenticate"),
            patch.object(self.device, "refresh_status"),
        ):
            assert self.device.connect(check_protocol=True) is False

        old_socket.close.assert_called_once()
        new_socket.close.assert_not_called()
        assert self.device._socket is new_socket
        assert self.device._buffer == b"active"
        assert self.device._unsupported_protocol == ["new"]

    def test_connect_v2_without_protocol_check(self) -> None:
        """Test successful V2 connect skips auth and protocol checks."""
        socket_mock = MagicMock()
        self.device._device_protocol_version = ProtocolVersion.V2
        with (
            patch("socket.socket", return_value=socket_mock),
            patch.object(self.device, "authenticate") as authenticate_mock,
            patch.object(self.device, "refresh_status") as refresh_mock,
        ):
            assert self.device.connect() is True

        authenticate_mock.assert_not_called()
        refresh_mock.assert_not_called()
        assert self.device.available is False

    def test_connect_loop_discards_connection_closed_before_install(self) -> None:
        """Test close() during connect prevents a connected socket from surviving."""
        socket_mock = MagicMock()
        close_started = threading.Event()
        close_finished = threading.Event()
        close_thread: threading.Thread | None = None

        def close_device() -> None:
            close_started.set()
            self.device.close()
            close_finished.set()

        def create_socket(*_args: object) -> MagicMock:
            nonlocal close_thread
            close_thread = threading.Thread(target=close_device)
            close_thread.start()
            assert close_started.wait(1)
            assert not close_finished.wait(0.01)
            return socket_mock

        self.device._is_run = True
        self.device._device_protocol_version = ProtocolVersion.V2
        with (
            patch("socket.socket", side_effect=create_socket),
            patch.object(self.device, "refresh_status"),
        ):
            self.device._connect_loop()

        assert close_thread is not None
        close_thread.join(1)
        assert close_finished.is_set()
        socket_mock.close.assert_called_once()
        assert self.device._socket is None
        assert self.device.available is False

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
        # One REAL status query rather than the appliance query, so the command count
        # per refresh_status is unchanged and the mock side_effects still line up.
        self.device._appliance_query = False
        real_cmd = MagicMock()
        with (
            patch.object(self.device, "build_query", return_value=[real_cmd]),
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

    def test_appliance_query_success_does_not_mask_failed_status_queries(
        self,
    ) -> None:
        """A successful appliance query must not hide every status query failing.

        The appliance query answers even when the device serves no status protocol.
        Counting it toward error_count left the total one short of len(cmds), so
        NoSupportedProtocol was never raised, connect() returned True, and the device
        came up available with data that never updated.
        """
        socket_mock = MagicMock()
        real_cmd = MagicMock()
        with (
            patch.object(self.device, "build_query", return_value=[real_cmd]),
            patch.object(
                socket_mock,
                "recv",
                side_effect=[bytearray([0x0]), TimeoutError()],
            ),
            patch.object(self.device, "build_send", return_value=None),
            patch.object(
                self.device,
                "parse_message",
                side_effect=[MessageResult.SUCCESS],
            ),
        ):
            self.device._socket = socket_mock
            assert self.device._appliance_query is True
            with pytest.raises(NoSupportedProtocol):
                self.device.refresh_status(True)

    def test_appliance_query_failure_alone_does_not_fail_the_device(self) -> None:
        """A failed appliance query must not count against the status queries.

        Ungated, its timeout increments error_count to 1, which already equals
        len(real_cmds) on the first iteration -- so a device whose real status query
        works perfectly well would be declared to support no protocol at all.
        """
        socket_mock = MagicMock()
        real_cmd = MagicMock()
        with (
            patch.object(self.device, "build_query", return_value=[real_cmd]),
            patch.object(
                socket_mock,
                "recv",
                side_effect=[TimeoutError(), bytearray([0x0])],
            ),
            patch.object(self.device, "build_send", return_value=None),
            patch.object(
                self.device,
                "parse_message",
                side_effect=[MessageResult.SUCCESS],
            ),
        ):
            self.device._socket = socket_mock
            assert self.device._appliance_query is True
            self.device.refresh_status(True)  # must not raise
            # The timed-out appliance query must still be blacklisted, which is what
            # stops it being re-sent on the next refresh. close_socket() re-arms
            # _appliance_query, so this list is the only thing holding it back on a
            # device that never answers it.
            assert "MessageQueryAppliance" in self.device._unsupported_protocol

    def test_garbled_appliance_reply_does_not_fail_the_device(self) -> None:
        """Third path into the same trap: a ResponseException on the appliance query.

        A V3 decode returning an error for the appliance reply raises
        ResponseException. Ungated that increments too, so with one real command the
        per-iteration check raises on the appliance iteration -- before the real query
        has even been sent -- tearing down a device whose status queries are fine.
        """
        socket_mock = MagicMock()
        real_cmd = MagicMock()
        with (
            patch.object(self.device, "build_query", return_value=[real_cmd]),
            patch.object(
                socket_mock,
                "recv",
                side_effect=[bytearray([0x0]), bytearray([0x0])],
            ),
            patch.object(self.device, "build_send", return_value=None),
            patch.object(
                self.device,
                "parse_message",
                # appliance reply is garbled, the real query answers cleanly
                side_effect=[MessageResult.ERROR, MessageResult.SUCCESS],
            ),
        ):
            self.device._socket = socket_mock
            self.device.refresh_status(True)  # must not raise

    def test_skipped_appliance_query_does_not_fail_the_device(self) -> None:
        """Same, via the "already unsupported, SKIP" branch.

        Once the appliance query is blacklisted it takes the SKIP path, which also
        increments error_count. Ungated that alone reaches len(real_cmds) and fails a
        healthy device.
        """
        socket_mock = MagicMock()
        real_cmd = MagicMock()
        self.device._unsupported_protocol = ["MessageQueryAppliance"]
        with (
            patch.object(self.device, "build_query", return_value=[real_cmd]),
            patch.object(socket_mock, "recv", side_effect=[bytearray([0x0])]),
            patch.object(self.device, "build_send", return_value=None),
            patch.object(
                self.device,
                "parse_message",
                side_effect=[MessageResult.SUCCESS],
            ),
        ):
            self.device._socket = socket_mock
            self.device.refresh_status(True)  # must not raise

    def test_empty_build_query_does_not_raise(self) -> None:
        """A device with no status queries must not report every query as failed.

        With build_query() empty, error_count and len(real_cmds) are both 0. Without
        the `real_cmds and` guard that compares equal and raises, failing a connect
        whose only command -- the appliance query -- had succeeded.
        """
        socket_mock = MagicMock()
        with (
            patch.object(self.device, "build_query", return_value=[]),
            patch.object(socket_mock, "recv", side_effect=[bytearray([0x0])]),
            patch.object(self.device, "build_send", return_value=None),
            patch.object(
                self.device,
                "parse_message",
                side_effect=[MessageResult.SUCCESS],
            ),
        ):
            self.device._socket = socket_mock
            self.device.refresh_status(True)

    def test_build_init_query_prepended_before_status_queries(self) -> None:
        """Init queries run after the appliance query and before status queries.

        build_init_query() (e.g. AC's one-shot B5 capability probes) must be
        prepended ahead of build_query() so their replies are processed before
        the recurring status queries, but still after the appliance query.
        """
        socket_mock = MagicMock()
        init_cmd = MagicMock(name="init_cmd")
        real_cmd = MagicMock(name="real_cmd")
        init_cmd.__class__.__name__ = "InitQuery"
        real_cmd.__class__.__name__ = "StatusQuery"
        sent: list[object] = []

        def parse(_msg: bytes) -> MessageResult:
            # The appliance reply is what clears _appliance_query in production
            # (via pre_process_message); model that so the init stage is armed.
            if sent and sent[-1].__class__.__name__ == "MessageQueryAppliance":
                self.device._appliance_query = False
            return MessageResult.SUCCESS

        with (
            patch.object(self.device, "build_query", return_value=[real_cmd]),
            patch.object(self.device, "build_init_query", return_value=[init_cmd]),
            patch.object(socket_mock, "recv", side_effect=[bytearray([0x0])] * 3),
            patch.object(
                self.device,
                "build_send",
                side_effect=lambda cmd, query=False: sent.append(cmd),  # noqa: ARG005
            ),
            patch.object(self.device, "parse_message", side_effect=parse),
        ):
            self.device._socket = socket_mock
            assert self.device._appliance_query is True
            self.device.refresh_status(True)

        # appliance query first, then the init query, then the status query.
        assert sent[0].__class__.__name__ == "MessageQueryAppliance"
        assert sent[1] is init_cmd
        assert sent[2] is real_cmd

    def test_appliance_query_timeout_still_runs_init_probes(self) -> None:
        """A failed appliance query must not block init/capability probes.

        Some devices do not answer MessageQueryAppliance, but still answer B5
        capability probes and status queries with the default protocol version
        0. Once the appliance query timeout is recorded as unsupported, the
        checked pass must continue to init probes before recurring status.
        """
        socket_mock = MagicMock()
        init_cmd = MagicMock(name="init_cmd")
        real_cmd = MagicMock(name="real_cmd")
        init_cmd.__class__.__name__ = "InitQuery"
        real_cmd.__class__.__name__ = "StatusQuery"
        sent: list[object] = []

        # Appliance query times out (no reply clears _appliance_query), then the
        # init probe and status query answer.
        with (
            patch.object(self.device, "build_query", return_value=[real_cmd]),
            patch.object(self.device, "build_init_query", return_value=[init_cmd]),
            patch.object(
                socket_mock,
                "recv",
                side_effect=[TimeoutError(), bytearray([0x0]), bytearray([0x0])],
            ),
            patch.object(
                self.device,
                "build_send",
                side_effect=lambda cmd, query=False: sent.append(cmd),  # noqa: ARG005
            ),
            patch.object(
                self.device,
                "parse_message",
                side_effect=[MessageResult.SUCCESS, MessageResult.SUCCESS],
            ),
        ):
            self.device._socket = socket_mock
            assert self.device._appliance_query is True
            self.device.refresh_status(True)

        # appliance query first, then the init probe, then the status query.
        assert sent[0].__class__.__name__ == "MessageQueryAppliance"
        assert sent[1] is init_cmd
        assert sent[2] is real_cmd
        assert "MessageQueryAppliance" in self.device._unsupported_protocol
        assert self.device._appliance_query is True

    def test_skipped_appliance_query_still_runs_init_probes(self) -> None:
        """A blacklisted appliance query must still advance to init probes."""
        socket_mock = MagicMock()
        init_cmd = MagicMock(name="init_cmd")
        real_cmd = MagicMock(name="real_cmd")
        init_cmd.__class__.__name__ = "InitQuery"
        real_cmd.__class__.__name__ = "StatusQuery"
        sent: list[object] = []
        self.device._unsupported_protocol = ["MessageQueryAppliance"]

        with (
            patch.object(self.device, "build_query", return_value=[real_cmd]),
            patch.object(self.device, "build_init_query", return_value=[init_cmd]),
            patch.object(socket_mock, "recv", side_effect=[bytearray([0x0])] * 2),
            patch.object(
                self.device,
                "build_send",
                side_effect=lambda cmd, query=False: sent.append(cmd),  # noqa: ARG005
            ),
            patch.object(
                self.device,
                "parse_message",
                side_effect=[MessageResult.SUCCESS, MessageResult.SUCCESS],
            ),
        ):
            self.device._socket = socket_mock
            assert self.device._appliance_query is True
            self.device.refresh_status(True)

        assert sent == [init_cmd, real_cmd]
        assert self.device._appliance_query is True

    def test_followup_init_query_spliced_into_checked_pass(self) -> None:
        """A reply that arms a follow-up init query gets it validated in-pass.

        The AC additional-capability probe is armed only after the basic frame's
        reply, i.e. after the command list was built. It must be sent and
        validated inside the same check_protocol pass, not deferred to an
        unchecked refresh where a timeout could never blacklist it.
        """
        socket_mock = MagicMock()
        self.device._appliance_query = False

        class _Basic:
            pass

        class _Additional:
            pass

        basic = _Basic()
        additional = _Additional()
        real_cmd = MagicMock(name="real_cmd")
        real_cmd.__class__.__name__ = "StatusQuery"
        # Arm the follow-up only after the basic probe's reply is processed.
        armed = {"additional": False}
        sent: list[object] = []

        def build_init() -> list[object]:
            return [additional] if armed["additional"] else [basic]

        def parse(_msg: bytes) -> MessageResult:
            if sent and isinstance(sent[-1], _Basic):
                armed["additional"] = True
            return MessageResult.SUCCESS

        with (
            patch.object(self.device, "build_query", return_value=[real_cmd]),
            patch.object(self.device, "build_init_query", side_effect=build_init),
            patch.object(socket_mock, "recv", side_effect=[bytearray([0x0])] * 3),
            patch.object(
                self.device,
                "build_send",
                side_effect=lambda cmd, query=False: sent.append(cmd),  # noqa: ARG005
            ),
            patch.object(self.device, "parse_message", side_effect=parse),
        ):
            self.device._socket = socket_mock
            self.device.refresh_status(True)

        # basic probe, then the spliced additional probe, then the status query.
        assert sent[0] is basic
        assert sent[1] is additional
        assert sent[2] is real_cmd

    def test_followup_init_query_blacklisted_on_timeout(self) -> None:
        """An armed follow-up probe that times out is recorded, not re-sent.

        Once the additional probe is spliced in and times out during the checked
        pass, it lands in _unsupported_protocol, so it is never queued again even
        though build_init_query() keeps reporting it as armed.
        """
        socket_mock = MagicMock()
        self.device._appliance_query = False

        class _Basic:
            pass

        class _Additional:
            pass

        basic = _Basic()
        additional = _Additional()
        real_cmd = MagicMock(name="real_cmd")
        real_cmd.__class__.__name__ = "StatusQuery"
        armed = {"additional": False}
        sent: list[object] = []

        def build_init() -> list[object]:
            return [additional] if armed["additional"] else [basic]

        def parse(_msg: bytes) -> MessageResult:
            if sent and isinstance(sent[-1], _Basic):
                armed["additional"] = True
            return MessageResult.SUCCESS

        # basic reply succeeds, additional probe times out, status query succeeds.
        with (
            patch.object(self.device, "build_query", return_value=[real_cmd]),
            patch.object(self.device, "build_init_query", side_effect=build_init),
            patch.object(
                socket_mock,
                "recv",
                side_effect=[bytearray([0x0]), TimeoutError(), bytearray([0x0])],
            ),
            patch.object(
                self.device,
                "build_send",
                side_effect=lambda cmd, query=False: sent.append(cmd),  # noqa: ARG005
            ),
            patch.object(self.device, "parse_message", side_effect=parse),
        ):
            self.device._socket = socket_mock
            self.device.refresh_status(True)  # must not raise (real query answered)

        assert "_Additional" in self.device._unsupported_protocol
        # Sent exactly once despite still being reported as armed.
        assert sum(isinstance(c, _Additional) for c in sent) == 1

    def test_blacklisted_init_query_still_advances_stage_in_checked_pass(self) -> None:
        """A skipped (already-unsupported) init stage still advances to the next.

        When an init query is already in _unsupported_protocol its send is
        skipped, but its stage is still resolved: the checked pass must build and
        send the next stage (the status queries) rather than stalling on the
        skipped command.
        """
        socket_mock = MagicMock()
        self.device._appliance_query = False

        class _Init:
            pass

        init_cmd = _Init()
        self.device._unsupported_protocol = ["_Init"]
        real_cmd = MagicMock(name="real_cmd")
        real_cmd.__class__.__name__ = "StatusQuery"
        armed = {"init": True}
        sent: list[object] = []

        def build_init() -> list[object]:
            return [init_cmd] if armed["init"] else []

        with (
            patch.object(self.device, "build_query", return_value=[real_cmd]),
            patch.object(self.device, "build_init_query", side_effect=build_init),
            patch.object(socket_mock, "recv", side_effect=[bytearray([0x0])]),
            patch.object(
                self.device,
                "build_send",
                side_effect=lambda cmd, query=False: sent.append(cmd),  # noqa: ARG005
            ),
            patch.object(
                self.device,
                "parse_message",
                side_effect=[MessageResult.SUCCESS],
            ),
        ):
            self.device._socket = socket_mock
            self.device.refresh_status(True)

        # The skipped init query is never sent, but the status stage still runs.
        assert init_cmd not in sent
        assert sent == [real_cmd]

    def test_run_loop_reconnects_when_no_protocol_is_supported(self) -> None:
        """NoSupportedProtocol must drop the socket, like every other error here.

        Continuing on the same socket could never recover: once every command is in
        _unsupported_protocol, refresh_status takes the SKIP branch for all of them
        and performs no socket I/O, so no socket error can ever be raised to break
        the loop. The device stayed stuck until Home Assistant restarted.

        The discriminator is how many times the refresh is attempted: breaking out
        reconnects after one, whereas continuing spins on the same dead socket. A
        socket mock is required -- without one the loop raises SocketException at the
        top and never reaches this handler at all.
        """
        attempts = 0
        connects = 0

        def refresh(_now: float) -> None:
            nonlocal attempts
            attempts += 1
            # Guarantee termination if the break is ever removed. It has to be an
            # exception the loop does NOT handle: the inner `while True` never
            # consults _is_run, so clearing that would spin forever instead of
            # failing.
            if attempts > 3:
                raise SystemExit
            raise NoSupportedProtocol

        def connect_loop() -> None:
            # Let the outer loop run once more so the RECONNECT is observable, then
            # stop the service. Ending it inside close_socket() instead would exit
            # before _connect_loop() could be reached, which is what made the old
            # version of this test prove only that the socket was dropped.
            nonlocal connects
            connects += 1
            if connects == 2:
                self.device._is_run = False

        with (
            patch.object(self.device, "_connect_loop", side_effect=connect_loop),
            # _should_run() is deliberately NOT patched: the outer loop reads
            # _is_run directly, but the early `if not self._should_run(): break`
            # right after _connect_loop() is what lets connect_loop() stop the
            # service. Patching it to True would defer the stop by one refresh
            # cycle (the outer `while` still exits), failing `attempts == 1`.
            patch.object(self.device, "_check_refresh", side_effect=refresh),
            patch.object(self.device, "close_socket") as close_mock,
        ):
            self.device._socket = MagicMock()
            self.device._is_run = True
            with contextlib.suppress(SystemExit):
                self.device.run()

        assert attempts == 1
        # The point of the fix: the socket is dropped AND the loop dials again.
        # Asserting only the first would pass even if recovery never happened.
        assert connects == 2
        close_mock.assert_called_once()

    def test_one_failing_query_among_several_does_not_fail_the_device(self) -> None:
        """Only ALL the status queries failing may raise.

        Every other test here uses a single status query, which cannot tell
        accumulation apart from assignment: with `error_count = 1` instead of `+= 1`
        the check still passes for one command but can never be reached for a real
        device -- an AC builds eleven -- so the whole guard would be inert. And with
        the count over-incremented, "all failed" silently becomes "any failed", so one
        timed-out group query during the initial probe fails connect() and a working
        device never comes online.
        """
        socket_mock = MagicMock()
        # Distinct classes on purpose: _unsupported_protocol keys off
        # cmd.__class__.__name__, so two MagicMocks would share a name and the second
        # would take the "already unsupported, SKIP" path instead of the one under
        # test.
        cmd_ok = type("QueryOk", (), {})()
        cmd_bad = type("QueryBad", (), {})()
        with (
            patch.object(
                self.device,
                "build_query",
                return_value=[cmd_ok, cmd_bad],
            ),
            patch.object(
                socket_mock,
                "recv",
                # appliance ok, first real ok, second real times out
                side_effect=[bytearray([0x0]), bytearray([0x0]), TimeoutError()],
            ),
            patch.object(self.device, "build_send", return_value=None),
            patch.object(
                self.device,
                "parse_message",
                side_effect=[MessageResult.SUCCESS, MessageResult.SUCCESS],
            ),
        ):
            self.device._socket = socket_mock
            self.device.refresh_status(True)  # must not raise

    def test_all_queries_failing_among_several_raises(self) -> None:
        """The sibling of the above: every real query failing must still raise."""
        socket_mock = MagicMock()
        cmd_a = type("QueryA", (), {})()
        cmd_b = type("QueryB", (), {})()
        with (
            patch.object(self.device, "build_query", return_value=[cmd_a, cmd_b]),
            patch.object(
                socket_mock,
                "recv",
                side_effect=[bytearray([0x0]), TimeoutError(), TimeoutError()],
            ),
            patch.object(self.device, "build_send", return_value=None),
            patch.object(
                self.device,
                "parse_message",
                side_effect=[MessageResult.SUCCESS],
            ),
        ):
            self.device._socket = socket_mock
            with pytest.raises(NoSupportedProtocol):
                self.device.refresh_status(True)
            # Both must have failed on their own timeout. If they shared a class name
            # the second would take the SKIP path, consuming only two of the three
            # recv side effects and testing a different branch than this one claims.
            assert self.device._unsupported_protocol == ["QueryA", "QueryB"]
            assert socket_mock.recv.call_count == 3

    def test_close_socket_rearms_appliance_query(self) -> None:
        """close_socket must re-arm the appliance query for the next connection.

        _appliance_query is cleared in pre_process_message and was never set back, so
        a reconnected device skipped protocol detection entirely.
        """
        self.device._socket = None
        self.device._appliance_query = False
        self.device.close_socket()
        assert self.device._appliance_query is True

    def test_refresh_status_without_appliance_or_protocol_check(self) -> None:
        """Test refresh_status can send queries without response validation."""
        cmd = MagicMock()
        self.device._appliance_query = False
        with (
            patch.object(self.device, "build_query", return_value=[cmd]),
            patch.object(self.device, "build_send") as build_send_mock,
        ):
            self.device.refresh_status()

        build_send_mock.assert_called_once_with(cmd, query=True)

    def test_unchecked_refresh_skips_unsupported_query_without_advancing(self) -> None:
        """An unchecked refresh skips an unsupported query and sends the rest.

        With check_protocol=False no reply is awaited inline, so a command in
        _unsupported_protocol takes the SKIP branch and does not trigger a stage
        advance -- the periodic refresh must simply pass over it and still send
        the remaining, supported query.
        """
        supported = type("Supported", (), {})()
        unsupported = type("Unsupported", (), {})()
        self.device._appliance_query = False
        self.device._unsupported_protocol = ["Unsupported"]
        with (
            patch.object(
                self.device,
                "build_query",
                return_value=[unsupported, supported],
            ),
            patch.object(self.device, "build_send") as build_send_mock,
        ):
            self.device.refresh_status()

        # Only the supported query is sent; the unsupported one is skipped.
        build_send_mock.assert_called_once_with(supported, query=True)

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

    def test_parse_message_without_appliance_preprocess(self) -> None:
        """Test parse_message processes payload when appliance query is disabled."""
        message = bytearray([0x0] * 72)
        message[4] = 72
        self.device._appliance_query = False
        with (
            patch.object(
                self.device,
                "fetch_v2_message",
                return_value=([message], b""),
            ),
            patch.object(
                self.device._security,
                "aes_decrypt",
                return_value=bytearray([0x1] * 16),
            ),
            patch.object(
                self.device,
                "process_message",
                return_value={"power": True},
            ) as process_message_mock,
        ):
            self.device._device_protocol_version = ProtocolVersion.V2
            assert self.device.parse_message(bytes([])) == MessageResult.SUCCESS

        process_message_mock.assert_called_once()

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

    def test_open(self) -> None:
        """Test open."""
        with (
            patch.object(self.device, "connect", return_value=False),
            patch.object(self.device, "run"),
        ):
            self.device.open()
            assert self.device._is_run is True

    def test_open_noop_when_already_running(self) -> None:
        """Test open does nothing when the thread is already marked running."""
        self.device._is_run = True
        with patch("threading.Thread.start") as start_mock:
            self.device.open()
        start_mock.assert_not_called()

    def test_close(self) -> None:
        """Test close."""
        with patch.object(self.device, "_socket") as socket_mock:
            self.device._is_run = True
            self.device.close()
            assert self.device._is_run is False
            socket_mock.close.assert_called()

    def test_close_noop_when_not_running(self) -> None:
        """Test close does nothing when the thread is already stopped."""
        self.device._is_run = False
        with patch.object(self.device, "close_socket") as close_socket_mock:
            self.device.close()
        close_socket_mock.assert_not_called()

    def test_close_socket_close_oserror(self) -> None:
        """Test close_socket swallows OSError raised by socket.close()."""
        socket_mock = MagicMock()
        socket_mock.close.side_effect = OSError("already closed")
        self.device._socket = socket_mock
        self.device.close_socket()
        socket_mock.close.assert_called_once()
        assert self.device._socket is None

    def test_close_socket_without_socket_clears_connection_state(self) -> None:
        """Test close_socket clears connection state when no socket exists."""
        self.device._socket = None
        self.device._buffer = b"stale"
        self.device._unsupported_protocol = ["old"]
        self.device.close_socket()
        assert self.device._buffer == b""
        assert self.device._unsupported_protocol == []

    def test_close_socket_close_value_error(self) -> None:
        """Test close_socket swallows ValueError raised by socket.close()."""
        socket_mock = MagicMock()
        socket_mock.close.side_effect = ValueError("invalid file descriptor")
        self.device._socket = socket_mock
        self.device.close_socket()
        socket_mock.close.assert_called_once()
        assert self.device._socket is None

    def test_close_socket_does_not_clear_replaced_socket(self) -> None:
        """Test close_socket only clears the same socket it captured."""
        old_socket = MagicMock()
        new_socket: Any = MagicMock()

        def replace_socket() -> None:
            self.device._socket = new_socket

        old_socket.close.side_effect = replace_socket
        self.device._socket = old_socket
        self.device.close_socket()

        old_socket.close.assert_called_once()
        assert self.device._socket is new_socket

    def test_set_ip(self) -> None:
        """Test set ip."""
        with patch.object(self.device, "_socket") as socket_mock:
            assert self.device._ip_address == "192.168.1.100"
            self.device.set_ip_address("10.0.0.1")
            socket_mock.close.assert_called()
            assert self.device._ip_address == "10.0.0.1"

    def test_set_ip_noop_when_unchanged(self) -> None:
        """Test set_ip_address does not close the socket when IP is unchanged."""
        with patch.object(self.device, "close_socket") as close_socket_mock:
            self.device.set_ip_address("192.168.1.100")
        close_socket_mock.assert_not_called()

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

    def test_connect_loop_does_not_close_socket_replaced_during_failed_connect(
        self,
    ) -> None:
        """Test _connect_loop failure handling keeps a concurrently replaced socket."""
        new_socket: Any = MagicMock()
        self.device._is_run = True
        self.device._socket = None
        self.device._buffer = b"active"
        self.device._unsupported_protocol = ["new"]

        def failed_connect(**_kwargs: object) -> bool:
            self.device._socket = new_socket
            return False

        with (
            patch.object(self.device, "connect", side_effect=failed_connect),
            patch("time.sleep"),
        ):
            self.device._connect_loop()

        new_socket.close.assert_not_called()
        assert self.device._socket is new_socket
        assert self.device._buffer == b"active"
        assert self.device._unsupported_protocol == ["new"]

    def test_connect_loop_skips_connect_after_stop_request(self) -> None:
        """Test _connect_loop skips connect if _should_run turns false."""
        self.device._is_run = True
        self.device._socket = None

        def stop_before_connect() -> bool:
            self.device._is_run = False
            return False

        with (
            patch.object(self.device, "_should_run", side_effect=stop_before_connect),
            patch.object(self.device, "connect") as connect_mock,
        ):
            self.device._connect_loop()

        connect_mock.assert_not_called()

    def test_connect_loop_sleep_backoff_can_finish_without_stop(self) -> None:
        """Test _connect_loop can finish the retry sleep without early stop."""
        self.device._is_run = True
        self.device._socket = None
        sleep_calls: list[float] = []

        def finish_sleep(seconds: float) -> None:
            sleep_calls.append(seconds)
            if len(sleep_calls) == 5:
                self.device._socket = MagicMock()

        with (
            patch.object(self.device, "connect", return_value=False),
            patch("time.sleep", side_effect=finish_sleep),
        ):
            self.device._connect_loop()

        assert sleep_calls == [1, 1, 1, 1, 1]

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
            if connect_loop_calls["n"] > 6:
                self.device._is_run = False

        # NoSupportedProtocol now closes the socket and breaks rather than continuing
        # on the same one, so it gets its own pass at the end -- if it stayed mid-pass
        # it would end that pass early and the SUCCESS/heartbeat-timeout script below
        # would never run.
        check_refresh_side_effect = (
            [None, None, None, None]  # passes 1-4: no refresh due
            + [None]  # pass 5, iter a: refresh ok, then SUCCESS recv
            + [None] * RESPONSE_TIMEOUT  # pass 5, iters b..: timeouts
            + [NoSupportedProtocol()]  # pass 6: close_socket + break
        )
        recv_side_effect = [
            b"",  # pass 1: empty -> ConnectionResetError
            b"\x01",  # pass 2: parsed as ERROR
            OSError("boom"),  # pass 3
            ValueError("boom"),  # pass 4
            b"\x01",  # pass 5, iter a: parsed as SUCCESS
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

        assert connect_loop_calls["n"] == 7
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
