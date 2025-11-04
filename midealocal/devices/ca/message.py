"""Midea local CA message."""

from midealocal.const import DeviceType
from midealocal.message import (
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)

MIN_CA_GENERAL_BODY_LENGTH = 20
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


class CAGeneralMessageBody(MessageBody):
    """CA message general body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize CA message general body."""
        super().__init__(body)

        self.code_mode = (body[1] & 0x01) > 0
        self.freezing_mode = (body[1] & 0x02) > 0
        self.smart_mode = (body[1] & 0x04) > 0
        self.energy_saving_mode = (body[1] & 0x08) > 0
        self.holiday_mode = (body[1] & 0x10) > 0
        self.moisturize_mode = (body[1] & 0x20) > 0
        self.preservation_mode = (body[1] & 0x40) > 0
        self.acmeFreezing_mode = (body[1] & 0x80) > 0
        # refrigerationTemperature
        self.refrigerator_setting_temp = body[2] & 0x0F
        # freezingTemperature
        self.freezer_setting_temp = -12 - ((body[2] & 0xF0) >> 4)
        # lVariableTemperature
        flex_zone_setting_temp = body[3]
        # rVariableTemperature
        right_flex_zone_setting_temp = body[4]

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

        self.variable_mode = body[5]  # variableModeValue
        # *powerValue 0x00 is on, 0x04/0x08/0x10/20 is off
        self.refrigeration_power = (body[6] & 0x01) < 1  # refrigerationPowerValue
        self.l_variable_power = (body[6] & 0x04) < 1  # lVariablePowerValue
        self.r_variable_power = (body[6] & 0x08) < 1  # rVariablePowerValue
        self.freezing_power = (body[6] & 0x10) < 1  # freezingPowerValue
        self.cross_peak_electricity_enter = body[6] & 0x20  # crossPeakElectricityEnter
        self.cross_peak_electricity = (body[6] & 0x40) > 0  # crossPeakElectricity
        self.all_refrigeration_power = (body[6] & 0x80) > 0  # allRefrigerationPower
        self.remove_dew = body[7] & 0x01  # removeDew
        self.humidify = body[7] & 0x02  # humidify
        self.unfreeze = body[7] & 0x04  # unfreeze
        # 0x08 fahrenheit, 0x00 celsius
        self.temperature_unit = body[7] & 0x08  # temperatureUnit
        self.flood_light = body[7] & 0x10  # floodlight
        # functionSwitch for icea_bar_function_switch
        self.function_switch = body[7] & 0xC0  # functionSwitch
        self.radar_mode = body[8] & 0x01  # radarMode
        self.milk_mode = body[8] & 0x02  # milkMode
        self.iced_mode = body[8] & 0x04  # icedMode
        self.plasma_aseptic_mode = body[8] & 0x08  # plasmaAsepticMode
        self.acquire_icea_mode = body[8] & 0x10  # acquireIceaMode
        self.brash_icea_mode = body[8] & 0x20  # brashIceaMode
        self.acquire_water_mode = body[8] & 0x40  # acquireWaterMode
        self.freezing_ice_machine_power = body[8] & 0x80  # freezingIceMachinePower
        self.freezing_fahrenheit = body[9]  # freezingFahrenheit
        self.refrigeration_fahrenheit = body[10] & 0xFC  # refrigerationFahrenheit
        self.leach_expire_day = body[11]  # leachExpireDay

        # powerConsumptionLow & powerConsumptionHigh
        self.energy_consumption = (body[13] << 8) + body[12]

        self.freezing_motor_reset_status = body[14] & 0x01  # freezingMotorResetStatus
        self.freezing_motor_deicing_status = (
            body[14] & 0x02
        )  # freezingMotorDeicingStatus
        self.freezing_ice_machine_water_status = (
            body[14] & 0x04
        )  # freezingIceMachineWaterStatus
        self.freezing_all_ice_status = body[14] & 0x08  # freezingAllIceStatus
        self.human_induction = body[14] & 0x10  # humanInduction
        self.refrigeration_door_power = body[15] & 0x01  # refrigerationDoorPower
        self.freezing_door_power = body[15] & 0x02  # freezingDoorPower
        self.variable_door_power = body[15] & 0x10  # variableDoorPower
        self.storage_iceHome_door_state = body[15] & 0x20  # storageIceHomeDoorState
        self.bar_door_power = body[15] & 0x04  # barDoorPower
        self.ice_mouth_power = body[15] & 0x08  # iceMouthPower
        self.is_error = body[16] & 0x01  # isError
        self.interval_room_humidity_level = body[16] & 0xFE  # intervalRoomHumidityLevel

        # refrigerationRealTemperature
        self.refrigerator_actual_temp = (body[17] - 100) / 2
        # freezingRealTemperature
        self.freezer_actual_temp = (body[18] - 100) / 2
        # lVariableRealTemperature
        self.flex_zone_actual_temp = (body[19] - 100) / 2
        # rVariableRealTemperature
        self.right_flex_zone_actual_temp = (body[20] - 100) / 2

        # fastColdMinuteLow & fastColdMinuteHigh
        self.fast_cold_minute = (body[22] << 8) + body[21]
        # fastFreezeMinuteLow & fastFreezeMinuteHigh
        self.fast_freeze_minute = (body[24] << 8) + body[23]

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
        self.eepromReadWriteError = body[3] & 0x04
        self.leftFlexzoneSensorError = body[3] & 0x04
        self.iceRoomSensorError = body[3] & 0x04
        self.mainDisplayCorrespondError = body[3] & 0x04
        self.flexzoneDefrostingSensorError = body[3] & 0x04
        self.flexzoneDefrostingSensor2Error = body[3] & 0x04
        self.yogurtMachineSensorError = body[3] & 0x04
        self.iceMachineFrettingSwitchError = body[3] & 0x04
        self.iceMachinePipeFilterOvertime = body[3] & 0x04
        self.ambientHumiditySensorError = body[3] & 0x04
        self.storageHumiditySensorError = body[3] & 0x04
        self.radarSensor1Error = body[3] & 0x04
        self.radarSensor2Error = body[3] & 0x04
        self.radarSensor3Error = body[3] & 0x04
        self.radarSensor4Error = body[3] & 0x04
        self.radarSensor5Error = body[3] & 0x04
        self.functionZoneTemperatureSensorError = body[3] & 0x04
        self.normalZoneTemperatureSensorError = body[3] & 0x04
        self.humidityControlSensorError = body[3] & 0x04
        self.openDoorTooFrequently = body[3] & 0x04
        self.storageDoorAloneOpenFrequently = body[3] & 0x04
        self.freezingDoorAloneOpenFrequently = body[3] & 0x04
        self.barDoorAloneOpenFrequently = body[3] & 0x04
        self.storageTemperatureOverheating = body[3] & 0x04
        self.storageTemperatureTooLow = body[3] & 0x04
        self.storageHeatingWireSensorError = body[3] & 0x04
        self.storageTemperatureTooLow = body[3] & 0x04


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
            self.message_type == MessageType.exception
            and self.body_type == ListTypes.X01
        ) or (
            self.message_type == MessageType.query and self.body_type == ListTypes.X02
        ):
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
