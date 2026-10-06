"""Midea local CA message."""

from typing import Any

from midealocal.const import DeviceType
from midealocal.message import (
    ListTypes,
    MessageBody,
    MessageCheckSumError,
    MessageLenError,
    MessageRequest,
    MessageResponse,
    MessageType,
)

# Toshiba IoLIFE refrigerators (manufacturer code 0008, e.g. GR-Y540XFS) wrap their
# payload in a "55 AA CC 33" frame instead of the AA frame (see lua/ca/T_0008_CA_*):
# 55 AA CC 33 | length (LE16, total - 4) | 01 CA | 00 x6 | data type (LE16) | body |
# CRC16-CCITT (LE16, poly 0x1021, init 0, over everything before it)
TOSHIBA_FRAME_HEADER = b"\x55\xaa\xcc\x33"
TOSHIBA_FRAME_HEADER_LENGTH = 16
TOSHIBA_FRAME_CRC_LENGTH = 2
TOSHIBA_FRAME_LENGTH_OFFSET = 4
TOSHIBA_FRAME_DATA_TYPE_INDEX = 14
TOSHIBA_FRAME_PREFIX = 0x01
TOSHIBA_DATA_TYPE_QUERY = 0x0003
TOSHIBA_FUNCTION_STATUS = 0x00
TOSHIBA_FUNCTION_AUTO_SAVING = 0x05
TOSHIBA_FUNCTION_DOOR = 0x22
TOSHIBA_STATUS_MIN_BODY_LENGTH = 16
TOSHIBA_STATUS_ERROR_CODE_BODY_LENGTH = 18
TOSHIBA_STATUS_AMBIENT_TEMP_BODY_LENGTH = 20
TOSHIBA_DOOR_MIN_BODY_LENGTH = 2
TOSHIBA_DOOR_ALARM_BODY_LENGTH = 3
TOSHIBA_AUTO_SAVING_MIN_BODY_LENGTH = 3
TOSHIBA_CHILLED_TEMP_THAWING = 0x02
TOSHIBA_NO_ERROR_CODE = b"\xff\xff"
TOSHIBA_SIGNED16_SIGN_BIT = 0x8000
TOSHIBA_SIGNED16_RANGE = 0x10000
TOSHIBA_AMBIENT_TEMP_SCALE = 10

# Value names follow the Toshiba Lua (T_0008_*_CA_*) where it defines them.
TOSHIBA_ICE_MAKER_STATUS = {
    0x00: "running",
    0x01: "water_shortage",
    0x02: "ice_full",
    0x03: "stop",
}
TOSHIBA_ICE_MAKING_MODE = {0x00: "normal", 0x01: "quick", 0x02: "off"}
TOSHIBA_POWER_SAVING_MODE = {
    0x00: "normal",
    0x01: "power_saving_auto",
    0x02: "power_saving_auto_plus",
    0x03: "power_saving",
    0x04: "low_power_cooling",
}
TOSHIBA_UPPER_FREEZER_MODE = {
    0x00: "normal",
    0x01: "quick_freezing",
    0x06: "rough_heat_removal",
    0x07: "cool_cooking",
    0x08: "timer",
    0x09: "frozen_rice",
}
TOSHIBA_CHILLED_ROOM_MODE = {
    0x00: "normal",
    0x01: "power_low_temp",
    0x02: "deli_chilled",
}
# Refrigerator / freezer setting, five steps from weak to strong. 0x80 is reported
# while another mode (low power cooling, or a special chilled mode) controls it.
TOSHIBA_SETTING_LEVEL = {
    0x02: "weak",
    0x07: "slightly_weak",
    0x0C: "medium",
    0x11: "slightly_strong",
    0x16: "strong",
    0x80: "auto",
}
TOSHIBA_AUTO_SAVING_STATUS = {
    0x00: "normal",
    0x01: "eco_auto",
    0x02: "precool",
    0x03: "auto_saving_off",
}

MIN_CA_GENERAL_BODY_LENGTH = 24
MIN_CA_EXCEPTION_BODY_LENGTH = 8
CA_GENERAL_BODY_LENGTH1 = 25
CA_GENERAL_BODY_LENGTH2 = 30
CA_GENERAL_BODY_LENGTH3 = 31
TEMP_POS_LOWER_VALUE = 1
TEMP_POS_UPPER_VALUE = 29
TEMP_NEG_LOWER_VALUE = 49
TEMP_NEG_UPPER_VALUE = 54


class MessageCABase(MessageRequest):
    """CA message base."""

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
        body_type: ListTypes,
    ) -> None:
        """Initialize CA message base."""
        super().__init__(
            device_type=DeviceType.CA,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery(MessageCABase):
    """CA message query."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize CA message query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X00,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([])


def toshiba_crc16(data: bytes | bytearray) -> int:
    """CRC16-CCITT (poly 0x1021, init 0) used by the Toshiba frame."""
    crc = 0
    for byte in data:
        crc ^= byte << 8
        for _ in range(8):
            crc = ((crc << 1) ^ 0x1021) if crc & 0x8000 else crc << 1
            crc &= 0xFFFF
    return crc


def toshiba_frame_header(body_length: int, data_type: int) -> bytearray:
    """Build the 16-byte Toshiba frame header for a body of ``body_length`` bytes."""
    total = TOSHIBA_FRAME_HEADER_LENGTH + body_length + TOSHIBA_FRAME_CRC_LENGTH
    header = bytearray(TOSHIBA_FRAME_HEADER_LENGTH)
    header[0:4] = TOSHIBA_FRAME_HEADER
    header[4:6] = (total - TOSHIBA_FRAME_LENGTH_OFFSET).to_bytes(2, "little")
    header[6] = TOSHIBA_FRAME_PREFIX
    header[7] = DeviceType.CA
    header[14:16] = data_type.to_bytes(2, "little")
    return header


def extract_toshiba_frame(message: bytes | bytearray) -> tuple[int, bytes]:
    """Validate a Toshiba frame and return its (data type, body).

    The decrypted payload may carry AES padding after the frame, so the frame
    length field decides where it ends.
    """
    min_length = TOSHIBA_FRAME_HEADER_LENGTH + 1 + TOSHIBA_FRAME_CRC_LENGTH
    if len(message) < min_length or not bytes(message).startswith(
        TOSHIBA_FRAME_HEADER,
    ):
        raise MessageLenError
    total = int.from_bytes(message[4:6], "little") + TOSHIBA_FRAME_LENGTH_OFFSET
    if total < min_length or total > len(message):
        raise MessageLenError
    frame = bytes(message[:total])
    if toshiba_crc16(frame[:-TOSHIBA_FRAME_CRC_LENGTH]) != int.from_bytes(
        frame[-TOSHIBA_FRAME_CRC_LENGTH:],
        "little",
    ):
        raise MessageCheckSumError
    return (
        frame[TOSHIBA_FRAME_DATA_TYPE_INDEX],
        frame[TOSHIBA_FRAME_HEADER_LENGTH:-TOSHIBA_FRAME_CRC_LENGTH],
    )


class MessageToshibaQuery(MessageCABase):
    """CA status query in the Toshiba IoLIFE frame format.

    Serializes to ``55 aa cc 33 0f 00 01 ca 00 00 00 00 00 00 03 00 00 35 7c``.
    """

    def __init__(self) -> None:
        """Initialize Toshiba CA status query."""
        super().__init__(
            protocol_version=0,
            message_type=MessageType.query,
            body_type=ListTypes.X00,  # function type 0x00: status
        )

    @property
    def header(self) -> bytearray:
        """Toshiba frame header."""
        return toshiba_frame_header(len(self.body), TOSHIBA_DATA_TYPE_QUERY)

    @property
    def _body(self) -> bytearray:
        return bytearray([])

    def serialize(self) -> bytearray:
        """Serialize to a Toshiba frame (header, body, CRC16)."""
        stream = self.header + self.body
        stream.extend(toshiba_crc16(stream).to_bytes(2, "little"))
        return stream


class CAGeneralMessageBody(MessageBody):
    """CA message general body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize CA message general body."""
        super().__init__(body)

        self.code_mode = (self.read_byte(body, 1) & 0x01) > 0
        self.freezing_mode = (self.read_byte(body, 1) & 0x02) > 0
        self.smart_mode = (self.read_byte(body, 1) & 0x04) > 0
        self.energy_saving_mode = (self.read_byte(body, 1) & 0x08) > 0
        self.holiday_mode = (self.read_byte(body, 1) & 0x10) > 0
        self.moisturize_mode = (self.read_byte(body, 1) & 0x20) > 0
        self.preservation_mode = (self.read_byte(body, 1) & 0x40) > 0
        self.acmeFreezing_mode = (self.read_byte(body, 1) & 0x80) > 0
        # refrigerationTemperature
        self.refrigerator_setting_temp = self.read_byte(body, 2) & 0x0F
        # freezingTemperature
        self.freezer_setting_temp = -12 - ((self.read_byte(body, 2) & 0xF0) >> 4)
        # lVariableTemperature
        flex_zone_setting_temp = self.read_byte(body, 3)
        # rVariableTemperature
        right_flex_zone_setting_temp = self.read_byte(body, 4)

        if TEMP_POS_LOWER_VALUE <= flex_zone_setting_temp <= TEMP_POS_UPPER_VALUE:
            self.flex_zone_setting_temp = flex_zone_setting_temp - 19
        elif TEMP_NEG_LOWER_VALUE <= flex_zone_setting_temp <= TEMP_NEG_UPPER_VALUE:
            self.flex_zone_setting_temp = 30 - flex_zone_setting_temp
        else:
            self.flex_zone_setting_temp = 0
        if TEMP_POS_LOWER_VALUE <= right_flex_zone_setting_temp <= TEMP_POS_UPPER_VALUE:
            self.right_flex_zone_setting_temp = right_flex_zone_setting_temp - 19
        elif (
            TEMP_NEG_LOWER_VALUE <= right_flex_zone_setting_temp <= TEMP_NEG_UPPER_VALUE
        ):
            self.right_flex_zone_setting_temp = 30 - right_flex_zone_setting_temp
        else:
            self.right_flex_zone_setting_temp = 0

        self.variable_mode = self.read_byte(body, 5)  # variableModeValue
        # *powerValue 0x00 is on, 0x04/0x08/0x10/20 is off
        self.refrigeration_power = (
            self.read_byte(body, 6) & 0x01
        ) < 1  # refrigerationPowerValue
        self.l_variable_power = (
            self.read_byte(body, 6) & 0x04
        ) < 1  # lVariablePowerValue
        self.r_variable_power = (
            self.read_byte(body, 6) & 0x08
        ) < 1  # rVariablePowerValue
        self.freezing_power = (self.read_byte(body, 6) & 0x10) < 1  # freezingPowerValue
        self.cross_peak_electricity_enter = (
            self.read_byte(body, 6) & 0x20
        )  # crossPeakElectricityEnter
        self.cross_peak_electricity = (
            self.read_byte(body, 6) & 0x40
        ) > 0  # crossPeakElectricity
        self.all_refrigeration_power = (
            self.read_byte(body, 6) & 0x80
        ) > 0  # allRefrigerationPower
        self.remove_dew = self.read_byte(body, 7) & 0x01  # removeDew
        self.humidify = self.read_byte(body, 7) & 0x02  # humidify
        self.unfreeze = self.read_byte(body, 7) & 0x04  # unfreeze
        # 0x08 fahrenheit, 0x00 celsius
        self.temperature_unit = self.read_byte(body, 7) & 0x08  # temperatureUnit
        self.flood_light = self.read_byte(body, 7) & 0x10  # floodlight
        # functionSwitch for icea_bar_function_switch
        self.function_switch = self.read_byte(body, 7) & 0xC0  # functionSwitch
        self.radar_mode = self.read_byte(body, 8) & 0x01  # radarMode
        self.milk_mode = self.read_byte(body, 8) & 0x02  # milkMode
        self.iced_mode = self.read_byte(body, 8) & 0x04  # icedMode
        self.plasma_aseptic_mode = self.read_byte(body, 8) & 0x08  # plasmaAsepticMode
        self.acquire_icea_mode = self.read_byte(body, 8) & 0x10  # acquireIceaMode
        self.brash_icea_mode = self.read_byte(body, 8) & 0x20  # brashIceaMode
        self.acquire_water_mode = self.read_byte(body, 8) & 0x40  # acquireWaterMode
        self.freezing_ice_machine_power = (
            self.read_byte(body, 8) & 0x80
        )  # freezingIceMachinePower
        self.freezing_fahrenheit = self.read_byte(body, 9)  # freezingFahrenheit
        self.refrigeration_fahrenheit = (
            self.read_byte(body, 10) & 0xFC
        )  # refrigerationFahrenheit
        self.leach_expire_day = self.read_byte(body, 11)  # leachExpireDay

        # powerConsumptionLow & powerConsumptionHigh
        self.energy_consumption = (self.read_byte(body, 13) << 8) + self.read_byte(
            body,
            12,
        )

        self.freezing_motor_reset_status = (
            self.read_byte(body, 14) & 0x01
        )  # freezingMotorResetStatus
        self.freezing_motor_deicing_status = (
            self.read_byte(body, 14) & 0x02
        )  # freezingMotorDeicingStatus
        self.freezing_ice_machine_water_status = (
            self.read_byte(body, 14) & 0x04
        )  # freezingIceMachineWaterStatus
        self.freezing_all_ice_status = (
            self.read_byte(body, 14) & 0x08
        )  # freezingAllIceStatus
        self.human_induction = self.read_byte(body, 14) & 0x10  # humanInduction
        self.refrigeration_door_power = (
            self.read_byte(body, 15) & 0x01
        )  # refrigerationDoorPower
        self.freezing_door_power = self.read_byte(body, 15) & 0x02  # freezingDoorPower
        self.variable_door_power = self.read_byte(body, 15) & 0x10  # variableDoorPower
        self.storage_iceHome_door_state = (
            self.read_byte(body, 15) & 0x20
        )  # storageIceHomeDoorState
        self.bar_door_power = self.read_byte(body, 15) & 0x04  # barDoorPower
        self.ice_mouth_power = self.read_byte(body, 15) & 0x08  # iceMouthPower
        self.is_error = self.read_byte(body, 16) & 0x01  # isError
        self.interval_room_humidity_level = (
            self.read_byte(body, 16) & 0xFE
        )  # intervalRoomHumidityLevel

        # refrigerationRealTemperature
        self.refrigerator_actual_temp = (self.read_byte(body, 17) - 100) / 2
        # freezingRealTemperature
        self.freezer_actual_temp = (self.read_byte(body, 18) - 100) / 2
        # lVariableRealTemperature
        self.flex_zone_actual_temp = (self.read_byte(body, 19) - 100) / 2
        # rVariableRealTemperature
        self.right_flex_zone_actual_temp = (self.read_byte(body, 20) - 100) / 2

        # fastColdMinuteLow & fastColdMinuteHigh
        self.fast_cold_minute = (self.read_byte(body, 22) << 8) + self.read_byte(
            body,
            21,
        )
        # fastFreezeMinuteLow & fastFreezeMinuteHigh
        self.fast_freeze_minute = (self.read_byte(body, 24) << 8) + self.read_byte(
            body,
            23,
        )

        if len(body) > CA_GENERAL_BODY_LENGTH1:
            self.microcrystal_fresh = (body[27] & 0x01) > 0
            self.dry_zone = (body[27] & 0x02) > 0
            self.electronic_smell = (body[27] & 0x04) > 0
            self.humidity = body[27] & 0x70
            self.normal_temperature_level = body[28]
            self.function_zone_level = body[29]

        if len(body) > CA_GENERAL_BODY_LENGTH2:
            self.humidity_setting = body[30] & 0x7F
            self.smart_humidity = body[30] & 0x80

        if len(body) > CA_GENERAL_BODY_LENGTH3:
            self.storage_left_door_auto = body[31] & 0x03
            self.storage_right_door_auto = body[31] & 0x0C
            self.freezer_door_auto = body[31] & 0x30
            self.freezer_door_auto_control = body[31] & 0x40
            self.storage_door_auto_control = body[31] & 0x80


class CAExceptionMessageBody(MessageBody):
    """CA message exception body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize CA message exception body."""
        super().__init__(body)

        self.refrigerator_door_overtime = (body[1] & 0x01) > 0
        self.freezer_door_overtime = (body[1] & 0x02) > 0
        self.bar_door_overtime = (body[1] & 0x04) > 0
        self.flex_zone_door_overtime = (body[1] & 0x08) > 0

        self.ice_miachine_full = body[1] & 0x10
        self.refrigeration_sensor_error = body[2] & 0x01
        self.refrigeration_deforsting_sensor_error = body[2] & 0x02
        self.ring_temperature_sensor_error = body[2] & 0x04
        self.flex_zone_sensor_error = body[2] & 0x08
        self.right_flex_zone_sensor_error = body[2] & 0x10
        self.freezing_high_temperature = body[2] & 0x20
        self.freezing_sensor_error = body[2] & 0x40
        self.freezing_defrosting_sensor_error = body[2] & 0x80
        self.ice_electrical_machinery_error = body[3] & 0x01
        self.refrigeration_defrosting_overtime = body[3] & 0x02
        self.freezing_defrosting_overtime = body[3] & 0x04
        self.zeroCrossingCheckError = body[3] & 0x08
        self.eepromReadWriteError = (body[3] & 0x10) > 0
        self.leftFlexzoneSensorError = (body[3] & 0x20) > 0
        self.iceRoomSensorError = (body[3] & 0x40) > 0
        self.mainDisplayCorrespondError = (body[3] & 0x80) > 0
        self.iceMachineTemperatureError = (body[4] & 0x01) > 0
        self.flexzoneDefrostingSensorError = (body[4] & 0x02) > 0
        self.flexzoneDefrostingSensor2Error = (body[4] & 0x04) > 0
        self.yogurtMachineSensorError = (body[4] & 0x08) > 0
        self.iceMachineFrettingSwitchError = (body[4] & 0x10) > 0
        self.iceMachinePipeFilterOvertime = (body[4] & 0x20) > 0
        self.ambientHumiditySensorError = (body[4] & 0x40) > 0
        self.storageHumiditySensorError = (body[4] & 0x80) > 0
        self.radarSensor1Error = (body[5] & 0x01) > 0
        self.radarSensor2Error = (body[5] & 0x02) > 0
        self.radarSensor3Error = (body[5] & 0x04) > 0
        self.radarSensor4Error = (body[5] & 0x08) > 0
        self.radarSensor5Error = (body[5] & 0x10) > 0
        self.functionZoneTemperatureSensorError = (body[5] & 0x20) > 0
        self.normalZoneTemperatureSensorError = (body[5] & 0x40) > 0
        self.humidityControlSensorError = (body[5] & 0x80) > 0
        self.openDoorTooFrequently = (body[6] & 0x01) > 0
        self.storageDoorAloneOpenFrequently = (body[6] & 0x02) > 0
        self.freezingDoorAloneOpenFrequently = (body[6] & 0x04) > 0
        self.barDoorAloneOpenFrequently = (body[6] & 0x08) > 0
        self.snWritingError = (body[6] & 0x20) > 0
        self.storageTemperatureOverheating = (body[6] & 0x40) > 0
        self.storageTemperatureTooLow = (body[6] & 0x80) > 0
        self.storageHeatingWireSensorError = (body[7] & 0x01) > 0
        self.uartReceiverError = (body[7] & 0x02) > 0
        self.crystalliteMainSensorError = (body[7] & 0x08) > 0
        self.crystalliteBase1SensorError = (body[7] & 0x10) > 0
        self.crystalliteBase2SensorError = (body[7] & 0x20) > 0
        self.crystalliteBase3SensorError = (body[7] & 0x40) > 0
        self.crystalliteBase4SensorError = (body[7] & 0x80) > 0


class CANotify00MessageBody(MessageBody):
    """CA message notify00 body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize CA message notify00 body."""
        super().__init__(body)
        self.refrigerator_door = (body[1] & 0x01) > 0
        self.freezer_door = (body[1] & 0x02) > 0
        self.bar_door = (body[1] & 0x04) > 0
        self.flex_zone_door = (body[1] & 0x010) > 0


class CANotify01MessageBody(MessageBody):
    """CA message notify01 body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize CA message notify01 body."""
        super().__init__(body)
        self.refrigerator_setting_temp = body[37]
        self.freezer_setting_temp = -12 - body[38]
        flex_zone_setting_temp = body[39]
        right_flex_zone_setting_temp = body[40]

        if TEMP_POS_LOWER_VALUE <= flex_zone_setting_temp <= TEMP_POS_UPPER_VALUE:
            self.flex_zone_setting_temp = flex_zone_setting_temp - 19
        elif TEMP_NEG_LOWER_VALUE <= flex_zone_setting_temp <= TEMP_NEG_UPPER_VALUE:
            self.flex_zone_setting_temp = 30 - flex_zone_setting_temp
        else:
            self.flex_zone_setting_temp = 0
        if TEMP_POS_LOWER_VALUE <= right_flex_zone_setting_temp <= TEMP_POS_UPPER_VALUE:
            self.right_flex_zone_setting_temp = right_flex_zone_setting_temp - 19
        elif (
            TEMP_NEG_LOWER_VALUE <= right_flex_zone_setting_temp <= TEMP_NEG_UPPER_VALUE
        ):
            self.right_flex_zone_setting_temp = 30 - right_flex_zone_setting_temp
        else:
            self.right_flex_zone_setting_temp = 0


class MessageCAResponse(MessageResponse):
    """CA message response."""

    def __init__(self, message: bytes) -> None:
        """Initialize CA message response."""
        super().__init__(bytearray(message))
        # uptable["dataType"] 0x02 and messageBytes[0] 0x00
        # uptable["dataType"] 0x03 and messageBytes[0] 0x00
        # uptable["dataType"] 0x04 and messageBytes[0] 0x02)
        if (
            (
                self.message_type in [MessageType.query, MessageType.set]
                and self.body_type == ListTypes.X00
            )
            or (
                self.message_type == MessageType.notify1
                and self.body_type == ListTypes.X02
            )
        ) and len(super().body) > MIN_CA_GENERAL_BODY_LENGTH:
            self.set_body(CAGeneralMessageBody(super().body))
        # uptable["dataType"] 0x06 and messageBytes[0] 0x01
        # uptable["dataType"] 0x03 and messageBytes[0] 0x02
        elif (
            (
                self.message_type == MessageType.exception
                and self.body_type == ListTypes.X01
            )
            or (
                self.message_type == MessageType.query
                and self.body_type == ListTypes.X02
            )
        ) and len(super().body) >= MIN_CA_EXCEPTION_BODY_LENGTH:
            self.set_body(CAExceptionMessageBody(super().body))
        # uptable["dataType"] 0x04 and messageBytes[0] 0x00
        elif (
            self.message_type == MessageType.notify1 and self.body_type == ListTypes.X00
        ):
            self.set_body(CANotify00MessageBody(super().body))
        # uptable["dataType"] 0x04 and messageBytes[0] 0x01
        # uptable["dataType"] 0x03 and messageBytes[0] 0x01
        elif (
            self.message_type in [MessageType.query, MessageType.notify1]
            and self.body_type == ListTypes.X01
        ):
            self.set_body(CANotify01MessageBody(super().body))
        self.set_attr()


class MessageToshibaCAResponse:
    """CA response or notification in the Toshiba IoLIFE frame format.

    Only the fields carried by the received function type are set as attributes,
    so ``update_attributes_from_message`` leaves the others untouched.
    """

    def __init__(self, message: bytes) -> None:
        """Parse a Toshiba frame."""
        self.data_type, body = extract_toshiba_frame(message)
        self.function_type = body[0] if body else None
        if (
            self.function_type == TOSHIBA_FUNCTION_STATUS
            and len(body) >= TOSHIBA_STATUS_MIN_BODY_LENGTH
        ):
            self._parse_status(body)
        elif (
            self.function_type == TOSHIBA_FUNCTION_DOOR
            and len(body) >= TOSHIBA_DOOR_MIN_BODY_LENGTH
        ):
            self._parse_door(body)
        elif (
            self.function_type == TOSHIBA_FUNCTION_AUTO_SAVING
            and len(body) >= TOSHIBA_AUTO_SAVING_MIN_BODY_LENGTH
        ):
            # Pushed only; a query with body 0x05 is not answered.
            self.auto_saving_status = TOSHIBA_AUTO_SAVING_STATUS.get(body[2])

    def _parse_status(self, body: bytes) -> None:
        """Parse function type 0x00 (full status)."""
        chilled = body[1]
        self.chilled_room_mode = (
            "thawing"
            if chilled >> 4 == TOSHIBA_CHILLED_TEMP_THAWING
            else TOSHIBA_CHILLED_ROOM_MODE.get(chilled & 0x0F)
        )
        self.power_saving_mode = TOSHIBA_POWER_SAVING_MODE.get(body[3])
        self.upper_freezer_mode = TOSHIBA_UPPER_FREEZER_MODE.get(body[4])
        self.refrigerator_setting_level = TOSHIBA_SETTING_LEVEL.get(body[5])
        self.freezer_setting_level = TOSHIBA_SETTING_LEVEL.get(body[6])
        self.ice_making_mode = TOSHIBA_ICE_MAKING_MODE.get(body[7] & 0x0F)
        self.ice_maker_status = TOSHIBA_ICE_MAKER_STATUS.get(body[7] >> 4)
        self.vegetable_sterilization = bool(body[8] & 0x01)
        self.ice_tray_cleaning = bool(body[8] & 0x02)
        self.moisturizing = bool(body[10] & 0x01)
        self.precooling = bool(body[10] & 0x02)
        self.defrosting = bool(body[10] & 0x04)
        self.refrigerator_door = bool(body[11] & 0x01)
        self.freezer_door = bool(body[11] & 0x02)
        self.ice_door = bool(body[11] & 0x04)
        self.vegetable_door = bool(body[11] & 0x08)
        self.upper_freezer_door = bool(body[11] & 0x10)
        # The Lua reads these two as big-endian, but on the device they are
        # little-endian (checked against a smart plug). The power is the
        # appliance's own estimate and reads ~1.3-1.4x the measured value while
        # the compressor runs; the energy resets at midnight.
        self.estimated_power = int.from_bytes(body[12:14], "little")
        self.daily_energy = int.from_bytes(body[14:16], "little")
        if len(body) >= TOSHIBA_STATUS_ERROR_CODE_BODY_LENGTH:
            raw_error = bytes(body[16:18])
            # 401 while the door-open alarm sounds
            self.error_code = (
                None
                if raw_error == TOSHIBA_NO_ERROR_CODE
                else int.from_bytes(raw_error, "little")
            )
        if len(body) >= TOSHIBA_STATUS_AMBIENT_TEMP_BODY_LENGTH:
            raw_temp = int.from_bytes(body[18:20], "little")
            if raw_temp & TOSHIBA_SIGNED16_SIGN_BIT:
                raw_temp -= TOSHIBA_SIGNED16_RANGE
            self.ambient_temperature = raw_temp / TOSHIBA_AMBIENT_TEMP_SCALE

    def _parse_door(self, body: bytes) -> None:
        """Parse function type 0x22 (door info, pushed on every open/close).

        The bit order differs from the status body.
        """
        doors = body[1]
        self.refrigerator_door = bool(doors & 0x01)
        self.vegetable_door = bool(doors & 0x02)
        self.ice_door = bool(doors & 0x04)
        self.upper_freezer_door = bool(doors & 0x08)
        self.freezer_door = bool(doors & 0x10)
        if len(body) >= TOSHIBA_DOOR_ALARM_BODY_LENGTH:
            # chillingRoomTempThan12 / freezingRoomTempThan10 in the Lua
            self.refrigerator_high_temperature = bool(body[2] & 0x01)
            self.freezer_high_temperature = bool(body[2] & 0x02)

    def __str__(self) -> str:
        """Parse to string."""
        attributes: dict[str, Any] = dict(self.__dict__)
        return str(attributes)
