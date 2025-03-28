"""B0 Midea local message."""

from midealocal.const import MAX_BYTE_VALUE, DeviceType
from midealocal.message import (
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)

MIN_MSG_BODY = 15


class MessageB0Base(MessageRequest):
    """B0 message base."""

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
        body_type: ListTypes,
    ) -> None:
        """Initialize B0 message base."""
        super().__init__(
            device_type=DeviceType.B0,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery00(MessageB0Base):
    """B0 message query 00."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize B0 message query 00."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X00,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([])


class MessageQuery01(MessageB0Base):
    """B0 message query 01."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize B0 message query 01."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([])


class MessageQuery31(MessageB0Base):
    """B0 message query 31."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize B0 message query 31."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X31,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([])


class MessageSetWorkMode(MessageB0Base):
    """B0 message set Work Mode."""

    def __init__(
        self,
        protocol_version: int,
        mode: int = MAX_BYTE_VALUE,
        fire_power: int = MAX_BYTE_VALUE,
        work_time: int = 60,  # default is 60 seconds
        temperature: int = 0,
    ) -> None:
        """Initialize C3 message set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X22,
        )
        self.fire_power = fire_power  # default is 0xFF
        self.mode = mode  # default is 0xFF
        self.work_time = work_time
        self.temperature = temperature

    @property
    def _body(self) -> bytearray:
        work_mode = self.mode
        fire_power = self.fire_power
        # get work time value
        work_hours = self.work_time // 3600
        work_minutes = (self.work_time % 3600) // 60
        work_seconds = self.work_time % 60
        # set work time byte
        hours_set = max(0, work_hours)
        minutes_set = max(0, work_minutes)
        seconds_set = max(0, work_seconds)

        temperature_high = (
            (self.temperature // (16**2)) if self.temperature > 0 else 0x00
        )
        temperature_low = (self.temperature % (16**2)) if self.temperature > 0 else 0x00

        return bytearray(
            [
                0x01,
                0x00,
                0x00,
                0x00,
                0x11,  # singleCooking
                0x00,  # pre_heat
                hours_set,
                minutes_set,
                seconds_set,
                work_mode,
                temperature_high,
                temperature_low,
                temperature_high,
                temperature_low,
                fire_power,
                0xFF,  # weight
                0xFF,
                0x00,  # probe_temperature
            ],
        )


class MessageSetNotWorkMode(MessageB0Base):
    """B0 message set Not Work Mode."""

    def __init__(
        self,
        protocol_version: int,
        status: int = MAX_BYTE_VALUE,
        power: int = MAX_BYTE_VALUE,
        child_lock: int = MAX_BYTE_VALUE,
        door: int = MAX_BYTE_VALUE,
    ) -> None:
        """Initialize C3 message set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X22,
        )
        self.status = status
        self.power = power  # 1 is off, 2 is on, default is ff
        self.child_lock = child_lock  # 0 is off, 1 is on, default is ff/255
        self.door = door  # 0 is close, 1 is open, default is ff

    @property
    def _body(self) -> bytearray:
        if self.status < MAX_BYTE_VALUE:
            status = self.status
        elif self.power < MAX_BYTE_VALUE:
            status = self.power  # power and status is same byte
        else:
            status = MAX_BYTE_VALUE
        child_lock = self.child_lock  # default is 0xFF
        door = self.door  # default is 0xFF

        return bytearray(
            [
                0x02,
                status,
                child_lock,
                0xFF,  # furnace_light
                0xFF,  # camera
                door,
            ],
        )


class MessageIncreaseControl(MessageB0Base):
    """B0 message Increase time/temperature Control."""

    def __init__(
        self,
        protocol_version: int,
        time_increase: int = 0,
        temperature_increase: int = 0,
    ) -> None:
        """Initialize C3 message set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X22,
        )
        self.time_increase: int = time_increase
        self.temperature_increase: int = temperature_increase

    @property
    def _body(self) -> bytearray:
        hours_inc = self.time_increase // 3600
        minutes_inc = (self.time_increase % 3600) // 60
        seconds_inc = self.time_increase % 60

        temperature_inc = (
            self.temperature_increase if self.temperature_increase else 0xFF
        )

        return bytearray(
            [
                0x03,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
                hours_inc,
                minutes_inc,
                seconds_inc,
                0xFF,
                0xFF,
                temperature_inc,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
            ],
        )


class MessageSetControl(MessageB0Base):
    """B0 message set work_time/temperature/fire_power SetControl."""

    def __init__(
        self,
        protocol_version: int,
        work_time: int = 0,
        fire_power: int = 255,
        temperature: int = 0,
    ) -> None:
        """Initialize C3 message set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X22,
        )
        self.work_time: int = work_time
        self.fire_power = fire_power
        self.temperature: int = temperature

    @property
    def _body(self) -> bytearray:
        # get hours/minutes/seconds value
        hours_work = self.work_time // 3600
        minutes_work = (self.work_time % 3600) // 60
        seconds_work = self.work_time % 60
        # set byte for hours/minutes/seconds
        hours_set = hours_work if hours_work > 0 else 0xFF
        minutes_set = minutes_work if minutes_work > 0 else 0xFF
        seconds_set = seconds_work if seconds_work > 0 else 0xFF

        temperature_enable = 0x00 if self.temperature else 0xFF
        temperature_set = self.temperature if self.temperature else 0xFF

        fire_power_set = self.fire_power

        return bytearray(
            [
                0x04,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
                hours_set,
                minutes_set,
                seconds_set,
                0xFF,
                temperature_enable,
                temperature_set,
                0xFF,
                0xFF,
                fire_power_set,
                0xFF,  # steam_set
                0xFF,
                0xFF,
            ],
        )


class B0MessageBody(MessageBody):
    """B0 message body [T_0000_B0_6.lua]."""

    def __init__(self, body: bytearray) -> None:
        """Initialize B0 message body."""
        super().__init__(body)
        if len(body) > MIN_MSG_BODY:
            self.door = (body[0] & 0x80) > 0
            self.status = body[0] & 0x7F
            self.mode = body[1]
            self.time_remaining = body[2] * 60 + body[3]
            self.work_stage = body[4]
            self.error_code = body[5]
            self.tips_code = body[6]
            self.maintain = body[7]
            self.fire_power = body[14]


class B0Message01Body(MessageBody):
    """B0 message 01 body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize B0 message 01 body."""
        super().__init__(body)
        if len(body) > MIN_MSG_BODY:
            self.door = (body[32] & 0x02) > 0
            self.status = body[31]
            self.time_remaining = (
                (0 if body[22] == MAX_BYTE_VALUE else body[22]) * 3600
                + (0 if body[23] == MAX_BYTE_VALUE else body[23]) * 60
                + (0 if body[24] == MAX_BYTE_VALUE else body[24])
            )
            self.current_temperature = (body[25] << 8) + (body[26])
            if self.current_temperature == 0:
                self.current_temperature = (body[27] << 8) + body[28]
            self.tank_ejected = (body[32] & 0x04) > 0
            self.water_shortage = (body[32] & 0x08) > 0
            self.water_change_reminder = (body[32] & 0x10) > 0


class B0Message31Body(MessageBody):
    """B0 message 31 body [T_0000_B0_0TG025JG_2021070701.lua]."""

    def __init__(self, body: bytearray) -> None:
        """Initialize B0 message 31 body."""
        super().__init__(body)
        if len(body) > MIN_MSG_BODY:
            self.status = body[1]
            self.cloudmenuid = body[2] * (16 ^ 4) + body[3] * (16 ^ 2) + body[4]
            self.total_step = body[5] / 16
            self.step_num = body[5]
            self.time_remaining = (
                (0 if body[6] == MAX_BYTE_VALUE else body[6]) * 3600
                + (0 if body[7] == MAX_BYTE_VALUE else body[7]) * 60
                + (0 if body[8] == MAX_BYTE_VALUE else body[8])
            )
            self.mode = body[9]
            # current_temperature
            temperature_above = body[11]
            temperature_under = body[13]
            if 0 < temperature_above < MAX_BYTE_VALUE:
                self.current_temperature = temperature_above
            if 0 < temperature_under < MAX_BYTE_VALUE:
                self.current_temperature = temperature_under
            self.fire_power = body[14]
            self.weight = 0 if body[15] == MAX_BYTE_VALUE else body[15] * 10
            self.people_number = 0 if body[15] == MAX_BYTE_VALUE else body[15]
            # lua b26, byte16, bit 0-7
            self.child_lock = self.get_bit(body, 16, 0) > 0
            self.door = self.get_bit(body, 16, 1) > 0
            self.tank_ejected = self.get_bit(body, 16, 2) > 0  # water_box
            self.water_shortage = self.get_bit(body, 16, 3) > 0  # water_state
            self.water_change_reminder = self.get_bit(body, 16, 4) > 0  # change_water
            # preheat
            preheat = self.get_bit(body, 16, 5)
            preheat_end = self.get_bit(body, 16, 6)
            if preheat_end:
                self.pre_heat = "End"
            elif preheat:
                self.pre_heat = "Working"
            else:
                self.pre_heat = "Off"
            self.error_code = self.get_bit(body, 16, 7)


class MessageB0Response(MessageResponse):
    """B0 message response."""

    def __init__(self, message: bytearray) -> None:
        """Initialize B0 message response."""
        super().__init__(message)
        if self.message_type in [
            MessageType.set,
            MessageType.notify1,
            MessageType.query,
        ]:
            if self.body_type == ListTypes.X01:
                self.set_body(B0Message01Body(super().body))
            elif self.body_type == ListTypes.X04:
                pass
            # add for B0 model 0TG025JG, subtype 2, include x31/x41 body
            elif self.body_type in [ListTypes.X31, ListTypes.X41]:
                self.set_body(B0Message31Body(super().body))
            else:
                self.set_body(B0MessageBody(super().body))
        self.set_attr()
