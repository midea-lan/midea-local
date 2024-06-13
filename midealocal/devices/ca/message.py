from midealocal.devices import BodyType
from midealocal.message import (
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)

TEMP_POS_LOWER_VALUE = 1
TEMP_POS_UPPER_VALUE = 29
TEMP_NEG_LOWER_VALUE = 49
TEMP_NEG_UPPER_VALUE = 54


class MessageCABase(MessageRequest):
    def __init__(
        self,
        protocol_version: int,
        message_type: int,
        body_type: int,
    ) -> None:
        super().__init__(
            device_type=0xCA,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery(MessageCABase):
    def __init__(self, protocol_version: int) -> None:
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=0x00,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([])


class CAGeneralMessageBody(MessageBody):
    def __init__(self, body: bytearray) -> None:
        super().__init__(body)
        self.refrigerator_setting_temp = body[2] & 0x0F
        self.freezer_setting_temp = -12 - ((body[2] & 0xF0) >> 4)
        flex_zone_setting_temp = body[3]
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

        self.energy_consumption = (body[13] << 8) + body[12]
        self.refrigerator_actual_temp = (body[17] - 100) / 2
        self.freezer_actual_temp = (body[18] - 100) / 2
        self.flex_zone_actual_temp = (body[19] - 100) / 2
        self.right_flex_zone_actual_temp = (body[20] - 100) / 2


class CAExceptionMessageBody(MessageBody):
    def __init__(self, body: bytearray) -> None:
        super().__init__(body)
        self.refrigerator_door_overtime = (body[1] & 0x01) > 0
        self.freezer_door_overtime = (body[1] & 0x02) > 0
        self.bar_door_overtime = (body[1] & 0x04) > 0
        self.flex_zone_door_overtime = (body[1] & 0x08) > 0


class CANotify00MessageBody(MessageBody):
    def __init__(self, body: bytearray) -> None:
        super().__init__(body)
        self.refrigerator_door = (body[1] & 0x01) > 0
        self.freezer_door = (body[1] & 0x02) > 0
        self.bar_door = (body[1] & 0x04) > 0
        self.flex_zone_door = (body[1] & 0x010) > 0


class CANotify01MessageBody(MessageBody):
    def __init__(self, body: bytearray) -> None:
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
    def __init__(self, message: bytes) -> None:
        super().__init__(bytearray(message))
        if (
            (
                self.message_type in [MessageType.query, MessageType.set]
                and self.body_type == BodyType.X00
            )
            or (
                self.message_type == MessageType.notify1
                and self.body_type == BodyType.X02
            )
        ) and len(super().body) > 20:
            self.set_body(CAGeneralMessageBody(super().body))
        elif (
            self.message_type == MessageType.exception
            and self.body_type == BodyType.X01
        ) or (
            self.message_type == MessageType.query and self.body_type == BodyType.X02
        ):
            self.set_body(CAExceptionMessageBody(super().body))
        elif (
            self.message_type == MessageType.notify1 and self.body_type == BodyType.X00
        ):
            self.set_body(CANotify00MessageBody(super().body))
        elif (
            self.message_type in [MessageType.query, MessageType.notify1]
            and self.body_type == BodyType.X01
        ):
            self.set_body(CANotify01MessageBody(super().body))
        self.set_attr()
