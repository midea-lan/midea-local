"""Midea local CD message."""

from typing import Any

from midealocal.const import DeviceType
from midealocal.message import (
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)

OLD_BODY_LENGTH = 29


class MessageCDBase(MessageRequest):
    """CD message base."""

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
        body_type: ListTypes,
    ) -> None:
        """Initialize CD message base."""
        super().__init__(
            device_type=DeviceType.CD,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery(MessageCDBase):
    """CD message query."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize CD message query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x01])


class MessageSet(MessageCDBase):
    """CD message set."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize CD message set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X01,
        )
        self.power: bool = False
        self.target_temperature: float = 0
        self.aux_heating: bool = False
        self.fields: dict[Any, Any] = {}
        self.mode: int = 1

    def read_field(self, field: str) -> int:
        """CD message set read field."""
        value = self.fields.get(field, 0)
        return int(value) if value else 0

    @property
    def _body(self) -> bytearray:
        power = 0x01 if self.power else 0x00
        mode = self.mode + 1
        target_temperature = round(self.target_temperature * 2 + 30)
        return bytearray(
            [
                0x01,
                power,
                mode,
                target_temperature,
                self.read_field("trValue"),
                self.read_field("openPTC"),
                self.read_field("ptcTemp"),
                0,  # self.read_field("byte8")
            ],
        )


class CDGeneralMessageBody(MessageBody):
    """CD message general body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize CD message general body."""
        super().__init__(body)
        self.power = (body[2] & 0x01) > 0
        # energyMode
        if (body[2] & 0x02) > 0:
            self.mode = 0x01
        # standardMode
        elif (body[2] & 0x04) > 0:
            self.mode = 0x02
        # compatibilizingMode
        elif (body[2] & 0x08) > 0:
            self.mode = 0x03
        # heatValue
        self.heat = body[2] & 0x20
        # dicaryonHeat
        self.heat = body[2] & 0x30
        # eco
        self.eco = body[2] & 0x40
        # tsValue
        self.target_temperature = body[3]
        # washBoxTemp
        self.current_temperature = body[4]
        # boxTopTemp
        self.top_temperature = body[5]
        # boxBottomTemp
        self.bottom_temperature = body[6]
        # t3Value
        self.condenser_temperature = body[7]
        # t4Value
        self.outdoor_temperature = body[8]
        # compressorTopTemp
        self.compressor_temperature = body[9]
        # tsMaxValue
        self.max_temperature = body[10]
        # tsMinValue
        self.min_temperature = body[11]
        # errorCode
        self.error_code = body[20]
        # bottomElecHeat
        self.bottom_elec_heat = (body[27] & 0x01) > 0
        # topElecHeat
        self.top_elec_heat = (body[27] & 0x02) > 0
        # waterPump
        self.water_pump = (body[27] & 0x04) > 0
        # compressor
        self.compressor_status = (body[27] & 0x08) > 0
        # middleWind
        if (body[27] & 0x10) > 0:
            self.wind = "middle"
        # lowWind
        if (body[27] & 0x40) > 0:
            self.wind = "low"
        # highWind
        if (body[27] & 0x80) > 0:
            self.wind = "high"
        # fourWayValve
        self.four_way = (body[27] & 0x20) > 0
        # elecHeatSupport
        self.elec_heat = (body[28] & 0x01) > 0
        # smartMode
        if (body[28] & 0x20) > 0:
            self.mode = 0x04
        # backwaterEffect
        self.back_water = (body[28] & 0x40) > 0
        # sterilizeEffect
        self.sterilize = (body[28] & 0x80) > 0
        # typeInfo
        self.typeinfo = body[29]
        # hotWater
        self.water_level = body[34] if len(body) > OLD_BODY_LENGTH else None
        # vacationMode
        if len(body) > OLD_BODY_LENGTH and (body[35] & 0x01) > 0:
            self.mode = 0x05
        # smartGrid
        self.smart_grid = (
            ((body[35] & 0x01) > 0) if len(body) > OLD_BODY_LENGTH else False
        )
        # multiTerminal
        self.multi_terminal = (
            ((body[35] & 0x40) > 0) if len(body) > OLD_BODY_LENGTH else False
        )
        # fahrenheitEffect
        self.fahrenheit = (
            ((body[35] & 0x80) > 0) if len(body) > OLD_BODY_LENGTH else False
        )
        # mute_effect
        self.mute_effect = (
            ((body[39] & 0x40) > 0) if len(body) > OLD_BODY_LENGTH else False
        )
        # mute_status
        self.mute_status = (
            ((body[39] & 0x880) > 0) if len(body) > OLD_BODY_LENGTH else False
        )


class CD01MessageBody(MessageBody):
    """CD message set 01 body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize CD message set 01 body."""
        super().__init__(body)
        self.fields = {}
        self.power = (body[2] & 0x01) > 0
        self.mode = body[3]
        self.target_temperature = body[4]
        self.fields["trValue"] = body[5]
        self.fields["openPTC"] = body[5]
        self.fields["ptcTemp"] = body[7]
        self.fields["byte8"] = body[8]


class MessageCDResponse(MessageResponse):
    """CD message response."""

    def __init__(self, message: bytes) -> None:
        """Initialize CD message response."""
        super().__init__(bytearray(message))
        # parse query/notify response message
        if self.message_type in [MessageType.query, MessageType.notify2]:
            self.set_body(CDGeneralMessageBody(super().body))
        # parse set message with body_type 0x01
        elif self.message_type == MessageType.set and self.body_type == 0x01:
            self.set_body(CD01MessageBody(super().body))
        self.set_attr()
