"""Midea local E2 message."""

from midealocal.const import DeviceType
from midealocal.message import (
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)

HEATING_POWER_BYTE = 34
PROTECTION_BYTE = 22
WATER_CONSUMPTION_BYTE = 25


class MessageE2Base(MessageRequest):
    """E2 message base."""

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
        body_type: ListTypes,
    ) -> None:
        """Initialize E2 message base."""
        super().__init__(
            device_type=DeviceType.E2,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery(MessageE2Base):
    """E2 message query."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize E2 message query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x01])


class MessagePower(MessageE2Base):
    """E2 message power."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize E2 message power."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X02,
        )
        self.power = False

    @property
    def _body(self) -> bytearray:
        if self.power:
            self.body_type = ListTypes.X01
        else:
            self.body_type = ListTypes.X02
        return bytearray([0x01])


class MessageNewProtocolSet(MessageE2Base):
    """E2 message new protocol set(T_0000_E2_24.lua:flag == false: else)."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize E2 message new protocol set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X14,
        )
        self.target_temperature: float | None = None
        self.variable_heating: bool | None = None
        self.sterilization: bool | None = None
        self.whole_tank_heating: bool | None = None
        self.protect: bool | None = None
        self.sleep: bool | None = None
        self.big_water: bool | None = None
        self.auto_off: bool | None = None
        self.safe: bool | None = None
        self.screen_off: bool | None = None
        self.wash_temperature: float | None = None
        self.always_fell: bool | None = None
        self.smart_sterilize: bool | None = None
        self.uv_sterilize: bool | None = None

    @property
    def _body(self) -> bytearray:
        byte12 = 0x00
        byte13 = 0x00
        if self.target_temperature is not None:
            byte12 = 0x07
            byte13 = int(self.target_temperature) & 0xFF
        elif self.whole_tank_heating is not None:
            byte12 = 0x04
            # byte2 0x02/whole_heat 0x01/half_heat
            byte13 = 0x02 if self.whole_tank_heating else 0x01
        # frequency_hot
        elif self.variable_heating is not None:
            byte12 = 0x10
            byte13 = 0x01 if self.variable_heating else 0x00
        # sterilization
        elif self.sterilization is not None:
            byte12 = 0x0D
            byte13 = 0x01 if self.sterilization else 0x00
        # protect
        elif self.protect is not None:
            byte12 = 0x05
            byte13 = 0x01 if self.protect else 0x00
        # sleep
        elif self.sleep is not None:
            byte12 = 0x0E
            byte13 = 0x01 if self.sleep else 0x00
        # big_water
        elif self.big_water is not None:
            byte12 = 0x11
            byte13 = 0x01 if self.big_water else 0x00
        # auto_off
        elif self.auto_off is not None:
            byte12 = 0x14
            byte13 = 0x01 if self.auto_off else 0x00
        # safe
        elif self.safe is not None:
            byte12 = 0x06
            byte13 = 0x01 if self.safe else 0x00
        # screen_off
        elif self.screen_off is not None:
            byte12 = 0x0F
            byte13 = 0x01 if self.screen_off else 0x00
        # wash_temperature
        elif self.wash_temperature is not None:
            byte12 = 0x16
            byte13 = int(self.wash_temperature) & 0xFF
        # smart_sterilize
        elif self.smart_sterilize is not None:
            byte12 = 0x1B
            byte13 = 0x01 if self.smart_sterilize else 0x00
        # uv_sterilize
        elif self.uv_sterilize is not None:
            byte12 = 0x1D
            byte13 = 0x01 if self.uv_sterilize else 0x00
        return bytearray([byte12, byte13])


class MessageSet(MessageE2Base):
    """E2 message set(T_0000_E2_24.lua: else)."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize E2 message set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X04,
        )
        self.target_temperature: float = 0.0
        self.variable_heating = False
        self.whole_tank_heating = False
        self.protection = False

    @property
    def _body(self) -> bytearray:
        # Byte 4 whole_tank_heating, protection
        protection = 0x04 if self.protection else 0x00
        whole_tank_heating = 0x02 if self.whole_tank_heating else 0x01
        # Byte 5 target_temperature
        target_temperature = int(self.target_temperature) & 0xFF
        # Byte 9 variable_heating
        variable_heating = 0x10 if self.variable_heating else 0x00
        return bytearray(
            [
                0x01,  # byte12
                0x00,  # byte13
                0x80,  # byte14
                whole_tank_heating | protection,  # byte15
                target_temperature,  # byte16
                0x00,  # byte17
                0x00,  # byte18
                0x00,  # byte19
                variable_heating,  # byte20
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
            ],
        )


class E2GeneralMessageBody(MessageBody):
    """E2 message general body(T_0000_E2_24.lua)."""

    def __init__(self, body: bytearray) -> None:
        """Initialize E2 message general body."""
        super().__init__(body)
        self.power = (body[2] & 0x01) > 0
        self.fast_hot_power = (body[2] & 0x02) > 0  # fast_hot_power
        self.heating = (body[2] & 0x04) > 0  # hot_power
        self.keep_warm = (body[2] & 0x08) > 0  # warm_power
        self.water_flow = (body[2] & 0x10) > 0  # water_flow
        self.sterilization = (body[2] & 0x40) > 0  # sterilization
        self.variable_heating = (body[2] & 0x80) > 0  # frequency_hot
        self.current_temperature = float(body[4])
        self.heat_water_level = body[5]  # heat_water_level
        self.eplus = (body[7] & 0x01) > 0  # eplus
        self.fast_wash = (body[7] & 0x02) > 0  # fast_wash
        self.half_heat = (body[7] & 0x04) > 0  # half_heat
        self.whole_tank_heating = (body[7] & 0x08) > 0  # whole_heat
        self.summer = (body[7] & 0x10) > 0
        self.winter = (body[7] & 0x20) > 0
        self.efficient = (body[7] & 0x40) > 0
        self.night = (body[7] & 0x80) > 0
        self.screen_off = (body[8] & 0x08) > 0
        self.sleep = (body[8] & 0x10) > 0
        self.cloud = (body[8] & 0x20) > 0
        self.appoint_wash = (body[8] & 0x40) > 0
        self.now_wash = (body[8] & 0x80) > 0
        # end_time_hour/end_time_minute
        self.heating_time_remaining = body[9] * 60 + body[10]
        self.target_temperature = float(body[11])
        self.smart_sterilize = (body[12] & 0x20) > 0
        self.sterilize_high_temp = (body[12] & 0x40) > 0
        self.uv_sterilize = (body[12] & 0x80) > 0
        self.discharge_status = body[13]
        self.top_temp = body[14]
        self.bottom_heat = (body[15] & 0x01) > 0
        self.top_heat = (body[15] & 0x02) > 0
        self.water_cyclic = (body[15] & 0x80) > 0
        self.water_system = body[16]
        # in_temperature
        self.in_temperature = float(body[18]) if len(body) > PROTECTION_BYTE else None
        # protect
        self.protection = (
            ((body[22] & 0x02) > 0) if len(body) > PROTECTION_BYTE else False
        )
        # waterday_lowbyte/waterday_highbyte
        if len(body) > WATER_CONSUMPTION_BYTE:
            self.day_water_consumption = body[20] + (body[21] << 8)
        # passwater_lowbyte/passwater_highbyte
        if len(body) > WATER_CONSUMPTION_BYTE:
            self.water_consumption = body[24] + (body[25] << 8)
        # volume
        if len(body) > HEATING_POWER_BYTE:
            self.volume = body[27]
        # rate
        if len(body) > HEATING_POWER_BYTE:
            self.rate = body[28] * 100
        # cur_rate
        if len(body) > HEATING_POWER_BYTE:
            self.heating_power = body[34] * 100


class MessageE2Response(MessageResponse):
    """E2 message response."""

    def __init__(self, message: bytes) -> None:
        """Initialize E2 message response."""
        super().__init__(bytearray(message))
        if (
            self.message_type in [MessageType.query, MessageType.notify1]
            and self.body_type == 0x01
        ) or (
            self.message_type == MessageType.set
            and self.body_type in [0x01, 0x02, 0x04, 0x14]
        ):
            self.set_body(E2GeneralMessageBody(super().body))
        self.set_attr()
