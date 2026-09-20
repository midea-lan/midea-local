"""Midea local device."""

import logging
import socket
import threading
import time
from collections.abc import Callable
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
RESPONSE_TIMEOUT = 12  # main loop socket recv timeout, 12 * 10s = 120s
SOCKET_TIMEOUT = 10  # socket connection default timeout
# fix https://github.com/wuwentao/midea_ac_lan/issues/658#issuecomment-4555804288
QUERY_TIMEOUT = (
    5  # default is 1s, 0xAC have more queries, set to 2s, latest: increase to 5s
)

_LOGGER = logging.getLogger(__name__)


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


class MideaDevice(threading.Thread):
    """Midea device."""

    def __init__(
        self,
        *,
        device_type: DeviceType,
        attributes: dict,
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Midea device initialization."""
        threading.Thread.__init__(self)
        self._attributes = attributes or {}
        self._socket: socket.socket | None = None
        self._ip_address = kwargs["ip_address"]
        self._port = kwargs["port"]
        self._security = LocalSecurity()
        self._socket_lock = threading.RLock()
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

    def connect(self, check_protocol: bool = False) -> bool:
        """Connect to device."""
        connected = False
        sock: socket.socket | None = None
        with self._socket_lock:
            was_running = self._is_run
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                self._socket = sock
                sock.settimeout(SOCKET_TIMEOUT)
                _LOGGER.debug(
                    "[%s] Connecting to %s:%s",
                    self._device_id,
                    self._ip_address,
                    self._port,
                )
                sock.connect((self._ip_address, self._port))
                _LOGGER.debug("[%s] Connected", self._device_id)
                if self._device_protocol_version == ProtocolVersion.V3:
                    self.authenticate()
                # 1. midea_ac_lan add device verify token with connect and auth
                # 2. init connection, check_protocol
                if check_protocol:
                    self.refresh_status(check_protocol=check_protocol)
                if was_running and not self._is_run:
                    _LOGGER.debug(
                        "[%s] Connection closed before lifecycle completed",
                        self._device_id,
                    )
                else:
                    connected = True
            except TimeoutError:
                _LOGGER.debug("[%s] Connection timed out", self._device_id)
            except OSError:  # refresh_status exception
                _LOGGER.debug("[%s] Connection error", self._device_id)
            except AuthException:  # authenticate exception
                _LOGGER.warning("[%s] Authentication failed", self._device_id)
            except SocketException:  # refresh_status exception
                _LOGGER.debug("[%s] Connect socket exception", self._device_id)
            except NoSupportedProtocol:  # refresh_status exception
                _LOGGER.warning("[%s] No supported query protocol", self._device_id)
            except Exception as e:
                _LOGGER.exception(
                    "[%s] Unknown error during connect device",
                    self._device_id,
                    exc_info=e,
                )
            finally:
                # Any failure path leaves connected False; release the socket once
                # here instead of repeating close_socket() in every handler.
                if not connected and sock is not None:
                    self.close_socket(sock)
        # enable/disable device in init connection
        if check_protocol:
            self.set_available(connected)
        return connected

    def authenticate(self) -> None:
        """Authenticate to device. V3 only."""
        request = self._security.encode_8370(self._token, MSGTYPE_HANDSHAKE_REQUEST)
        if not self._socket:
            _LOGGER.debug(
                "[%s] authenticate failure, device socket is none",
                self._device_id,
            )
            # raise exception to connect loop
            raise SocketException
        _LOGGER.debug("[%s] Authentication handshaking", self._device_id)
        self._socket.send(request)
        response = self._socket.recv(512)
        _LOGGER.debug(
            "[%s] Received auth response with %d bytes: %s",
            self._device_id,
            len(response),
            response.hex(),
        )
        if len(response) < MIN_AUTH_RESPONSE:
            _LOGGER.warning(
                "[%s] Received auth response len %d error, bytes: %s",
                self._device_id,
                len(response),
                response.hex(),
            )
            raise AuthException
        response = response[8:72]
        self._security.tcp_key(response, self._key)
        _LOGGER.debug("[%s] Authentication success", self._device_id)

    def send_message(self, data: bytes, query: bool = False) -> None:
        """Send message."""
        if self._device_protocol_version == ProtocolVersion.V3:
            self.send_message_v3(data, msg_type=MSGTYPE_ENCRYPTED_REQUEST, query=query)
        else:
            self.send_message_v2(data, query=query)

    def send_message_v2(self, data: bytes, query: bool = False) -> None:
        """Send message V2."""
        if not self._socket:
            _LOGGER.debug(
                "[%s] send_message_v2 failure, device socket is none, data: %s",
                self._device_id,
                data.hex(),
            )
            # raise exception to main loop
            raise SocketException
        try:
            # query msg, set timeout to QUERY_TIMEOUT
            if query:
                self._socket.settimeout(QUERY_TIMEOUT)
            self._socket.send(data)
        except TimeoutError:
            _LOGGER.debug(
                "[%s] send_message_v2 timed out",
                self._device_id,
            )
            # raise exception to main loop
            raise
        except ConnectionResetError as e:
            _LOGGER.debug(
                "[%s] send_message_v2 ConnectionResetError: %s",
                self._device_id,
                e,
            )
            # raise exception to main loop
            raise
        except OSError as e:
            _LOGGER.debug(
                "[%s] send_message_v2 OSError: %s",
                self._device_id,
                e,
            )
            # raise exception to main loop
            raise
        except Exception as e:
            _LOGGER.exception(
                "[%s] send_message_v2 Unexpected socket error",
                self._device_id,
                exc_info=e,
            )
            # raise exception to main loop
            raise

    def send_message_v3(
        self,
        data: bytes,
        msg_type: int = MSGTYPE_ENCRYPTED_REQUEST,
        query: bool = False,
    ) -> None:
        """Send message V3."""
        data = self._security.encode_8370(data, msg_type)
        self.send_message_v2(data, query=query)

    def build_send(self, cmd: MessageRequest, query: bool = False) -> None:
        """Serialize and send."""
        data = cmd.serialize()
        _LOGGER.debug("[%s] Sending: %s, query is %s", self._device_id, cmd, query)
        msg = PacketBuilder(self._device_id, data).finalize()
        self.send_message(msg, query=query)

    def _await_query_reply(self) -> None:
        """Block until the current query is answered (checked pass only).

        Loops over socket reads until parse_message reports SUCCESS, then
        restores SOCKET_TIMEOUT. A PADDING result keeps reading; any other
        result raises ResponseException. A missing socket or a closed peer
        raises to the connect/main loop. TimeoutError from recv propagates to
        the caller, which records the query as unsupported.
        """
        while True:
            if not self._socket:
                _LOGGER.debug("[%s] device socket is none", self._device_id)
                # raise exception to connect/main loop
                raise SocketException
            msg = self._socket.recv(512)
            if len(msg) == 0:
                raise ConnectionResetError("Connection closed by peer.")
            result = self.parse_message(msg)
            # Prevent infinite loop
            if result == MessageResult.SUCCESS:
                break
            if result == MessageResult.PADDING:
                continue
            raise ResponseException
        # recovery SOCKET_TIMEOUT after recv msg
        self._socket.settimeout(SOCKET_TIMEOUT)

    def _advance_query_stage(
        self,
        cmds: list,
        queued: set[str],
        real_cmds: list,
        status_appended: bool,
    ) -> tuple[list, bool, bool]:
        """Append the next due query stage to ``cmds`` in dependency order.

        Queries are built lazily, one stage at a time, so each stage sees the
        state resolved by the previous stage's reply: the one-time init queries
        (e.g. the AC B5 capability probes, which need the protocol version the
        appliance reply reports) run first, offered until they are exhausted,
        then the recurring status queries (which may need the decoded
        capabilities). Commands already queued this refresh are filtered out, so
        a probe left armed after a timeout -- still reported by build_init_query
        but recorded in _unsupported_protocol -- is not queued a second time.

        Returns the status-query list (for the all-failed check), whether the
        status stage has been appended yet, and whether this call appended
        anything (the unchecked pass loops on it until every stage is queued).
        """
        # Prefer the message protocol version reported by the appliance reply.
        # Some devices do not answer MessageQueryAppliance but still answer init
        # and status queries with the default protocol version 0, so a recorded
        # appliance-query timeout must not block capability probes forever.
        appliance_query_resolved = (
            not self._appliance_query
            or "MessageQueryAppliance" in self._unsupported_protocol
        )
        new_init = (
            [
                cmd
                for cmd in self.build_init_query()
                if cmd.__class__.__name__ not in queued
            ]
            if appliance_query_resolved
            else []
        )
        if new_init:
            for cmd in new_init:
                queued.add(cmd.__class__.__name__)
                cmds.append(cmd)
            return real_cmds, status_appended, True
        if not status_appended:
            real_cmds = self.build_query()
            for cmd in real_cmds:
                queued.add(cmd.__class__.__name__)
                cmds.append(cmd)
            return real_cmds, True, True
        return real_cmds, status_appended, False

    def refresh_status(self, check_protocol: bool = False) -> None:
        """Refresh device status.

        Queries are built and sent in dependency order so each stage's reply
        can inform the next: the appliance query first (it reports the message
        protocol version); once answered, the one-time init/capability probes
        are built (they need that version) and sent; once those are answered,
        the recurring status queries are built (they may need the decoded
        capabilities) and sent. In the checked pass each stage's reply is
        awaited before the next stage is built, via _advance_query_stage(). In
        the unchecked periodic refresh no reply is awaited inline -- the run
        loop parses them -- so any still-armed stage is built and sent back to
        back.
        """
        cmds: list = []
        real_cmds: list = []
        status_appended = False
        error_count = 0
        # Names already queued this refresh, so a stage command left armed after
        # a timeout (recorded in _unsupported_protocol) is not queued again.
        queued: set[str] = set()
        # Stage 1: the appliance query. When its reply will be awaited (checked
        # pass), later stages are appended only after it, so they see the
        # protocol version it reports. Otherwise they are seeded below.
        if self._appliance_query:
            cmds.append(MessageQueryAppliance(self.device_type))
            queued.add("MessageQueryAppliance")
        if check_protocol:
            # Nothing to await first (appliance query already done): seed the
            # next stage now; its reply then drives the remaining stages.
            if not cmds:
                real_cmds, status_appended, _ = self._advance_query_stage(
                    cmds,
                    queued,
                    real_cmds,
                    status_appended,
                )
        else:
            # No inline replies: build every still-armed stage up front.
            advanced = True
            while advanced:
                real_cmds, status_appended, advanced = self._advance_query_stage(
                    cmds,
                    queued,
                    real_cmds,
                    status_appended,
                )
        _LOGGER.debug(
            "[%s] refresh_status seed cmds: %s, check_protocol %s, "
            "device %s, type %s, model %s, subtype %s, device_protocol: %s, "
            "message_protocol %s, unsupported_protocol: %s",
            self._device_id,
            cmds,
            check_protocol,
            self._device_name,
            self._device_type,
            self._model,
            self._subtype,
            self._device_protocol_version,
            self._message_protocol_version,
            self._unsupported_protocol,
        )
        # Index-based so the next stage, built only once the current reply is
        # parsed, can be appended and validated within this same checked pass.
        index = 0
        while index < len(cmds):
            cmd = cmds[index]
            index += 1
            if cmd.__class__.__name__ not in self._unsupported_protocol:
                # set socket QUERY_TIMEOUT for query msg
                # build_send exception should be catch by connect/run
                self.build_send(cmd, query=True)
                # init check_protocol, skip timeout exception
                if check_protocol:
                    try:
                        self._await_query_reply()
                    # only catch TimoutError for check_protocol
                    # unexpected exception in recv/settimeout, catch by main loop
                    except TimeoutError:
                        if cmd in real_cmds:
                            error_count += 1
                        self._unsupported_protocol.append(cmd.__class__.__name__)
                        _LOGGER.debug(
                            "[%s] Does not supports the protocol %s, cmd %s, ignored",
                            self._device_id,
                            cmd.__class__.__name__,
                            cmd,
                        )
                    except ResponseException:
                        # parse msg error
                        if cmd in real_cmds:
                            error_count += 1
                        _LOGGER.debug(
                            "[%s] refresh_status ResponseException %s, cmd %s",
                            self._device_id,
                            cmd.__class__.__name__,
                            cmd,
                        )
                    # The reply (or its absence) may resolve the state the next
                    # stage depends on -- the appliance reply enables the
                    # capability probes, a capability reply the status queries.
                    # Append that stage now so it is sent and validated in this
                    # same checked pass, not deferred to an unchecked refresh
                    # where a timeout could never blacklist it.
                    real_cmds, status_appended, _ = self._advance_query_stage(
                        cmds,
                        queued,
                        real_cmds,
                        status_appended,
                    )
            else:
                _LOGGER.debug(
                    "[%s] refresh_status with cmd: %s, unsupported protocol, SKIP",
                    self._device_id,
                    cmd,
                )
                if cmd in real_cmds:
                    error_count += 1
                # A skipped (already-unsupported) stage command still resolves
                # its stage, so advance to the next one in the checked pass.
                if check_protocol:
                    real_cmds, status_appended, _ = self._advance_query_stage(
                        cmds,
                        queued,
                        real_cmds,
                        status_appended,
                    )
            # All the REAL status queries failed. The appliance query is excluded: it
            # answers even when the device serves no status protocol, so counting it
            # left error_count one short of len(cmds) and the failure was masked --
            # connect() returned True and the device came up available with no data.
            # `real_cmds and` keeps the check vacuously false for a device whose
            # build_query() is empty, which would otherwise raise on 0 == 0.
            if real_cmds and error_count == len(real_cmds):
                _LOGGER.warning(
                    "[%s] all the query cmds failed %s, please report bug",
                    self._device_id,
                    cmds,
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
                                "[%s] process message %s for device %s,"
                                "model %s, subtype %s, "
                                "device protocol %s, message protocol %s",
                                self._device_id,
                                decrypted.hex(),
                                self._device_name,
                                self._model,
                                self._subtype,
                                self._device_protocol_version,
                                self._message_protocol_version,
                            )
                            status = self.process_message(bytes(decrypted))
                            if len(status) > 0:
                                self.update_all(status)
                            else:
                                _LOGGER.debug(
                                    "[%s] Unidentified protocol",
                                    self._device_id,
                                )
                    except Exception:
                        _LOGGER.exception(
                            "[%s] Error in process message %s, "
                            "model %s, subtype %s, "
                            "device protocol %s, message protocol %s",
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

    def build_init_query(self) -> list:
        """Build one-time queries to run once at connect time.

        refresh_status() sends these after the appliance query and before the
        recurring build_query() status queries. A successful appliance reply can
        set the message protocol version before these probes are built; if the
        appliance query is unsupported, probes still run with the default
        protocol version 0. Their own replies are then processed before the
        status queries are built, so a status query can react to the result
        (e.g. the AC B5 capability probes decoded here). A device only needs to
        send these once (their reply never changes); the subclass clears its own
        arming flags when the reply is parsed, and any query that times out is
        recorded in _unsupported_protocol and skipped from then on. The subclass
        may return a follow-up query only after an earlier init reply is parsed
        (e.g. the AC additional-capability probe); refresh_status() keeps
        offering build_init_query() until it is exhausted. The base class has
        none.
        """
        return []

    def reset_init_query(self) -> None:
        """Re-arm the one-time init queries after the socket is closed.

        Called from close_socket() alongside the appliance-query re-arm so a
        reconnected device re-probes from scratch instead of reusing stale
        results. Subclasses that override build_init_query() reset their arming
        flags here. The base class has no init queries, so this is a no-op.
        """

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
                "[%s] send_command failure, %s, cmd_type: %s, cmd_body: %s",
                self._device_id,
                repr(e),
                cmd_type,
                cmd_body.hex(),
            )

    def send_heartbeat(self) -> None:
        """Send heartbeat."""
        msg = PacketBuilder(self._device_id, bytearray([0x00])).finalize(msg_type=0)
        self.send_message(msg)

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
            update(status)

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

    def open(self) -> None:
        """Open thread."""
        if not self._is_run:
            self._is_run = True
            threading.Thread.start(self)

    def close(self) -> None:
        """Close thread."""
        if self._is_run:
            self._is_run = False
            self.close_socket()

    def _should_run(self) -> bool:
        """Return whether the service loop should keep running.

        ``_is_run`` is flipped to False from another thread by ``close()``.
        Reading it through this method (instead of the bare attribute) keeps
        the loop-exit checks reachable to static analysis, which would
        otherwise narrow the attribute to True inside the loop.
        """
        return self._is_run

    def close_socket(self, sock: socket.socket | None = None) -> None:
        """Close socket."""
        with self._socket_lock:
            if sock is None:
                sock = self._socket
            if sock is None or self._socket is sock:
                self._unsupported_protocol = []
                # Re-arm the appliance query too. It is cleared in
                # pre_process_message and was never set back, so a reconnected device
                # would skip protocol detection and re-probe with build_query() alone.
                self._appliance_query = True
                # Re-arm one-time init queries (e.g. AC B5 capability probes) so a
                # reconnected device re-probes instead of reusing stale results.
                self.reset_init_query()
                self._buffer = b""
        if sock is not None:
            try:
                sock.shutdown(socket.SHUT_RDWR)
            except OSError as e:
                # shutdown() raises ENOTCONN if the peer already went away;
                # that's fine, we still close() below.
                _LOGGER.debug(
                    "[%s] Error while shutting down socket: %s",
                    self._device_id,
                    e,
                )
            try:
                sock.close()
                _LOGGER.debug("[%s] Socket closed", self._device_id)
            # catch OSError, AttributeError, ValueError to avoid race condition
            except (OSError, AttributeError, ValueError) as e:
                _LOGGER.debug("[%s] Error while closing socket: %s", self._device_id, e)
            finally:
                with self._socket_lock:
                    # Avoid clearing a socket installed by a concurrent reconnect.
                    if self._socket is sock:
                        self._socket = None

    def set_ip_address(self, ip_address: str) -> None:
        """Set IP address."""
        if self._ip_address != ip_address:
            _LOGGER.debug("[%s] Update IP address to %s", self._device_id, ip_address)
            self._ip_address = ip_address
            self.close_socket()

    def set_mac(self, mac: str | None) -> None:
        """Set MAC."""
        self._mac = mac or None

    def set_refresh_interval(self, refresh_interval: int) -> None:
        """Set refresh interval."""
        self._refresh_interval = refresh_interval

    def _check_refresh(self, now: float) -> None:
        if 0 < self._refresh_interval <= now - self._previous_refresh:
            self.refresh_status()
            self._previous_refresh = now

    def _check_heartbeat(self, now: float) -> None:
        if now - self._previous_heartbeat >= self._heartbeat_interval:
            self.send_heartbeat()
            self._previous_heartbeat = now

    def _connect_loop(self) -> None:
        """Connect loop until device online."""
        # connect loop until online
        connection_retries = 0
        while self._socket is None and self._is_run:
            _LOGGER.debug("[%s] Socket is None, try to connect", self._device_id)
            # Re-check _should_run(): close() may have requested shutdown after
            # the while guard was evaluated, so skip opening a socket / network
            # I/O once teardown is in progress.
            if self._should_run() and self.connect(check_protocol=True) is False:
                connection_retries += 1
                # Sleep time with exponential backoff, maximum 600 seconds
                sleep_time = min(5 * (2 ** (connection_retries - 1)), 600)
                _LOGGER.warning(
                    "[%s] Unable to connect, sleep %s seconds and retry",
                    self._device_id,
                    sleep_time,
                )
                # sleep and reconnect loop until device online
                for _ in range(sleep_time):
                    if not self._should_run():
                        break
                    time.sleep(1)

    def run(self) -> None:
        """Run loop brief description.

        1. first/init connection, self._socket is None
            1.1 connect() device loop, pass, enable device
            1.2 auth for v3 device, MUST pass for v3 device
            1.3 init refresh_status, send query and check supported protocol
                1.3.1 set socket timeout to QUERY_TIMEOUT before send query
                1.3.2 get response and add timeout query cmd to not supported
                1.3.1 parse recv response/status for supported protocol
        2. after socket/device connected, check for heartbeat/refresh_status
        3. job1: check refresh_interval
            3.1 socket/device connection should exist
            3.2 send only supported query and refresh status in main loop recv
            3.3 set socket timeout before socket recv
        4. job2: check heartbeat interval
            4.1 socket/device connection should exist
            4.2 send heartbeat packet to keep alive

        scenario/bug fix:
        1. while True loop should sleep 0.1 second to prevent cpu usage issue
        2. device running and power off become offline, status update
        3. device disconnected and power on, become online, status update
        4. set command call build_send, main loop recv socket msg and refresh

        """
        # service loop
        while self._is_run:
            # connect loop until device online
            self._connect_loop()
            if not self._should_run():
                break
            # socket recv msg timeout counter
            timeout_counter = 0
            start = time.time()
            self._previous_refresh = self._previous_heartbeat = start
            # refresh/recv msg loop after connected
            while True:
                try:
                    if not self._socket:
                        _LOGGER.debug("[%s] Socket is none", self._device_id)
                        raise SocketException  # noqa: TRY301
                    now = time.time()
                    # refresh_status only send supported query msg
                    self._check_refresh(now)
                    self._check_heartbeat(now)
                    # set SOCKET_TIMEOUT before recv socket msg
                    self._socket.settimeout(SOCKET_TIMEOUT)
                    # refresh status after set/query
                    msg = self._socket.recv(512)
                    if len(msg) == 0:
                        raise ConnectionResetError("Connection closed by peer")  # noqa: TRY301
                    # parse msg and update latest status
                    result = self.parse_message(msg)
                    if result == MessageResult.SUCCESS:
                        timeout_counter = 0
                    if result == MessageResult.ERROR:
                        _LOGGER.debug("[%s] Message 'ERROR' received", self._device_id)
                        self.close_socket()
                        break
                except TimeoutError:
                    timeout_counter += 1
                    if timeout_counter >= RESPONSE_TIMEOUT:
                        _LOGGER.debug("[%s] Heartbeat timed out", self._device_id)
                        self.close_socket()
                        break
                except SocketException:  # refresh_status
                    _LOGGER.debug("[%s] Socket Exception", self._device_id)
                    self.close_socket()
                    break
                except NoSupportedProtocol:
                    # Drop the socket and reconnect, as every other exception here
                    # does. Continuing on the same socket could never recover: once
                    # every command is in _unsupported_protocol, refresh_status takes
                    # the SKIP branch for all of them and performs NO socket I/O, so
                    # no socket error can ever be raised to break the loop and the
                    # device stayed stuck until Home Assistant restarted.
                    # close_socket() clears _unsupported_protocol and re-arms
                    # _appliance_query, so the reconnect is a genuine fresh probe --
                    # the same effect as the user power-cycling the device.
                    _LOGGER.debug("[%s] No Supported protocol", self._device_id)
                    self.close_socket()
                    break
                except ConnectionResetError:  # refresh_status -> build_send exception
                    _LOGGER.debug("[%s] Connection reset by peer", self._device_id)
                    self.close_socket()
                    break
                except OSError:  # refresh_status
                    _LOGGER.debug("[%s] OS error", self._device_id)
                    self.close_socket()
                    break
                except Exception as e:
                    _LOGGER.exception(
                        "[%s] Unexpected error",
                        self._device_id,
                        exc_info=e,
                    )
                    self.close_socket()
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
