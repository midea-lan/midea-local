import logging
from abc import ABC
from enum import IntEnum
from typing import SupportsIndex, cast

_LOGGER = logging.getLogger(__name__)


class MessageLenError(Exception):
    pass


class MessageBodyError(Exception):
    pass


class MessageCheckSumError(Exception):
    pass


class MessageType(IntEnum):
    set = (0x02,)
    query = (0x03,)
    notify1 = (0x04,)
    notify2 = (0x05,)
    exception = (0x06,)
    exception2 = (0x0A,)
    query_appliance = 0xA0


NONE_VALUE = 0x00


class MessageBase(ABC):
    HEADER_LENGTH = 10

    def __init__(self) -> None:
        self._device_type = NONE_VALUE
        self._message_type = NONE_VALUE
        self._body_type = NONE_VALUE
        self._protocol_version = NONE_VALUE

    @staticmethod
    def checksum(data: bytes) -> SupportsIndex:
        return cast(SupportsIndex, (~sum(data) + 1) & 0xFF)

    @property
    def header(self) -> bytearray:
        raise NotImplementedError

    @property
    def body(self) -> bytearray:
        raise NotImplementedError

    @property
    def message_type(self) -> int:
        return self._message_type

    @message_type.setter
    def message_type(self, value: int) -> None:
        self._message_type = value

    @property
    def device_type(self) -> int:
        return self._device_type

    @device_type.setter
    def device_type(self, value: int) -> None:
        self._device_type = value

    @property
    def body_type(self) -> int:
        return self._body_type

    @body_type.setter
    def body_type(self, value: int) -> None:
        self._body_type = value

    @property
    def protocol_version(self) -> int:
        return self._protocol_version

    @protocol_version.setter
    def protocol_version(self, protocol_version: int) -> None:
        self._protocol_version = protocol_version

    def __str__(self) -> str:
        output = {
            "header": self.header.hex(),
            "body": self.body.hex(),
            "message type": "%02x" % self._message_type,
            "body type": (
                ("%02x" % self._body_type) if self._body_type != NONE_VALUE else "None"
            ),
        }
        return str(output)


class MessageRequest(MessageBase):
    def __init__(
        self,
        device_type: int,
        protocol_version: int,
        message_type: int,
        body_type: int,
    ) -> None:
        super().__init__()
        self.device_type = device_type
        self.protocol_version = protocol_version
        self.message_type = message_type
        self.body_type = body_type

    @property
    def header(self) -> bytearray:
        length = self.HEADER_LENGTH + len(self.body)
        return bytearray(
            [
                # flag
                0xAA,
                # length
                length,
                # device type
                self.device_type,
                # frame checksum
                0x00,  # self._device_type ^ length,
                # unused
                0x00,
                0x00,
                # frame ID
                0x00,
                # frame protocol version
                0x00,
                # device protocol version
                self.protocol_version,
                # frame type
                self.message_type,
            ],
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError

    @property
    def body(self) -> bytearray:
        body = bytearray([])
        if self.body_type != NONE_VALUE:
            body.append(self.body_type)
        if self._body is not None:
            body.extend(self._body)
        return body

    def serialize(self) -> bytearray:
        stream = self.header + self.body
        stream.append(MessageBase.checksum(stream[1:]))
        return stream


class MessageQuestCustom(MessageRequest):
    def __init__(
        self,
        device_type: int,
        protocol_version: int,
        cmd_type: int,
        cmd_body: bytearray,
    ) -> None:
        super().__init__(
            device_type=device_type,
            protocol_version=protocol_version,
            message_type=cmd_type,
            body_type=NONE_VALUE,
        )
        self._cmd_body = cmd_body

    @property
    def _body(self) -> bytearray:
        return bytearray([])

    @property
    def body(self) -> bytearray:
        return self._cmd_body


class MessageQueryAppliance(MessageRequest):
    def __init__(self, device_type: int) -> None:
        super().__init__(
            device_type=device_type,
            protocol_version=0,
            message_type=MessageType.query_appliance,
            body_type=NONE_VALUE,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([])

    @property
    def body(self) -> bytearray:
        return bytearray([0x00] * 19)


class MessageBody:
    def __init__(self, body: bytearray) -> None:
        self._data = body

    @property
    def data(self) -> bytearray:
        return self._data

    @property
    def body_type(self) -> int:
        return self._data[0]

    @staticmethod
    def read_byte(body: bytearray, byte: int, default_value: int = 0) -> int:
        return body[byte] if len(body) > byte else default_value


class NewProtocolMessageBody(MessageBody):
    def __init__(self, body: bytearray, bt: int) -> None:
        super().__init__(body)
        if bt == 0xB5:
            self._pack_len = 4
        else:
            self._pack_len = 5

    @staticmethod
    def pack(param: int, value: bytearray, pack_len: int = 4) -> bytearray:
        length = len(value)
        if pack_len == 4:
            stream = bytearray([param & 0xFF, param >> 8, length]) + value
        else:
            stream = bytearray([param & 0xFF, param >> 8, 0x00, length]) + value
        return stream

    def parse(self) -> dict[int, bytearray]:
        result = {}
        try:
            pos = 2
            for _ in range(self.data[1]):
                param = self.data[pos] + (self.data[pos + 1] << 8)
                if self._pack_len == 5:
                    pos += 1
                length = self.data[pos + 2]
                if length > 0:
                    value = self.data[pos + 3 : pos + 3 + length]
                    result[param] = value
                pos += 3 + length
        except IndexError:
            # Some device used non-standard new-protocol(美的乐享三代中央空调?)
            _LOGGER.debug("Non-standard new-protocol %s", self.data.hex())
        return result


class MessageResponse(MessageBase):
    def __init__(self, message: bytearray) -> None:
        super().__init__()
        if message is None or len(message) < self.HEADER_LENGTH + 1:
            raise MessageLenError
        self._header = message[: self.HEADER_LENGTH]
        self.protocol_version = self._header[-2]
        self.message_type = self._header[-1]
        self.device_type = self._header[2]
        body = message[self.HEADER_LENGTH : -1]
        self._body = MessageBody(body)
        self.body_type = self._body.body_type

    @property
    def header(self) -> bytearray:
        return self._header

    @property
    def body(self) -> bytearray:
        return self._body.data

    def set_body(self, body: MessageBody) -> None:
        self._body = body

    def set_attr(self) -> None:
        for key in vars(self._body).keys():
            if key != "data":
                value = getattr(self._body, key, None)
                setattr(self, key, value)


class MessageApplianceResponse(MessageResponse):
    def __init__(self, message: bytearray) -> None:
        super().__init__(message)
