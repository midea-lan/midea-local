"""Midea Local device test."""

import asyncio
import contextlib
from collections.abc import Callable
from types import SimpleNamespace
from typing import Any, ClassVar
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from midealocal.cloud import DEFAULT_KEYS
from midealocal.const import DeviceType, ProtocolVersion
from midealocal.device import (
    MESSAGE_TYPE_INDEX,
    RESPONSE_TIMEOUT,
    SKIP_ATTRIBUTE,
    AuthException,
    MessageResult,
    MideaDevice,
    NoSupportedProtocol,
    ResponseException,
    dict_translator,
    list_translator,
    multiplier_translator,
    precision_halves_translator,
    sentinel_translator,
)
from midealocal.exceptions import SocketException
from midealocal.message import MessageType
from tests.conftest import make_stream_pair, running_reader_loop


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


# A valid V3 handshake response: header + 32 zero bytes + a 32-byte payload
# whose exact content is irrelevant to authenticate() beyond its length.
_AUTH_HANDSHAKE_RESPONSE = bytearray(
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
)


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
        ("exc", "result"),
        [
            (TimeoutError, False),
            (OSError, False),
            (AuthException, False),
            (NoSupportedProtocol, False),
            (SocketException, False),
            (None, True),
        ],
    )
    @pytest.mark.asyncio
    async def test_connect(
        self,
        exc: type[Exception] | None,
        result: bool,
    ) -> None:
        """Test connect."""
        # Pre-populate buffer to confirm the failure path runs close_socket(),
        # which clears it.
        self.device._buffer = b"stale"
        reader, writer = make_stream_pair([b""])
        open_connection_mock = AsyncMock(side_effect=exc, return_value=(reader, writer))
        with (
            patch("midealocal.device.asyncio.open_connection", open_connection_mock),
            patch.object(self.device, "authenticate", new=AsyncMock()),
            patch.object(self.device, "refresh_status", new=AsyncMock()),
        ):
            assert await self.device.connect(check_protocol=True) is result
            assert self.device.available is result
            assert (self.device._writer is None) is (not result)
            if not result:
                # close_socket() was invoked: it also resets the buffer.
                assert self.device._buffer == b""
        # connect() starts a reader task on the successful path; stop it.
        task, self.device._reader_task = self.device._reader_task, None
        if task is not None:
            task.cancel()
            with contextlib.suppress(BaseException):
                await task

    @pytest.mark.asyncio
    async def test_connect_v3_does_not_race_authenticate_against_read_loop(
        self,
    ) -> None:
        """Regression test: the reader task must not start until after the V3 handshake.

        asyncio.StreamReader raises RuntimeError if two coroutines await
        read() on it concurrently. authenticate() does its own raw read()
        for the handshake response, so _read_loop() (the sole reader once
        the connection is up) must not start until that read is done --
        this uses a real StreamReader, since mocks don't reproduce that
        guard.
        """
        reader = asyncio.StreamReader()
        writer = MagicMock(spec=asyncio.StreamWriter)
        writer.wait_closed = AsyncMock()

        async def _feed_handshake_response() -> None:
            # Give the event loop a beat before the response "arrives", so
            # a reader task started too early has every chance to race
            # authenticate()'s own pending read() on self._reader.
            await asyncio.sleep(0)
            reader.feed_data(bytes(_AUTH_HANDSHAKE_RESPONSE))

        feeder = asyncio.create_task(_feed_handshake_response())
        with patch(
            "midealocal.device.asyncio.open_connection",
            new=AsyncMock(return_value=(reader, writer)),
        ):
            assert await self.device.connect() is True
        await feeder

        task, self.device._reader_task = self.device._reader_task, None
        assert task is not None
        # A task that already crashed (e.g. RuntimeError from a concurrent
        # read()) finished before cancel() below has any effect on it, so
        # it comes back non-cancelled -- that's the failure this catches.
        task.cancel()
        with contextlib.suppress(asyncio.CancelledError):
            await task
        assert task.cancelled()

    @pytest.mark.asyncio
    async def test_connect_generic_exception(self) -> None:
        """Test connect with generic exception."""
        self.device._buffer = b"stale"
        with patch(
            "midealocal.device.asyncio.open_connection",
            new=AsyncMock(side_effect=Exception()),
        ):
            assert await self.device.connect() is False
            assert self.device.available is False
            assert self.device._writer is None
            assert self.device._buffer == b""

    @pytest.mark.asyncio
    async def test_authenticate(self) -> None:
        """Test authenticate."""
        reader, writer = make_stream_pair([bytearray(), _AUTH_HANDSHAKE_RESPONSE])

        with pytest.raises(SocketException):
            await self.device.authenticate()

        self.device._reader, self.device._writer = reader, writer
        with pytest.raises(AuthException):
            await self.device.authenticate()

        await self.device.authenticate()

    @pytest.mark.asyncio
    async def test_send_message(self) -> None:
        """Test send message."""
        reader, writer = make_stream_pair([_AUTH_HANDSHAKE_RESPONSE])
        self.device._reader, self.device._writer = reader, writer
        await self.device.authenticate()
        self.device.send_message(bytes([0x0] * 20))
        self.device._device_protocol_version = ProtocolVersion.V2
        self.device.send_message(bytes([0x0] * 20))

    def test_send_message_v2_socket_none(self) -> None:
        """Test send_message_v2 raises SocketException when writer is None."""
        self.device._writer = None
        with pytest.raises(SocketException):
            self.device.send_message_v2(bytes([0x0] * 20))

    @pytest.mark.parametrize(
        "exc",
        [TimeoutError, ConnectionResetError, OSError, ValueError],
    )
    def test_send_message_v2_send_errors_reraised(self, exc: type[Exception]) -> None:
        """Test send_message_v2 logs and re-raises every writer.write failure."""
        _reader, writer = make_stream_pair()
        writer.write.side_effect = exc("boom")
        self.device._writer = writer
        with pytest.raises(exc):
            self.device.send_message_v2(bytes([0x0] * 20))

    def test_build_send(self) -> None:
        """Test build_send serializes, packages and sends the command."""
        cmd = MagicMock()
        cmd.serialize.return_value = bytes([0x01, 0x02])
        with patch.object(self.device, "send_message") as send_mock:
            self.device.build_send(cmd)
        cmd.serialize.assert_called_once()
        send_mock.assert_called_once()

    @pytest.mark.asyncio
    async def test_wait_for_query_response_no_reader_task_raises_socket_exception(
        self,
    ) -> None:
        """Test _wait_for_query_response with no reader task running."""
        self.device._reader_task = None
        with pytest.raises(SocketException):
            await self.device._wait_for_query_response()

    @pytest.mark.asyncio
    async def test_wait_for_query_response_done_reader_task_raises_socket_exception(
        self,
    ) -> None:
        """Test _wait_for_query_response once the reader task has already exited."""
        task = asyncio.create_task(asyncio.sleep(0))
        await task
        self.device._reader_task = task
        with pytest.raises(SocketException):
            await self.device._wait_for_query_response()

    @pytest.mark.asyncio
    async def test_wait_for_query_response_times_out(self) -> None:
        """Test _wait_for_query_response raises TimeoutError and clears the waiter."""
        idle_task = asyncio.create_task(asyncio.sleep(100))
        self.device._reader_task = idle_task
        with (
            patch("midealocal.device.QUERY_TIMEOUT", 0.01),
            pytest.raises(TimeoutError),
        ):
            await self.device._wait_for_query_response()
        assert self.device._response_waiter is None
        idle_task.cancel()
        with contextlib.suppress(BaseException):
            await idle_task

    @pytest.mark.asyncio
    async def test_wait_for_query_response_resolves_when_waiter_is_set(self) -> None:
        """Test _wait_for_query_response returns once the waiter is resolved."""
        idle_task = asyncio.create_task(asyncio.sleep(100))
        self.device._reader_task = idle_task

        async def _resolve_soon() -> None:
            await asyncio.sleep(0)
            assert self.device._response_waiter is not None
            self.device._response_waiter.set_result(MessageResult.SUCCESS)

        resolver = asyncio.create_task(_resolve_soon())
        await self.device._wait_for_query_response()
        await resolver
        idle_task.cancel()
        with contextlib.suppress(BaseException):
            await idle_task

    @pytest.mark.asyncio
    async def test_resolve_waiter_or_raise_success_sets_result(self) -> None:
        """Test _resolve_waiter_or_raise resolves a pending waiter on SUCCESS."""
        waiter = asyncio.get_running_loop().create_future()
        self.device._response_waiter = waiter
        self.device._resolve_waiter_or_raise(MessageResult.SUCCESS)
        assert waiter.result() == MessageResult.SUCCESS

    @pytest.mark.asyncio
    async def test_resolve_waiter_or_raise_non_success_rejects_waiter(self) -> None:
        """Test _resolve_waiter_or_raise rejects a pending waiter on a bad result."""
        waiter = asyncio.get_running_loop().create_future()
        self.device._response_waiter = waiter
        self.device._resolve_waiter_or_raise(MessageResult.ERROR)
        with pytest.raises(ResponseException):
            waiter.result()

    @pytest.mark.asyncio
    async def test_resolve_waiter_or_raise_unsolicited_error_raises(self) -> None:
        """Test _resolve_waiter_or_raise raises when nobody is waiting."""
        self.device._response_waiter = None
        with pytest.raises(ResponseException):
            self.device._resolve_waiter_or_raise(MessageResult.ERROR)

    @pytest.mark.asyncio
    async def test_resolve_waiter_or_raise_ignores_already_done_waiter(self) -> None:
        """An already-resolved waiter must not swallow a later unsolicited error."""
        waiter = asyncio.get_running_loop().create_future()
        waiter.set_result(MessageResult.SUCCESS)
        self.device._response_waiter = waiter
        with pytest.raises(ResponseException):
            self.device._resolve_waiter_or_raise(MessageResult.ERROR)

    @pytest.mark.asyncio
    async def test_fail_waiter_sets_exception_on_pending_waiter(self) -> None:
        """Test _fail_waiter rejects a pending waiter with the given exception."""
        waiter = asyncio.get_running_loop().create_future()
        self.device._response_waiter = waiter
        exc = SocketException()
        self.device._fail_waiter(exc)
        assert waiter.exception() is exc

    def test_fail_waiter_noop_when_no_waiter(self) -> None:
        """Test _fail_waiter is a no-op when nothing is waiting."""
        self.device._response_waiter = None
        self.device._fail_waiter(SocketException())

    @pytest.mark.asyncio
    async def test_read_loop_requires_reader(self) -> None:
        """Test _read_loop raises SocketException when self._reader is None."""
        self.device._reader = None
        with pytest.raises(SocketException):
            await self.device._read_loop()

    @pytest.mark.asyncio
    async def test_read_loop_empty_data_raises_connection_reset(self) -> None:
        """Test _read_loop treats an empty read as the peer closing the connection."""
        reader, _writer = make_stream_pair([b""])
        self.device._reader = reader
        waiter = asyncio.get_running_loop().create_future()
        self.device._response_waiter = waiter
        with pytest.raises(ConnectionResetError, match=r"Connection closed by peer\."):
            await self.device._read_loop()
        with pytest.raises(ConnectionResetError):
            waiter.result()

    @pytest.mark.asyncio
    async def test_read_loop_read_error_propagates_and_fails_waiter(self) -> None:
        """Test _read_loop re-raises and fails the waiter on a read-level error."""
        reader, _writer = make_stream_pair([OSError("boom")])
        self.device._reader = reader
        waiter = asyncio.get_running_loop().create_future()
        self.device._response_waiter = waiter
        with pytest.raises(OSError, match="boom"):
            await self.device._read_loop()
        with pytest.raises(OSError, match="boom"):
            waiter.result()

    @pytest.mark.asyncio
    async def test_read_loop_parse_error_fails_waiter_and_propagates(self) -> None:
        """Test _read_loop re-raises and fails the waiter on a parse_message error."""
        reader, _writer = make_stream_pair([b"\x00"])
        self.device._reader = reader
        waiter = asyncio.get_running_loop().create_future()
        self.device._response_waiter = waiter
        with (
            patch.object(
                self.device,
                "parse_message",
                side_effect=ValueError("bad frame"),
            ),
            pytest.raises(ValueError, match="bad frame"),
        ):
            await self.device._read_loop()
        with pytest.raises(ValueError, match="bad frame"):
            waiter.result()

    @pytest.mark.asyncio
    async def test_read_loop_consecutive_timeouts_raise_socket_exception(self) -> None:
        """Test RESPONSE_TIMEOUT consecutive read timeouts tear down the connection."""
        reader, _writer = make_stream_pair([TimeoutError()] * RESPONSE_TIMEOUT)
        self.device._reader = reader
        waiter = asyncio.get_running_loop().create_future()
        self.device._response_waiter = waiter
        with pytest.raises(SocketException):
            await self.device._read_loop()
        with pytest.raises(SocketException):
            waiter.result()

    @pytest.mark.asyncio
    async def test_read_loop_padding_then_success_resolves_waiter(self) -> None:
        """Test _read_loop loops past PADDING results without touching the waiter."""
        reader, _writer = make_stream_pair([b"\x00", b"\x00"])
        self.device._reader = reader
        waiter = asyncio.get_running_loop().create_future()
        self.device._response_waiter = waiter
        with patch.object(
            self.device,
            "parse_message",
            side_effect=[MessageResult.PADDING, MessageResult.SUCCESS],
        ):
            task = asyncio.create_task(self.device._read_loop())
            try:
                result = await asyncio.wait_for(waiter, timeout=1)
            finally:
                task.cancel()
                with contextlib.suppress(BaseException):
                    await task
        assert result == MessageResult.SUCCESS

    def test_request_refresh_sets_flag(self) -> None:
        """Test request_refresh sets the pending-refresh flag."""
        assert self.device._refresh_requested is False
        self.device.request_refresh()
        assert self.device._refresh_requested is True

    @pytest.mark.asyncio
    async def test_read_loop_services_pending_refresh_request(self) -> None:
        """Test _read_loop schedules refresh_status() when a refresh was requested."""
        reader, _writer = make_stream_pair([b"\x00", b""])
        self.device._reader = reader

        def _fake_parse(_data: bytes) -> MessageResult:
            self.device.request_refresh()
            return MessageResult.SUCCESS

        with (
            patch.object(self.device, "parse_message", side_effect=_fake_parse),
            patch.object(
                self.device,
                "refresh_status",
                new=AsyncMock(),
            ) as refresh_mock,
        ):
            with pytest.raises(ConnectionResetError):
                await asyncio.wait_for(self.device._read_loop(), timeout=1)
            await asyncio.sleep(0)  # let the detached refresh task run
            refresh_mock.assert_called_once()
        assert self.device._refresh_requested is False

    @pytest.mark.asyncio
    async def test_read_loop_does_not_block_on_requested_refresh(self) -> None:
        """A pending refresh must be scheduled, not awaited, by the read loop.

        Regression test: refresh_status() takes self._query_lock, which
        another coroutine can be holding while it awaits a response that
        only this same read loop, continuing on to its next read, can ever
        deliver. Awaiting the requested refresh inline here would deadlock
        that caller; the read loop must reach its next message regardless of
        how long the refresh takes.
        """
        reader, _writer = make_stream_pair([b"\x00", b""])
        self.device._reader = reader
        refresh_started = asyncio.Event()
        refresh_may_finish = asyncio.Event()

        def _fake_parse(_data: bytes) -> MessageResult:
            self.device.request_refresh()
            return MessageResult.SUCCESS

        async def _blocked_refresh() -> None:
            refresh_started.set()
            await refresh_may_finish.wait()

        with (
            patch.object(self.device, "parse_message", side_effect=_fake_parse),
            patch.object(
                self.device,
                "refresh_status",
                new=AsyncMock(side_effect=_blocked_refresh),
            ),
        ):
            read_loop_task = asyncio.create_task(self.device._read_loop())
            # If the refresh were awaited inline instead of scheduled as its
            # own task, the read loop could never reach EOF while it's
            # blocked awaiting refresh_may_finish below.
            with pytest.raises(ConnectionResetError):
                await asyncio.wait_for(read_loop_task, timeout=1)
            await asyncio.wait_for(refresh_started.wait(), timeout=1)
            refresh_may_finish.set()
            await asyncio.sleep(0)  # let the detached task finish cleanly

    @pytest.mark.asyncio
    async def test_run_requested_refresh_logs_failure(self) -> None:
        """Test _run_requested_refresh logs, rather than raises, on failure."""
        with patch.object(
            self.device,
            "refresh_status",
            new=AsyncMock(side_effect=NoSupportedProtocol),
        ):
            await self.device._run_requested_refresh()  # must not raise

    @pytest.mark.asyncio
    async def test_refresh_status_build_query_not_implemented(self) -> None:
        """Test refresh_status propagates build_query()'s NotImplementedError."""
        self.device._appliance_query = False
        with pytest.raises(NotImplementedError):
            await self.device.refresh_status()

    @pytest.mark.asyncio
    async def test_refresh_status_no_reader_task_raises_socket_exception(self) -> None:
        """Test refresh_status with no reader task running."""
        self.device._appliance_query = False
        with (
            patch.object(self.device, "build_query", return_value=[MagicMock()]),
            patch.object(self.device, "build_send", return_value=None),
            pytest.raises(SocketException),
        ):
            await self.device.refresh_status(True)

    @pytest.mark.asyncio
    async def test_refresh_status_connection_closed_by_peer(self) -> None:
        """Test refresh_status surfaces the read loop's connection-closed error."""
        self.device._appliance_query = False
        real_cmd = MagicMock()
        reader, writer = make_stream_pair([b""])
        self.device._reader, self.device._writer = reader, writer
        with (
            patch.object(self.device, "build_query", return_value=[real_cmd]),
            patch.object(self.device, "build_send", return_value=None),
        ):
            async with running_reader_loop(self.device):
                with pytest.raises(OSError, match=r"Connection closed by peer\."):
                    await self.device.refresh_status(True)

    @pytest.mark.asyncio
    async def test_refresh_status_success(self) -> None:
        """Test refresh_status succeeds when the read loop reports SUCCESS."""
        self.device._appliance_query = False
        real_cmd = MagicMock()
        reader, writer = make_stream_pair([b"\x00"])
        self.device._reader, self.device._writer = reader, writer
        with (
            patch.object(self.device, "build_query", return_value=[real_cmd]),
            patch.object(self.device, "build_send", return_value=None),
            patch.object(
                self.device,
                "parse_message",
                return_value=MessageResult.SUCCESS,
            ),
        ):
            async with running_reader_loop(self.device):
                await self.device.refresh_status(True)

    @pytest.mark.asyncio
    async def test_refresh_status_padding_then_success(self) -> None:
        """Test refresh_status succeeds after the read loop absorbs a PADDING result."""
        self.device._appliance_query = False
        real_cmd = MagicMock()
        reader, writer = make_stream_pair([b"\x00", b"\x00"])
        self.device._reader, self.device._writer = reader, writer
        with (
            patch.object(self.device, "build_query", return_value=[real_cmd]),
            patch.object(self.device, "build_send", return_value=None),
            patch.object(
                self.device,
                "parse_message",
                side_effect=[MessageResult.PADDING, MessageResult.SUCCESS],
            ),
        ):
            async with running_reader_loop(self.device):
                await self.device.refresh_status(True)

    @pytest.mark.asyncio
    async def test_refresh_status_error_response_raises_no_supported_protocol(
        self,
    ) -> None:
        """Test refresh_status raises NoSupportedProtocol on an ERROR result."""
        self.device._appliance_query = False
        real_cmd = MagicMock()
        reader, writer = make_stream_pair([b"\x00"])
        self.device._reader, self.device._writer = reader, writer
        with (
            patch.object(self.device, "build_query", return_value=[real_cmd]),
            patch.object(self.device, "build_send", return_value=None),
            patch.object(
                self.device,
                "parse_message",
                return_value=MessageResult.ERROR,
            ),
        ):
            async with running_reader_loop(self.device):
                with pytest.raises(NoSupportedProtocol):
                    await self.device.refresh_status(True)

    @pytest.mark.asyncio
    async def test_refresh_status_retries_once_before_blacklisting(self) -> None:
        """A single timeout during the probe must not blacklist the protocol."""
        with (
            patch.object(self.device, "build_query", return_value=[]),
            patch.object(self.device, "build_send", return_value=None) as build_send,
            patch.object(
                self.device,
                "_wait_for_query_response",
                new=AsyncMock(side_effect=[TimeoutError(), None]),
            ),
        ):
            await self.device.refresh_status(True)

        assert self.device._unsupported_protocol == []
        assert build_send.call_count == 2

    @pytest.mark.asyncio
    async def test_refresh_status_blacklists_after_retry_exhausted(self) -> None:
        """Both probe retries timing out must blacklist the command."""
        self.device._appliance_query = False
        real_cmd = MagicMock()
        with (
            patch.object(self.device, "build_query", return_value=[real_cmd]),
            patch.object(self.device, "build_send", return_value=None) as build_send,
            patch.object(
                self.device,
                "_wait_for_query_response",
                new=AsyncMock(side_effect=[TimeoutError(), TimeoutError()]),
            ),
            pytest.raises(NoSupportedProtocol),
        ):
            await self.device.refresh_status(True)

        assert len(self.device._unsupported_protocol) == 1
        assert build_send.call_count == 2

    @pytest.mark.asyncio
    async def test_refresh_status_skips_blacklisted_protocol(self) -> None:
        """A blacklisted command must be skipped without any socket I/O."""
        self.device._appliance_query = False
        real_cmd = MagicMock()
        self.device._unsupported_protocol = [real_cmd.__class__.__name__]
        with (
            patch.object(self.device, "build_query", return_value=[real_cmd]),
            patch.object(self.device, "build_send", return_value=None) as build_send,
            pytest.raises(NoSupportedProtocol),
        ):
            await self.device.refresh_status(True)
        build_send.assert_not_called()

    @pytest.mark.asyncio
    async def test_refresh_status_appliance_success_does_not_mask_query_failure(
        self,
    ) -> None:
        """Regression test for #575: appliance success must not mask query timeouts."""
        real_cmd = MagicMock()
        with (
            patch.object(self.device, "build_query", return_value=[real_cmd]),
            patch.object(self.device, "build_send", return_value=None) as build_send,
            patch.object(
                self.device,
                "_wait_for_query_response",
                new=AsyncMock(side_effect=[None, TimeoutError(), TimeoutError()]),
            ),
        ):
            assert self.device._appliance_query is True
            with pytest.raises(NoSupportedProtocol):
                await self.device.refresh_status(True)

        assert build_send.call_count == 3

    @pytest.mark.asyncio
    async def test_refresh_status_appliance_query_failure_is_not_a_real_error(
        self,
    ) -> None:
        """An appliance-query timeout, error, or skip must not count as a real error."""
        real_cmd = MagicMock()
        wait_mock = AsyncMock(
            side_effect=[
                TimeoutError(),  # appliance query: timeout (attempt 1)
                TimeoutError(),  # appliance query: timeout (attempt 2, blacklisted)
                None,  # real_cmd: success
            ],
        )
        with (
            patch.object(self.device, "build_query", return_value=[real_cmd]),
            patch.object(self.device, "build_send", return_value=None),
            patch.object(self.device, "_wait_for_query_response", new=wait_mock),
        ):
            assert self.device._appliance_query is True
            await self.device.refresh_status(True)  # appliance times out, ignored
            assert "MessageQueryAppliance" in self.device._unsupported_protocol

            wait_mock.side_effect = [None]  # appliance SKIPped; real_cmd success
            await self.device.refresh_status(True)

            self.device._unsupported_protocol = []
            wait_mock.side_effect = [ResponseException(), None]
            await self.device.refresh_status(
                True,
            )  # appliance ResponseException, ignored

    @pytest.mark.asyncio
    async def test_refresh_status_builds_real_queries_after_appliance_reply(
        self,
    ) -> None:
        """Regression test: build_query() must see the resolved protocol version.

        A query built before the appliance reply keeps whatever protocol
        version was already known (0 on the very first probe), so a device
        that validates that header field would reject it even though the
        reply, parsed moments later in the same call, did resolve it.
        """
        assert self.device._appliance_query is True
        assert self.device._message_protocol_version == 0
        seen_protocol_version = None

        def _resolve_appliance_reply() -> None:
            # Stands in for parse_message() resolving a successful appliance
            # reply: it resolves the protocol version and disarms the flag.
            self.device._message_protocol_version = 8
            self.device._appliance_query = False

        def _capture_build_query() -> list:
            nonlocal seen_protocol_version
            seen_protocol_version = self.device._message_protocol_version
            return []

        with (
            patch.object(self.device, "build_send", return_value=None),
            patch.object(
                self.device,
                "_wait_for_query_response",
                new=AsyncMock(side_effect=_resolve_appliance_reply),
            ),
            patch.object(self.device, "build_query", side_effect=_capture_build_query),
        ):
            await self.device.refresh_status(True)

        assert seen_protocol_version == 8

    @pytest.mark.asyncio
    async def test_refresh_status_periodic_does_not_wait_for_reply(self) -> None:
        """An unchecked (periodic) refresh sends queries without awaiting a reply."""
        self.device._appliance_query = False
        real_cmd = MagicMock()
        with (
            patch.object(self.device, "build_query", return_value=[real_cmd]),
            patch.object(self.device, "build_send", return_value=None) as build_send,
            patch.object(
                self.device,
                "_wait_for_query_response",
                new=AsyncMock(),
            ) as wait_mock,
        ):
            await self.device.refresh_status()

        build_send.assert_called_once_with(real_cmd)
        wait_mock.assert_not_called()

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
        elsewhere; propagating it further (e.g. into a callback that touches
        an asyncio loop the consumer is tearing down) must be avoided.
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

    @pytest.mark.asyncio
    async def test_open(self) -> None:
        """Test open."""
        with patch.object(self.device, "_run", new=AsyncMock()):
            await self.device.open()
            assert self.device._is_run is True
            assert self.device._task is not None
            await self.device._task

    @pytest.mark.asyncio
    async def test_close(self) -> None:
        """Test close."""
        self.device._is_run = True
        self.device._task = asyncio.create_task(asyncio.sleep(100))
        _reader, writer = make_stream_pair()
        self.device._writer = writer
        await self.device.close()
        assert self.device._is_run is False
        writer.close.assert_called()

    @pytest.mark.asyncio
    async def test_close_without_task_still_closes_socket(self) -> None:
        """Test close() tears down the socket even without a supervisor task."""
        self.device._is_run = True
        self.device._task = None
        _reader, writer = make_stream_pair()
        self.device._writer = writer
        await self.device.close()
        assert self.device._is_run is False
        writer.close.assert_called()

    @pytest.mark.asyncio
    async def test_close_socket_close_oserror(self) -> None:
        """Test close_socket swallows OSError raised by writer.wait_closed()."""
        _reader, writer = make_stream_pair()
        writer.wait_closed = AsyncMock(side_effect=OSError("already closed"))
        self.device._writer = writer
        await self.device.close_socket()
        writer.close.assert_called_once()
        assert self.device._writer is None

    @pytest.mark.asyncio
    async def test_close_socket_rearms_appliance_query(self) -> None:
        """close_socket must re-arm the appliance query for the next connection.

        _appliance_query is cleared in pre_process_message and was never set
        back, so a reconnected device skipped protocol detection entirely.
        """
        self.device._writer = None
        self.device._appliance_query = False
        await self.device.close_socket()
        assert self.device._appliance_query is True

    @pytest.mark.asyncio
    async def test_close_socket_fails_pending_waiter(self) -> None:
        """close_socket must unblock anyone awaiting a response, not let it hang."""
        waiter = asyncio.get_running_loop().create_future()
        self.device._response_waiter = waiter
        await self.device.close_socket()
        assert waiter.done()
        with pytest.raises(SocketException):
            waiter.result()

    @pytest.mark.asyncio
    async def test_close_socket_cancels_reader_task(self) -> None:
        """close_socket must cancel a still-running reader task."""
        task = asyncio.create_task(asyncio.sleep(100))
        self.device._reader_task = task
        await self.device.close_socket()
        with contextlib.suppress(BaseException):
            await task
        assert task.cancelled()

    @pytest.mark.asyncio
    async def test_set_ip(self) -> None:
        """Test set ip."""
        _reader, writer = make_stream_pair()
        self.device._writer = writer
        assert self.device._ip_address == "192.168.1.100"
        await self.device.set_ip_address("10.0.0.1")
        writer.close.assert_called()
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

    @pytest.mark.asyncio
    async def test_check_refresh(self) -> None:
        """Test _check_refresh triggers refresh_status once the interval elapses."""
        self.device._refresh_interval = 30
        self.device._previous_refresh = 0.0
        with patch.object(
            self.device,
            "refresh_status",
            new=AsyncMock(),
        ) as refresh_mock:
            # Not enough time elapsed yet: no refresh.
            await self.device._check_refresh(10.0)
            refresh_mock.assert_not_called()
            assert self.device._previous_refresh == 0.0

            # Interval elapsed: refresh triggered and previous_refresh updated.
            await self.device._check_refresh(30.0)
            refresh_mock.assert_called_once()
            assert self.device._previous_refresh == 30.0

    @pytest.mark.asyncio
    async def test_check_heartbeat(self) -> None:
        """Test _check_heartbeat triggers send_heartbeat once the interval elapses."""
        self.device._heartbeat_interval = 10
        self.device._previous_heartbeat = 0.0
        with patch.object(self.device, "send_heartbeat") as heartbeat_mock:
            await self.device._check_heartbeat(5.0)
            heartbeat_mock.assert_not_called()
            assert self.device._previous_heartbeat == 0.0

            await self.device._check_heartbeat(10.0)
            heartbeat_mock.assert_called_once()
            assert self.device._previous_heartbeat == 10.0

    @pytest.mark.asyncio
    async def test_connect_loop(self) -> None:
        """Test _connect_loop retries with backoff and stops when told to."""
        self.device._is_run = True
        self.device._writer = None
        sleep_calls: list[float] = []

        async def fake_sleep(seconds: float) -> None:
            sleep_calls.append(seconds)
            # Simulate close() happening concurrently during the backoff sleep.
            self.device._is_run = False

        with (
            patch.object(self.device, "connect", new=AsyncMock(return_value=False)),
            patch("midealocal.device.asyncio.sleep", side_effect=fake_sleep),
        ):
            await self.device._connect_loop()

        assert sleep_calls == [5]
        assert self.device._writer is None

    @pytest.mark.asyncio
    async def test_connect_loop_exits_once_connected(self) -> None:
        """Test _connect_loop stops retrying as soon as connect() succeeds."""
        self.device._is_run = True
        self.device._writer = None

        async def fake_connect(*, check_protocol: bool = False) -> bool:
            del check_protocol
            self.device._writer = MagicMock()
            return True

        with patch.object(self.device, "connect", side_effect=fake_connect):
            await self.device._connect_loop()

        assert self.device._writer is not None

    @pytest.mark.asyncio
    async def test_run_breaks_when_stopped_during_connect_loop(self) -> None:
        """Test _run exits immediately if closed while _connect_loop runs."""
        self.device._is_run = True

        async def fake_connect_loop() -> None:
            self.device._is_run = False

        with patch.object(self.device, "_connect_loop", side_effect=fake_connect_loop):
            await self.device._run()
        assert self.device._is_run is False

    @pytest.mark.asyncio
    async def test_run_reconnects_when_connect_loop_leaves_no_reader_task(self) -> None:
        """Test _run tears down and retries if _connect_loop leaves no reader task."""
        calls = {"n": 0}

        async def fake_connect_loop() -> None:
            calls["n"] += 1
            if calls["n"] >= 2:
                self.device._is_run = False

        with (
            patch.object(self.device, "_connect_loop", side_effect=fake_connect_loop),
            patch.object(self.device, "close_socket", new=AsyncMock()) as close_mock,
        ):
            self.device._is_run = True
            self.device._reader_task = None
            await self.device._run()

        assert calls["n"] == 2
        close_mock.assert_called_once()

    @pytest.mark.asyncio
    async def test_run_polls_without_reconnecting_while_reader_task_is_healthy(
        self,
    ) -> None:
        """Test _run's steady-state pass: a still-running reader task is left alone.

        Only once the reader task actually finishes should _run treat it as
        a reason to reconnect; a poll where it's simply still running must
        not trigger close_socket()/reconnect.
        """
        calls = {"n": 0}
        reader_may_finish = asyncio.Event()

        async def fake_connect_loop() -> None:
            calls["n"] += 1
            self.device._writer = MagicMock()
            if calls["n"] == 1:

                async def _reader_body() -> None:
                    await reader_may_finish.wait()
                    raise SocketException

                self.device._reader_task = asyncio.create_task(_reader_body())
            else:
                self.device._is_run = False

        check_refresh_calls = {"n": 0}

        async def fake_check_refresh(_now: float) -> None:
            check_refresh_calls["n"] += 1
            # Let the reader task stay healthy through one full poll pass
            # before finally finishing on the next one.
            if check_refresh_calls["n"] >= 2:
                reader_may_finish.set()

        with (
            patch.object(self.device, "_connect_loop", side_effect=fake_connect_loop),
            patch.object(self.device, "_check_refresh", side_effect=fake_check_refresh),
            patch.object(self.device, "_check_heartbeat", new=AsyncMock()),
            patch.object(self.device, "close_socket", new=AsyncMock()) as close_mock,
            patch("midealocal.device.SOCKET_TIMEOUT", 0.01),
        ):
            self.device._is_run = True
            await self.device._run()

        assert calls["n"] == 2
        assert check_refresh_calls["n"] >= 2
        close_mock.assert_called_once()

    @pytest.mark.asyncio
    @pytest.mark.parametrize(
        "exc",
        [
            SocketException,
            ConnectionResetError,
            OSError,
            ResponseException,
            ValueError,
        ],
    )
    async def test_run_reconnects_when_reader_task_raises(
        self,
        exc: type[Exception],
    ) -> None:
        """Test _run tears down and reconnects for every kind of reader-task error."""
        calls = {"n": 0}

        async def fake_connect_loop() -> None:
            calls["n"] += 1
            self.device._writer = MagicMock()
            if calls["n"] == 1:

                async def _raise() -> None:
                    raise exc

                self.device._reader_task = asyncio.create_task(_raise())
            else:
                self.device._is_run = False

        with (
            patch.object(self.device, "_connect_loop", side_effect=fake_connect_loop),
            patch.object(self.device, "_check_refresh", new=AsyncMock()),
            patch.object(self.device, "_check_heartbeat", new=AsyncMock()),
            patch.object(self.device, "close_socket", new=AsyncMock()) as close_mock,
        ):
            self.device._is_run = True
            await self.device._run()

        assert calls["n"] == 2
        close_mock.assert_called_once()

    @pytest.mark.asyncio
    async def test_run_reconnects_when_check_refresh_finds_no_supported_protocol(
        self,
    ) -> None:
        """NoSupportedProtocol from _check_refresh must reconnect, like every error.

        Continuing on the same connection could never recover: once every
        command is in _unsupported_protocol, refresh_status takes the SKIP
        branch for all of them, so no further error can ever be raised to
        break the loop. The device would stay stuck until restarted.
        """
        connect_calls = {"n": 0}

        async def fake_connect_loop() -> None:
            connect_calls["n"] += 1
            self.device._writer = MagicMock()
            self.device._reader_task = asyncio.create_task(asyncio.sleep(0))
            if connect_calls["n"] >= 2:
                self.device._is_run = False

        check_refresh_mock = AsyncMock(side_effect=NoSupportedProtocol)

        with (
            patch.object(self.device, "_connect_loop", side_effect=fake_connect_loop),
            patch.object(self.device, "_check_refresh", check_refresh_mock),
            patch.object(self.device, "_check_heartbeat", new=AsyncMock()),
            patch.object(self.device, "close_socket", new=AsyncMock()) as close_mock,
        ):
            self.device._is_run = True
            await self.device._run()

        # The point of the fix: the connection is dropped AND the loop dials
        # again, rather than spinning forever on a socket no command can use.
        assert connect_calls["n"] == 2
        check_refresh_mock.assert_called_once()
        close_mock.assert_called_once()

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
