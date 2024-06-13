import logging
import socket
import threading
import time
from enum import IntEnum
from typing import Any

from .backports.enum import StrEnum
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

_LOGGER = logging.getLogger(__name__)


class AuthException(Exception):
    pass


class ResponseException(Exception):
    pass


class RefreshFailed(Exception):
    pass


class DeviceAttributes(StrEnum):
    pass


class ParseMessageResult(IntEnum):
    SUCCESS = 0
    PADDING = 1
    ERROR = 99


class MideaDevice(threading.Thread):
    def __init__(
        self,
        name: str,
        device_id: int,
        device_type: int,
        ip_address: str,
        port: int,
        token: str,
        key: str,
        protocol: int,
        model: str,
        subtype: int,
        attributes: dict,
    ):
        threading.Thread.__init__(self)
        self._attributes = attributes or {}
        self._socket: socket.socket | None = None
        self._ip_address = ip_address
        self._port = port
        self._security = LocalSecurity()
        self._token = bytes.fromhex(token)
        self._key = bytes.fromhex(key)
        self._buffer = b""
        self._device_name = name
        self._device_id = device_id
        self._device_type = device_type
        self._protocol = protocol
        self._model = model
        self._subtype = subtype
        self._protocol_version = 0
        self._updates = [dict]
        self._unsupported_protocol = [dict]
        self._is_run = False
        self._available = True
        self._appliance_query = True
        self._refresh_interval = 30
        self._heartbeat_interval = 10
        self._default_refresh_interval = 30
        self.name = self._device_name

    @property
    def available(self) -> bool:
        return self._available

    @property
    def device_id(self) -> int:
        return self._device_id

    @property
    def device_type(self) -> int:
        return self._device_type

    @property
    def model(self) -> str:
        return self._model

    @property
    def subtype(self) -> int:
        return self._subtype

    @staticmethod
    def fetch_v2_message(msg: bytes) -> tuple[list, bytes]:
        result = []
        while len(msg) > 0:
            factual_msg_len = len(msg)
            if factual_msg_len < 6:
                break
            alleged_msg_len = msg[4] + (msg[5] << 8)
            if factual_msg_len >= alleged_msg_len:
                result.append(msg[:alleged_msg_len])
                msg = msg[alleged_msg_len:]
            else:
                break
        return result, msg

    def connect(self, refresh_status: bool = True) -> bool:
        try:
            self._socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self._socket.settimeout(10)
            _LOGGER.debug(
                "[%s] Connecting to %s:%s",
                self._device_id,
                self._ip_address,
                self._port,
            )
            self._socket.connect((self._ip_address, self._port))
            _LOGGER.debug("[%s] Connected", self._device_id)
            if self._protocol == 3:
                self.authenticate()
            _LOGGER.debug("[%s] Authentication success", self._device_id)
            if refresh_status:
                self.refresh_status(wait_response=True)
            self.enable_device(True)
            return True
        except TimeoutError:
            _LOGGER.debug("[%s] Connection timed out", self._device_id)
        except OSError:
            _LOGGER.debug("[%s] Connection error", self._device_id)
        except AuthException:
            _LOGGER.debug("[%s] Authentication failed", self._device_id)
        except ResponseException:
            _LOGGER.debug("[%s] Unexpected response received", self._device_id)
        except RefreshFailed:
            _LOGGER.debug("[%s] Refresh status is timed out", self._device_id)
        except Exception as e:
            assert e.__traceback__
            _LOGGER.error(
                "[%s] Unknown error: %s, %s, %s",
                self._device_id,
                e.__traceback__.tb_frame.f_globals["__file__"],
                e.__traceback__.tb_lineno,
                repr(e),
            )
        self.enable_device(False)
        return False

    def authenticate(self) -> None:
        request = self._security.encode_8370(self._token, MSGTYPE_HANDSHAKE_REQUEST)
        _LOGGER.debug("[%s] Handshaking", self._device_id)
        assert self._socket
        self._socket.send(request)
        response = self._socket.recv(512)
        if len(response) < 20:
            raise AuthException
        response = response[8:72]
        self._security.tcp_key(response, self._key)

    def send_message(self, data: bytes) -> None:
        if self._protocol == 3:
            self.send_message_v3(data, msg_type=MSGTYPE_ENCRYPTED_REQUEST)
        else:
            self.send_message_v2(data)

    def send_message_v2(self, data: bytes) -> None:
        if self._socket is not None:
            self._socket.send(data)
        else:
            _LOGGER.debug(
                "[%s] Send failure, device disconnected, data: %s",
                self._device_id,
                data.hex(),
            )

    def send_message_v3(
        self,
        data: bytes,
        msg_type: int = MSGTYPE_ENCRYPTED_REQUEST,
    ) -> None:
        data = self._security.encode_8370(data, msg_type)
        self.send_message_v2(data)

    def build_send(self, cmd: MessageRequest) -> None:
        data = cmd.serialize()
        _LOGGER.debug("[%s] Sending: %s", self._device_id, cmd)
        msg = PacketBuilder(self._device_id, data).finalize()
        self.send_message(msg)

    def refresh_status(self, wait_response: bool = False) -> None:
        cmds: list = self.build_query()
        if self._appliance_query:
            cmds = [MessageQueryAppliance(self.device_type)] + cmds
        error_count = 0
        for cmd in cmds:
            if cmd.__class__.__name__ not in self._unsupported_protocol:
                self.build_send(cmd)
                if wait_response:
                    try:
                        while True:
                            assert self._socket
                            msg = self._socket.recv(512)
                            if len(msg) == 0:
                                raise OSError
                            result = self.parse_message(msg)
                            if result == ParseMessageResult.SUCCESS:
                                break
                            elif result == ParseMessageResult.PADDING:
                                continue
                            else:
                                raise ResponseException
                    except TimeoutError:
                        error_count += 1
                        self._unsupported_protocol.append(cmd.__class__.__name__)
                        _LOGGER.debug(
                            "[%s] Does not supports the protocol %s, ignored",
                            self._device_id,
                            cmd.__class__.__name__,
                        )
                    except ResponseException:
                        error_count += 1
            else:
                error_count += 1
        if error_count == len(cmds):
            raise RefreshFailed

    def pre_process_message(self, msg: bytearray) -> bool:
        if msg[9] == MessageType.query_appliance:
            message = MessageApplianceResponse(msg)
            self._appliance_query = False
            _LOGGER.debug("[%s] Received: %s", self._device_id, message)
            self._protocol_version = message.protocol_version
            _LOGGER.debug(
                "[%s] Device protocol version: %s",
                self._device_id,
                self._protocol_version,
            )
            return False
        return True

    def parse_message(self, msg: bytes) -> ParseMessageResult:
        if self._protocol == 3:
            messages, self._buffer = self._security.decode_8370(self._buffer + msg)
        else:
            messages, self._buffer = self.fetch_v2_message(self._buffer + msg)
        if len(messages) == 0:
            return ParseMessageResult.PADDING
        for message in messages:
            if message == b"ERROR":
                return ParseMessageResult.ERROR
            payload_len = message[4] + (message[5] << 8) - 56
            payload_type = message[2] + (message[3] << 8)
            if payload_type in [0x1001, 0x0001]:
                # Heartbeat detected
                pass
            elif len(message) > 56:
                cryptographic = message[40:-16]
                if payload_len % 16 == 0:
                    decrypted = self._security.aes_decrypt(cryptographic)
                    try:
                        cont = True
                        if self._appliance_query:
                            cont = self.pre_process_message(decrypted)
                        if cont:
                            status = self.process_message(decrypted)
                            if len(status) > 0:
                                self.update_all(status)
                            else:
                                _LOGGER.debug(
                                    "[%s] Unidentified protocol",
                                    self._device_id,
                                )

                    except Exception:
                        _LOGGER.error(
                            "[%s] Error in process message, msg = %s",
                            self._device_id,
                            decrypted.hex(),
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
        return ParseMessageResult.SUCCESS

    def build_query(self) -> list:
        raise NotImplementedError

    def process_message(self, msg: bytes) -> dict[str, Any]:
        raise NotImplementedError

    def send_command(self, cmd_type: int, cmd_body: bytearray) -> None:
        cmd = MessageQuestCustom(
            self._device_type,
            self._protocol_version,
            cmd_type,
            cmd_body,
        )
        try:
            self.build_send(cmd)
        except OSError as e:
            _LOGGER.debug(
                "[{%s] Interface send_command failure, %s, "
                "cmd_type: %s, cmd_body: %s",
                self._device_id,
                repr(e),
                cmd_type,
                cmd_body.hex(),
            )

    def send_heartbeat(self) -> None:
        msg = PacketBuilder(self._device_id, bytearray([0x00])).finalize(msg_type=0)
        self.send_message(msg)

    def register_update(self, update: Any) -> None:
        self._updates.append(update)

    def update_all(self, status: dict[str, Any]) -> None:
        _LOGGER.debug("[%s] Status update: %s", self._device_id, status)
        for update in self._updates:
            update(status)

    def enable_device(self, available: bool = True) -> None:
        self._available = available
        status = {"available": available}
        self.update_all(status)

    def open(self) -> None:
        if not self._is_run:
            self._is_run = True
            threading.Thread.start(self)

    def close(self) -> None:
        if self._is_run:
            self._is_run = False
            self.close_socket()

    def close_socket(self) -> None:
        self._unsupported_protocol = []
        self._buffer = b""
        if self._socket:
            self._socket.close()
            self._socket = None

    def set_ip_address(self, ip_address: str) -> None:
        if self._ip_address != ip_address:
            _LOGGER.debug("[%s] Update IP address to %s", self._device_id, ip_address)
            self._ip_address = ip_address
            self.close_socket()

    def set_refresh_interval(self, refresh_interval: int) -> None:
        self._refresh_interval = refresh_interval

    def run(self) -> None:
        while self._is_run:
            while self._socket is None:
                if self.connect(refresh_status=True) is False:
                    self.close_socket()
                    time.sleep(5)
            timeout_counter = 0
            start = time.time()
            previous_refresh = start
            previous_heartbeat = start
            self._socket.settimeout(1)
            while True:
                try:
                    now = time.time()
                    if 0 < self._refresh_interval <= now - previous_refresh:
                        self.refresh_status()
                        previous_refresh = now
                    if now - previous_heartbeat >= self._heartbeat_interval:
                        self.send_heartbeat()
                        previous_heartbeat = now
                    msg = self._socket.recv(512)
                    msg_len = len(msg)
                    if msg_len == 0:
                        raise OSError("Connection closed by peer")
                    result = self.parse_message(msg)
                    if result == ParseMessageResult.ERROR:
                        _LOGGER.debug("[%s] Message 'ERROR' received", self._device_id)
                        self.close_socket()
                        break
                    elif result == ParseMessageResult.SUCCESS:
                        timeout_counter = 0
                except TimeoutError:
                    timeout_counter = timeout_counter + 1
                    if timeout_counter >= 120:
                        _LOGGER.debug("[%s] Heartbeat timed out", self._device_id)
                        self.close_socket()
                        break
                except OSError as e:
                    if self._is_run:
                        _LOGGER.debug("[%s] Socket error %s", self._device_id, repr(e))
                        self.close_socket()
                    break
                except Exception as e:
                    assert e.__traceback__
                    _LOGGER.error(
                        "[%s] Unknown error :%s, %s, %s",
                        self._device_id,
                        e.__traceback__.tb_frame.f_globals["__file__"],
                        e.__traceback__.tb_lineno,
                        repr(e),
                    )

                    self.close_socket()
                    break

    def set_attribute(self, attr: str, value: Any) -> None:
        raise NotImplementedError

    def get_attribute(self, attr: str) -> Any:
        return self._attributes.get(attr)

    def set_customize(self, customize: str) -> None:
        pass

    @property
    def attributes(self) -> dict[str, Any]:
        ret = {}
        for status in self._attributes:
            ret[str(status)] = self._attributes[status]
        return ret
