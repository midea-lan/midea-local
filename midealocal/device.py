"""Midea local device."""

import asyncio
import contextlib
import logging
import time
from collections.abc import Callable, Mapping, Sequence
from enum import IntEnum, StrEnum
from typing import Any, ClassVar, NotRequired, TypedDict, Unpack

from typing_extensions import deprecated

from .const import DeviceType, ProtocolVersion
from .exceptions import SocketException
from .message import (
    MessageApplianceResponse,
    MessageQueryAppliance,
    MessageQuestCustom,
    MessageRequest,
    MessageType,
)
from .packet_builder import PacketBuilder
from .security import (
    MSGTYPE_ENCRYPTED_REQUEST,
    MSGTYPE_HANDSHAKE_REQUEST,
    LocalSecurity,
)

MIN_AUTH_RESPONSE = 20
MIN_MSG_LENGTH = 56
MESSAGE_TYPE_INDEX = 9  # offset of the message-type byte in the 10-byte header
MIN_V2_FACTUAL_MSG_LENGTH = 6
RESPONSE_TIMEOUT = 12  # read-loop recv timeout, 12 * 10s = 120s
SOCKET_TIMEOUT = 10  # socket connection default timeout
# fix https://github.com/wuwentao/midea_ac_lan/issues/658#issuecomment-4555804288
QUERY_TIMEOUT = (
    5  # default is 1s, 0xAC have more queries, set to 2s, latest: increase to 5s
)
# A single timeout during the initial protocol probe blacklists the command for
# the whole connection, even when it was just a slow/not-yet-ready device rather
# than a genuinely unsupported protocol. Give it one more try before giving up on it.
QUERY_PROBE_RETRIES = 2

_LOGGER = logging.getLogger(__name__)

# Sentinel returned by translators to preserve the stored attribute value.
SKIP_ATTRIBUTE = object()

# Private marker that distinguishes an omitted default from an explicit default.
_NO_DEFAULT = object()


def list_translator(
    values: Sequence[str],
    *,
    offset: int = 0,
    min_index: int = 0,
    default: str | None = None,
    key: Callable[[int], int] | None = None,
) -> Callable[[int], str | None]:
    """Build an update_attributes_from_message() translator for enum-style values.

    Returns a callable that maps a raw index into ``values``, or ``default``
    if the index falls outside ``[min_index, len(values))``, instead of
    raising or wrapping around on a negative index. ``offset`` shifts the raw
    value before indexing, for devices that report 1-based (or otherwise
    offset) indices; ``min_index`` excludes otherwise-valid low indices some
    devices reserve (e.g. 0 meaning "no value"). ``key``, if given, is applied
    to the raw value first, for devices that encode the index indirectly
    (e.g. a physical angle that first needs converting to a list position).
    """

    def _translate(index: int) -> str | None:
        i = (key(index) if key is not None else index) - offset
        return values[i] if min_index <= i < len(values) else default

    return _translate


def dict_translator(
    mapping: Mapping[Any, Any],
    default: Any = _NO_DEFAULT,  # noqa: ANN401
) -> Callable[[Any], Any]:
    """Build an update_attributes_from_message() translator for coded values.

    Looks up the raw value in ``mapping``. If absent, returns ``default`` when
    given, otherwise passes the raw value through unchanged.
    """

    def _translate(value: Any) -> Any:  # noqa: ANN401
        return mapping.get(value, value if default is _NO_DEFAULT else default)

    return _translate


def precision_halves_translator(
    precision_halves: bool | None,
) -> Callable[[float], float]:
    """Build an update_attributes_from_message() translator for halved readings.

    Some devices report values doubled (in 0.5-unit steps) when their
    ``precision_halves`` customize flag is enabled. Returns a callable that
    divides by 2 when ``precision_halves`` is truthy, otherwise passes the
    value through unchanged.
    """

    def _translate(value: float) -> float:
        return value / 2 if precision_halves else value

    return _translate


def multiplier_translator(multiplier: float) -> Callable[[float | None], float | None]:
    """Build an update_attributes_from_message() translator that scales a reading.

    Rounds ``value * multiplier`` to the nearest int, unless ``multiplier`` is
    1.0 (a no-op) or the raw value is ``None`` (unknown).
    """

    def _translate(value: float | None) -> float | None:
        if value is None or multiplier == 1.0:
            return value
        return round(value * multiplier)

    return _translate


def sentinel_translator(sentinel: Any, replacement: Any) -> Callable[[Any], Any]:  # noqa: ANN401
    """Build an update_attributes_from_message() translator for sentinel values.

    Swaps a device-specific "unset" sentinel raw value for a display
    placeholder, passing every other value through unchanged.
    """

    def _translate(value: Any) -> Any:  # noqa: ANN401
        return replacement if value == sentinel else value

    return _translate


class AuthException(Exception):
    """Authentication exception."""


class ResponseException(Exception):
    """Response exception."""


class NoSupportedProtocol(Exception):
    """Query device failed exception."""


class DeviceAttributes(StrEnum):
    """Device attributes."""


class MessageResult(IntEnum):
    """Parse message result."""

    PADDING = 0
    SUCCESS = 1
    UNKNOWN = 96
    UNEXPECTED = 97
    TIMEOUT = 98
    ERROR = 99


class MideaDeviceInitKwargs(TypedDict):
    """Connection/identity kwargs forwarded by device subclasses to MideaDevice.

    Every device subclass's ``__init__`` accepts these via ``**kwargs`` and
    forwards them unchanged to ``MideaDevice.__init__``. Keeping them in one
    place means adding a field here (e.g. ``mac``, ``serial_number``) is
    enough for every subclass to accept and forward it, with no per-subclass
    signature changes required.
    """

    name: str
    device_id: int
    ip_address: str
    port: int
    token: str
    key: str
    device_protocol: ProtocolVersion
    model: str
    subtype: int
    mac: NotRequired[str | None]
    serial_number: NotRequired[str | None]


class MideaDevice:
    """Midea device."""

    def __init__(
        self,
        *,
        device_type: DeviceType,
        attributes: dict,
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Midea device initialization."""
        self._attributes = attributes or {}
        self._reader: asyncio.StreamReader | None = None
        self._writer: asyncio.StreamWriter | None = None
        self._ip_address = kwargs["ip_address"]
        self._port = kwargs["port"]
        self._security = LocalSecurity()
        self._token = bytes.fromhex(kwargs["token"])
        self._key = bytes.fromhex(kwargs["key"])
        self._buffer = b""
        self._device_name = kwargs["name"]
        self._device_id = kwargs["device_id"]
        self._device_type = device_type
        self._device_protocol_version = kwargs["device_protocol"]
        self._model = kwargs["model"]
        self._subtype = kwargs["subtype"]
        self._message_protocol_version: int = 0
        self._updates: list[Callable[[dict[str, Any]], None]] = []
        self._unsupported_protocol: list[str] = []
        self._is_run: bool = False
        self._available = False
        self._appliance_query = True
        self._refresh_interval = 30
        self._heartbeat_interval = SOCKET_TIMEOUT
        self._default_refresh_interval = 30
        self._previous_refresh = 0.0
        self._previous_heartbeat = 0.0
        self._task: asyncio.Task | None = None
        self._reader_task: asyncio.Task | None = None
        # This protocol has no per-message correlation id, so at most one
        # query/response exchange can ever be outstanding at a time.
        self._query_lock = asyncio.Lock()
        self._response_waiter: asyncio.Future[MessageResult] | None = None
        self._refresh_requested = False
        self.name = self._device_name
        self.set_mac(kwargs.get("mac"))
        # Discovery may report a fixed-width serial padded with NUL bytes or an
        # empty ``apc_sn`` attribute; normalize these to None (mirrors set_mac).
        sn = kwargs.get("serial_number")
        self._serial_number = (sn.strip("\x00").strip() or None) if sn else None

    _fahrenheit_default: ClassVar[bool] = False

    @classmethod
    def get_dict_key_by_value(
        cls: type["MideaDevice"],
        dict_name: str,
        value: str,
    ) -> Any:  # noqa: ANN401
        """Get key by value from a specified class dictionary."""
        if hasattr(cls, dict_name) and isinstance(getattr(cls, dict_name), dict):
            target_dict: dict[Any, str] = getattr(cls, dict_name)
            for key, val in target_dict.items():
                if val == value:
                    return key
            return None  # if not found, return None
        raise ValueError(
            f"Class '{cls.__name__}' does not have a dict named '{dict_name}'.",
        )

    def celsius_to_fahrenheit(
        self,
        celsius: float,
        is_fahrenheit: bool | None = None,
    ) -> float:
        """Convert Celsius to Fahrenheit."""
        should_convert = (
            is_fahrenheit
            if is_fahrenheit is not None
            else getattr(self, "_fahrenheit", self._fahrenheit_default)
        )
        if should_convert:
            return celsius * 9.0 / 5.0 + 32
        return celsius  # Return Celsius if not converting

    def fahrenheit_to_celsius(
        self,
        fahrenheit: float,
        is_fahrenheit: bool | None = None,
    ) -> float:
        """Convert Fahrenheit to Celsius."""
        should_convert = (
            is_fahrenheit
            if is_fahrenheit is not None
            else getattr(self, "_fahrenheit", self._fahrenheit_default)
        )
        if should_convert:
            return (fahrenheit - 32.0) * 5.0 / 9.0
        return fahrenheit  # Return Fahrenheit if not converting

    @property
    def available(self) -> bool:
        """Device available."""
        return self._available

    @property
    def device_id(self) -> int:
        """Device ID."""
        return self._device_id

    @property
    def device_type(self) -> DeviceType:
        """Device type."""
        return self._device_type

    @property
    def model(self) -> str:
        """Device model."""
        return self._model

    @property
    def subtype(self) -> int:
        """Device subtype."""
        return self._subtype

    @property
    def mac(self) -> str | None:
        """Device MAC address."""
        return self._mac

    @property
    def serial_number(self) -> str | None:
        """Device serial number."""
        return self._serial_number

    @staticmethod
    def fetch_v2_message(msg: bytes) -> tuple[list, bytes]:
        """Fetch V2 message."""
        result = []
        while len(msg) > 0:
            factual_msg_len = len(msg)
            if factual_msg_len < MIN_V2_FACTUAL_MSG_LENGTH:
                break
            alleged_msg_len = msg[4] + (msg[5] << 8)
            if factual_msg_len >= alleged_msg_len:
                result.append(msg[:alleged_msg_len])
                msg = msg[alleged_msg_len:]
            else:
                break
        return result, msg

    async def connect(self, check_protocol: bool = False) -> bool:
        """Connect to device."""
        connected = False
        try:
            _LOGGER.debug(
                "[%s] Connecting to %s:%s",
                self._device_id,
                self._ip_address,
                self._port,
            )
            self._reader, self._writer = await asyncio.wait_for(
                asyncio.open_connection(self._ip_address, self._port),
                timeout=SOCKET_TIMEOUT,
            )
            _LOGGER.debug("[%s] Connected", self._device_id)
            if self._device_protocol_version == ProtocolVersion.V3:
                await self.authenticate()
            # Start the sole reader only now: authenticate() does its own
            # raw read() on self._reader for the handshake response, and
            # asyncio.StreamReader raises RuntimeError if a second coroutine
            # (here, _read_loop) awaits read() while one is already pending.
            self._reader_task = asyncio.create_task(self._read_loop())
            # 1. midea_ac_lan add device verify token with connect and auth
            # 2. init connection, check_protocol
            if check_protocol:
                await self.refresh_status(check_protocol=check_protocol)
            connected = True
        except TimeoutError:
            _LOGGER.debug("[%s] Connection timed out", self._device_id)
        except OSError:  # refresh_status exception
            _LOGGER.debug("[%s] Connection error", self._device_id)
        except AuthException:  # authenticate exception
            _LOGGER.debug("[%s] Authentication failed", self._device_id)
        except SocketException:  # refresh_status exception
            _LOGGER.debug("[%s] Connect socket exception", self._device_id)
        except NoSupportedProtocol:  # refresh_status exception
            _LOGGER.debug("[%s] No supported query protocol", self._device_id)
        except Exception as e:
            _LOGGER.exception(
                "[%s] Unknown error during connect device",
                self._device_id,
                exc_info=e,
            )
        finally:
            # Any failure path leaves connected False; release the socket once
            # here instead of repeating close_socket() in every handler.
            if not connected:
                await self.close_socket()
        # enable/disable device in init connection
        if check_protocol:
            self.set_available(connected)
        return connected

    async def authenticate(self) -> None:
        """Authenticate to device. V3 only."""
        request = self._security.encode_8370(self._token, MSGTYPE_HANDSHAKE_REQUEST)
        if not self._writer or not self._reader:
            _LOGGER.debug(
                "[%s] authenticate failure, device socket is none",
                self._device_id,
            )
            # raise exception to connect loop
            raise SocketException
        _LOGGER.debug("[%s] Authentication handshaking", self._device_id)
        self._writer.write(request)
        response = await asyncio.wait_for(
            self._reader.read(512),
            timeout=SOCKET_TIMEOUT,
        )
        _LOGGER.debug(
            "[%s] Received auth response with %d bytes: %s",
            self._device_id,
            len(response),
            response.hex(),
        )
        if len(response) < MIN_AUTH_RESPONSE:
            _LOGGER.debug(
                "[%s] Received auth response len %d error, bytes: %s",
                self._device_id,
                len(response),
                response.hex(),
            )
            raise AuthException
        response = response[8:72]
        self._security.tcp_key(response, self._key)
        _LOGGER.debug("[%s] Authentication success", self._device_id)

    def send_message(self, data: bytes) -> None:
        """Send message."""
        if self._device_protocol_version == ProtocolVersion.V3:
            self.send_message_v3(data, msg_type=MSGTYPE_ENCRYPTED_REQUEST)
        else:
            self.send_message_v2(data)

    def send_message_v2(self, data: bytes) -> None:
        """Send message V2."""
        if not self._writer:
            _LOGGER.debug(
                "[%s] send_message_v2 failure, device socket is none, data: %s",
                self._device_id,
                data.hex(),
            )
            # raise exception to caller
            raise SocketException
        try:
            self._writer.write(data)
        except OSError as e:
            _LOGGER.debug(
                "[%s] send_message_v2 OSError: %s",
                self._device_id,
                e,
            )
            # raise exception to caller
            raise
        except Exception as e:
            _LOGGER.exception(
                "[%s] send_message_v2 Unexpected socket error",
                self._device_id,
                exc_info=e,
            )
            # raise exception to caller
            raise

    def send_message_v3(
        self,
        data: bytes,
        msg_type: int = MSGTYPE_ENCRYPTED_REQUEST,
    ) -> None:
        """Send message V3."""
        data = self._security.encode_8370(data, msg_type)
        self.send_message_v2(data)

    def build_send(self, cmd: MessageRequest) -> None:
        """Serialize and send."""
        data = cmd.serialize()
        _LOGGER.debug("[%s] Sending: %s", self._device_id, cmd)
        msg = PacketBuilder(self._device_id, data).finalize()
        self.send_message(msg)

    async def _wait_for_query_response(self) -> None:
        """Wait for one query response, raising on timeout or bad data.

        The response itself is delivered by ``_read_loop`` (the sole reader
        of the connection) resolving ``self._response_waiter``; this method
        never touches the reader directly.
        """
        if self._reader_task is None or self._reader_task.done():
            raise SocketException
        self._response_waiter = asyncio.get_running_loop().create_future()
        try:
            await asyncio.wait_for(self._response_waiter, timeout=QUERY_TIMEOUT)
        finally:
            self._response_waiter = None

    async def _refresh_query(
        self,
        cmd: MessageRequest,
        check_protocol: bool,
        real_cmds: Sequence[MessageRequest],
    ) -> int:
        """Send one refresh_status query, returning 1 if it counts as a failure.

        Only a query that also appears in ``real_cmds`` can return 1: the
        appliance query (never in ``real_cmds``) blacklists its own protocol
        on failure without masking, or contributing to, a genuine
        "all queries failed" verdict for the caller.
        """
        if cmd.__class__.__name__ in self._unsupported_protocol:
            _LOGGER.debug(
                "[%s] refresh_status with cmd: %s, unsupported protocol, SKIP",
                self._device_id,
                cmd,
            )
            return 1 if cmd in real_cmds else 0
        # build_send exception should be caught by connect/_run
        self.build_send(cmd)
        if not check_protocol:
            return 0
        # only catch TimeoutError for check_protocol
        # unexpected exception in read loop is caught there
        try:
            attempt = 0
            while True:
                try:
                    await self._wait_for_query_response()
                    break
                except TimeoutError:
                    attempt += 1
                    if attempt >= QUERY_PROBE_RETRIES:
                        raise
                    # retry once before blacklisting: a single timeout
                    # during the probe can be a slow device, not proof
                    # the protocol is unsupported
                    self.build_send(cmd)
        except TimeoutError:
            self._unsupported_protocol.append(cmd.__class__.__name__)
            _LOGGER.debug(
                "[%s] Does not supports the protocol %s, cmd %s, ignored",
                self._device_id,
                cmd.__class__.__name__,
                cmd,
            )
            return 1 if cmd in real_cmds else 0
        except ResponseException:
            # parse msg error
            _LOGGER.debug(
                "[%s] refresh_status ResponseException %s, cmd %s",
                self._device_id,
                cmd.__class__.__name__,
                cmd,
            )
            return 1 if cmd in real_cmds else 0
        return 0

    async def refresh_status(self, check_protocol: bool = False) -> None:
        """Refresh device status."""
        async with self._query_lock:
            if self._appliance_query:
                # Sent (and, when checking, awaited) before build_query() below,
                # so the real queries it returns pick up the message protocol
                # version this reply resolves instead of one baked into them
                # before the reply arrived, which devices that validate it would
                # silently reject.
                await self._refresh_query(
                    MessageQueryAppliance(self.device_type),
                    check_protocol,
                    (),
                )
            real_cmds: list = self.build_query()
            error_count = 0
            _LOGGER.debug(
                "[%s] refresh_status with cmds: %s, check_protocol %s, \
                device %s, type %s, model %s, subtype %s, device_protocol: %s, \
                message_protocol %s, unsupported_protocol: %s",
                self._device_id,
                real_cmds,
                check_protocol,
                self._device_name,
                self._device_type,
                self._model,
                self._subtype,
                self._device_protocol_version,
                self._message_protocol_version,
                self._unsupported_protocol,
            )
            for cmd in real_cmds:
                error_count += await self._refresh_query(cmd, check_protocol, real_cmds)
                # A successful appliance query is not device status: it must not
                # mask every real status query failing. Guard against a subclass
                # whose build_query() returns [], where "all failed" would be
                # vacuous.
                if real_cmds and error_count == len(real_cmds):
                    _LOGGER.debug(
                        "[%s] all the query cmds failed %s, please report bug",
                        self._device_id,
                        real_cmds,
                    )
                    raise NoSupportedProtocol

    def pre_process_message(self, msg: bytearray) -> bool:
        """Pre process message."""
        if len(msg) <= MESSAGE_TYPE_INDEX:
            # Some devices answer a query with a payload shorter than the
            # header (observed: a 4-byte `01000000` from a 0xFA tower fan).
            # Indexing blindly raises IndexError, which aborts the whole status
            # parse and leaves every entity stuck at its last value.
            _LOGGER.debug(
                "[%s] Ignoring short message: %s",
                self._device_id,
                msg.hex(),
            )
            return False
        if msg[MESSAGE_TYPE_INDEX] == MessageType.query_appliance:
            message = MessageApplianceResponse(msg)
            self._appliance_query = False
            _LOGGER.debug("[%s] Appliance query Received: %s", self._device_id, message)
            self._message_protocol_version = message.protocol_version
            _LOGGER.debug(
                "[%s] device model %s subtype %s, device protocol %s, msg protocol %s",
                self._device_id,
                self._model,
                self._subtype,
                self._device_protocol_version,
                self._message_protocol_version,
            )
            return False
        return True

    def parse_message(self, msg: bytes) -> MessageResult:
        """Parse message."""
        if self._device_protocol_version == ProtocolVersion.V3:
            messages, self._buffer = self._security.decode_8370(self._buffer + msg)
        else:
            messages, self._buffer = self.fetch_v2_message(self._buffer + msg)
        if len(messages) == 0:
            return MessageResult.PADDING
        for message in messages:
            if message == b"ERROR":
                return MessageResult.ERROR
            payload_len = message[4] + (message[5] << 8) - 56
            payload_type = message[2] + (message[3] << 8)
            if payload_type in [0x1001, 0x0001]:
                pass
            elif len(message) > MIN_MSG_LENGTH:
                cryptographic = bytes(message[40:-16])
                if payload_len % 16 == 0:
                    decrypted: bytearray = self._security.aes_decrypt(cryptographic)
                    try:
                        cont = True
                        if self._appliance_query:
                            cont = self.pre_process_message(decrypted)
                        if cont:
                            _LOGGER.debug(
                                "[%s] process message %s for device %s, \
                                model %s, subtype %s, \
                                device protocol %s, message procol %s",
                                self._device_id,
                                decrypted.hex(),
                                self._device_name,
                                self._model,
                                self._subtype,
                                self._device_protocol_version,
                                self._message_protocol_version,
                            )
                            status = self.process_message(bytes(decrypted))
                            if len(status) == 0:
                                _LOGGER.debug(
                                    "[%s] Unidentified protocol",
                                    self._device_id,
                                )
                                continue
                            if self._should_run():
                                # Closing (e.g. Home Assistant shutting down
                                # or reloading) may already have torn down
                                # whatever these callbacks depend on; don't
                                # propagate stale reads.
                                self.update_all(status)
                    except Exception:
                        _LOGGER.exception(
                            "[%s] Error in process message %s, \
                                model %s, subtype %s, \
                                device protocol %s, message procol %s",
                            self._device_id,
                            decrypted.hex(),
                            self._model,
                            self._subtype,
                            self._device_protocol_version,
                            self._message_protocol_version,
                        )
                else:
                    _LOGGER.warning(
                        "[%s] Illegal payload, "
                        "original message = %s, buffer = %s, "
                        "8370 decoded = %s, payload type = %s, "
                        "alleged payload length = %s, factual payload length = %s, ",
                        self._device_id,
                        msg.hex(),
                        self._buffer.hex(),
                        message.hex(),
                        payload_type,
                        payload_len,
                        len(cryptographic),
                    )
            else:
                _LOGGER.warning(
                    "[%s] Illegal message, "
                    "original message = %s, buffer = %s, "
                    "8370 decoded = %s, payload type = %s, "
                    "alleged payload length = %s, message length = %s, ",
                    self._device_id,
                    msg.hex(),
                    self._buffer.hex(),
                    message.hex(),
                    payload_type,
                    payload_len,
                    len(message),
                )
        return MessageResult.SUCCESS

    def build_query(self) -> list:
        """Build query."""
        raise NotImplementedError

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Process message."""
        raise NotImplementedError

    def send_command(self, cmd_type: MessageType, cmd_body: bytearray) -> None:
        """Send command."""
        cmd = MessageQuestCustom(
            self._device_type,
            self._message_protocol_version,
            cmd_type,
            cmd_body,
        )
        try:
            self.build_send(cmd)
        except OSError as e:
            _LOGGER.debug(
                "[{%s] Interface send_command failure, %s, cmd_type: %s, cmd_body: %s",
                self._device_id,
                repr(e),
                cmd_type,
                cmd_body.hex(),
            )

    def send_heartbeat(self) -> None:
        """Send heartbeat."""
        msg = PacketBuilder(self._device_id, bytearray([0x00])).finalize(msg_type=0)
        self.send_message(msg)

    def request_refresh(self) -> None:
        """Ask the read loop to refresh status once the current message is handled.

        For a subclass whose process_message() learns, from the message
        itself, that status may already be stale (e.g. a command was just
        acknowledged) -- process_message() must stay synchronous, so it
        cannot await refresh_status() itself. This defers the actual
        (async) refresh to the read loop, which already owns the
        connection and runs immediately after the message that requested it.
        """
        self._refresh_requested = True

    def register_update(self, update: Callable[[dict[str, Any]], None]) -> None:
        """Register update."""
        self._updates.append(update)

    def unregister_update(self, update: Callable[[dict[str, Any]], None]) -> None:
        """Unregister update."""
        if update in self._updates:
            self._updates.remove(update)

    def update_all(self, status: dict[str, Any]) -> None:
        """Update all."""
        _LOGGER.debug("[%s] Status update: %s", self._device_id, status)
        for update in self._updates:
            try:
                update(status)
            except Exception:
                _LOGGER.exception(
                    "[%s] Error in update callback %s",
                    self._device_id,
                    update,
                )

    def update_attributes_from_message(
        self,
        message: object,
        translators: dict[str, Callable[[Any], str | float | bool | None]]
        | None = None,
        default_transform: Callable[[Any], str | float | bool | None] | None = None,
    ) -> dict[str, Any]:
        """Copy matching attributes from a parsed response into self._attributes.

        For each attribute the device declares, if ``message`` carries a
        same-named field, run it through ``translators[attr]`` (if present) or
        ``default_transform`` (if given and no specific translator matched),
        then store the result in both ``self._attributes`` and the returned
        status dict -- so pushed updates and ``device.attributes`` reads can
        never disagree on the value. A translator may return ``SKIP_ATTRIBUTE``
        to leave the attribute's stored value untouched for this message.
        """
        new_status: dict[str, Any] = {}
        translators = translators or {}
        for status in self._attributes:
            if hasattr(message, str(status)):
                value = getattr(message, str(status))
                if status in translators:
                    value = translators[status](value)
                elif default_transform is not None:
                    value = default_transform(value)
                if value is SKIP_ATTRIBUTE:
                    continue
                self._attributes[status] = value
                new_status[str(status)] = value
        return new_status

    def set_available(self, available: bool = True) -> None:
        """Set available value."""
        _LOGGER.debug(
            "[%s] %s device",
            self._device_id,
            "Enabling" if available else "Disabling",
        )
        self._available = available
        status = {"available": available}
        self.update_all(status)

    @deprecated("enable_device is replaced by set_available")
    def enable_device(self, available: bool = True) -> None:
        """Enable device."""
        self.set_available(available)

    async def open(self) -> None:
        """Start the supervisor task."""
        if not self._is_run:
            self._is_run = True
            self._task = asyncio.create_task(self._run())

    async def close(self) -> None:
        """Stop the supervisor task and close the connection."""
        if self._is_run:
            self._is_run = False
            task, self._task = self._task, None
            if task is not None:
                task.cancel()
                with contextlib.suppress(asyncio.CancelledError):
                    await task
            await self.close_socket()

    def _should_run(self) -> bool:
        """Return whether the service loop should keep running."""
        return self._is_run

    async def close_socket(self) -> None:
        """Close socket."""
        self._unsupported_protocol = []
        # Re-arm the appliance query too. It is cleared in pre_process_message
        # and was never set back, so a reconnected device would skip protocol
        # detection and re-probe with build_query() alone.
        self._appliance_query = True
        self._buffer = b""
        if self._response_waiter is not None and not self._response_waiter.done():
            # Unblock anyone awaiting a response now, rather than leaving them
            # to hang until their own timeout fires.
            self._response_waiter.set_exception(SocketException)
        reader_task, self._reader_task = self._reader_task, None
        if reader_task is not None:
            # Not awaited: it already raised (and logged) whatever tore the
            # connection down, or is merely blocked on a read that closing
            # the writer below will unblock; either way, awaiting it here
            # would risk swallowing this coroutine's own cancellation instead.
            reader_task.cancel()
        writer, self._writer = self._writer, None
        self._reader = None
        if writer is not None:
            writer.close()
            try:
                await writer.wait_closed()
                _LOGGER.debug("[%s] Socket closed", self._device_id)
            except OSError as e:
                _LOGGER.debug("[%s] Error while closing socket: %s", self._device_id, e)

    async def set_ip_address(self, ip_address: str) -> None:
        """Set IP address."""
        if self._ip_address != ip_address:
            _LOGGER.debug("[%s] Update IP address to %s", self._device_id, ip_address)
            self._ip_address = ip_address
            await self.close_socket()

    def set_mac(self, mac: str | None) -> None:
        """Set MAC."""
        self._mac = mac or None

    def set_refresh_interval(self, refresh_interval: int) -> None:
        """Set refresh interval."""
        self._refresh_interval = refresh_interval

    async def _check_refresh(self, now: float) -> None:
        if 0 < self._refresh_interval <= now - self._previous_refresh:
            await self.refresh_status()
            self._previous_refresh = now

    async def _check_heartbeat(self, now: float) -> None:
        if now - self._previous_heartbeat >= self._heartbeat_interval:
            self.send_heartbeat()
            self._previous_heartbeat = now

    async def _connect_loop(self) -> None:
        """Connect loop until device online."""
        # connect loop until online
        connection_retries = 0
        while self._writer is None and self._is_run:
            _LOGGER.debug("[%s] Socket is None, try to connect", self._device_id)
            # Re-check _should_run(): close() may have requested shutdown after
            # the while guard was evaluated, so skip opening a socket / network
            # I/O once teardown is in progress.
            if self._should_run() and await self.connect(check_protocol=True) is False:
                await self.close_socket()
                connection_retries += 1
                # Sleep time with exponential backoff, maximum 600 seconds
                sleep_time = min(5 * (2 ** (connection_retries - 1)), 600)
                _LOGGER.warning(
                    "[%s] Unable to connect, sleep %s seconds and retry",
                    self._device_id,
                    sleep_time,
                )
                # Cancellation (from close()) interrupts this immediately.
                await asyncio.sleep(sleep_time)

    async def _read_loop(self) -> None:
        """Sole reader of self._reader for this connection's lifetime.

        Resolves self._response_waiter for anyone awaiting a specific query
        response; otherwise dispatches parsed status via parse_message()'s
        own call to update_all(). Raises to signal the supervisor to
        reconnect when the connection is stale or broken.
        """
        if self._reader is None:
            raise SocketException
        reader = self._reader
        timeout_counter = 0
        while True:
            try:
                data = await asyncio.wait_for(
                    reader.read(512),
                    timeout=SOCKET_TIMEOUT,
                )
            except TimeoutError:
                timeout_counter += 1
                if timeout_counter >= RESPONSE_TIMEOUT:
                    timeout_exc = SocketException()
                    self._fail_waiter(timeout_exc)
                    raise timeout_exc from None
                continue
            except Exception as read_exc:
                self._fail_waiter(read_exc)
                raise
            if len(data) == 0:
                reset_exc = ConnectionResetError("Connection closed by peer.")
                self._fail_waiter(reset_exc)
                raise reset_exc
            timeout_counter = 0
            try:
                result = self.parse_message(data)
            except Exception as parse_exc:
                self._fail_waiter(parse_exc)
                raise
            if self._refresh_requested:
                self._refresh_requested = False
                # Scheduled, not awaited: refresh_status() takes
                # self._query_lock, which another coroutine may already
                # hold while it awaits a response that only this same read
                # loop, continuing on to the next iteration, can ever
                # deliver. Awaiting it here would deadlock that caller.
                asyncio.create_task(self._run_requested_refresh())  # noqa: RUF006
            if result == MessageResult.PADDING:
                continue
            self._resolve_waiter_or_raise(result)

    async def _run_requested_refresh(self) -> None:
        """Run a request_refresh()-triggered refresh_status(), logging failures.

        Detached from _read_loop (see its caller); nothing else observes
        this task, so a failure must be logged here instead of propagating.
        """
        try:
            await self.refresh_status()
        except Exception:
            _LOGGER.exception(
                "[%s] Requested refresh failed",
                self._device_id,
            )

    def _resolve_waiter_or_raise(self, result: MessageResult) -> None:
        """Resolve/reject a pending query waiter, or raise for an unsolicited error.

        Called by _read_loop for every non-PADDING parsed result. A waiter,
        if present, always takes the response (success or not) instead of
        tearing down the connection -- that failure is scoped to the one
        query awaiting it. Only an ERROR frame nobody is waiting for is
        treated as fatal for the connection.
        """
        if self._response_waiter is not None and not self._response_waiter.done():
            if result == MessageResult.SUCCESS:
                self._response_waiter.set_result(result)
            else:
                self._response_waiter.set_exception(ResponseException())
        elif result == MessageResult.ERROR:
            raise ResponseException

    def _fail_waiter(self, exc: BaseException) -> None:
        if self._response_waiter is not None and not self._response_waiter.done():
            self._response_waiter.set_exception(exc)

    async def _run(self) -> None:
        """Supervise the connection: connect/reconnect, refresh, heartbeat.

        1. first/init connection
            1.1 connect() device loop, pass, enable device
            1.2 auth for v3 device, MUST pass for v3 device
            1.3 init refresh_status, send query and check supported protocol
                1.3.1 get response and add timeout query cmd to not supported
                1.3.2 parse recv response/status for supported protocol
        2. after socket/device connected, check for heartbeat/refresh_status
        3. job1: check refresh_interval
            3.1 socket/device connection should exist
            3.2 send only supported query and refresh status in main loop recv
        4. job2: check heartbeat interval
            4.1 socket/device connection should exist
            4.2 send heartbeat packet to keep alive

        scenario/bug fix:
        1. device running and power off become offline, status update
        2. device disconnected and power on, become online, status update
        3. set command call build_send, read loop recv socket msg and refresh
        """
        # service loop
        while self._is_run:
            # connect loop until device online
            await self._connect_loop()
            if not self._should_run():
                break
            start = time.time()
            self._previous_refresh = self._previous_heartbeat = start
            reader_task = self._reader_task
            if reader_task is None:
                await self.close_socket()
                continue
            # refresh/heartbeat/watch-reader loop after connected
            while True:
                should_reconnect = False
                error_msg: str | None = None
                try:
                    now = time.time()
                    await self._check_refresh(now)
                    await self._check_heartbeat(now)
                    # Poll at the same cadence the old recv() timeout used, so
                    # refresh/heartbeat get checked every SOCKET_TIMEOUT
                    # regardless of how the two intervals are configured.
                    done, _pending = await asyncio.wait(
                        {reader_task},
                        timeout=SOCKET_TIMEOUT,
                    )
                    if reader_task in done:
                        # _read_loop only ever exits by raising; result()
                        # re-raises that exception here.
                        reader_task.result()
                        should_reconnect = True
                except SocketException:  # refresh_status
                    error_msg = "Socket Exception"
                    should_reconnect = True
                except NoSupportedProtocol:
                    error_msg = "No Supported protocol"
                    should_reconnect = True
                except ConnectionResetError:
                    error_msg = "Connection reset by peer"
                    should_reconnect = True
                except OSError:
                    error_msg = "OS error"
                    should_reconnect = True
                except ResponseException:
                    error_msg = "Message 'ERROR' received"
                    should_reconnect = True
                except Exception as e:
                    _LOGGER.exception(
                        "[%s] Unexpected error",
                        self._device_id,
                        exc_info=e,
                    )
                    should_reconnect = True
                if error_msg:
                    _LOGGER.debug("[%s] %s", self._device_id, error_msg)
                if should_reconnect:
                    await self.close_socket()
                    break

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Set attribute."""
        raise NotImplementedError

    def get_attribute(self, attr: str) -> bool | int | str | list[int] | None:
        """Get attribute."""
        return self._attributes.get(attr)

    def set_customize(self, customize: str) -> None:
        """Set customize."""

    @property
    def attributes(self) -> dict[str, Any]:
        """Attributes."""
        ret = {}
        for status in self._attributes:
            ret[str(status)] = self._attributes[status]
        return ret
