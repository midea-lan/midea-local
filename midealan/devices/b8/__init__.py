"""Midea local B8 device."""

import logging
from enum import IntEnum, StrEnum
from typing import Any, Unpack

from midealan.const import DeviceType
from midealan.device import MideaDevice, MideaDeviceInitKwargs
from midealan.message import ListTypes

from .message import (
    B8_CLEAN_MODES,
    B8_FAN_LEVELS,
    B8_MOVE_DIRECTIONS,
    B8_SPEAK_LEVELS,
    B8_WATER_LEVELS,
    B8_WORK_STATUS_CONTROLS,
    B8CleanMode,
    B8ControlType,
    B8ErrorCanFixDescription,
    B8ErrorType,
    B8FanLevel,
    B8FunctionType,
    B8MopState,
    B8Moviment,
    B8SpeakLevel,
    B8Speed,
    B8StatusType,
    B8WaterLevel,
    B8WorkMode,
    B8WorkStatus,
    MessageB8Response,
    MessageQuery,
    MessageSet,
    MessageSetCommand,
    MessageSetMovement,
    MessageSetVoiceVolume,
)

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Midea B8 device attributes."""

    work_status = "work_status"
    function_type = "function_type"
    control_type = "control_type"
    move_direction = "move_direction"
    clean_mode = "clean_mode"
    fan_level = "fan_level"
    area = "area"
    water_level = "water_level"
    speak_level = "speak_level"
    zone_id = "zone_id"
    voice_volume = "voice_volume"
    disturb_switch = "disturb_switch"
    disturb_start_time = "disturb_start_time"
    disturb_end_time = "disturb_end_time"
    side_brush_rest_time = "side_brush_rest_time"
    side_brush_life_time = "side_brush_life_time"
    filter_net_rest_time = "filter_net_rest_time"
    filter_net_life_time = "filter_net_life_time"
    roll_brush_rest_time = "roll_brush_rest_time"
    roll_brush_life_time = "roll_brush_life_time"
    mop = "mop"
    carpet_switch = "carpet_switch"
    speed = "speed"
    have_reserve_task = "have_reserve_task"
    battery_percent = "battery_percent"
    work_time = "work_time"
    uv_switch = "uv_switch"
    wifi_switch = "wifi_switch"
    voice_switch = "voice_switch"
    command_source = "command_source"
    error_type = "error_type"
    error_desc = "error_desc"
    device_error = "device_error"
    board_communication_error = "board_communication_error"
    laser_sensor_shelter = "laser_sensor_shelter"
    laser_sensor_error = "laser_sensor_error"


class MideaB8Device(MideaDevice):
    """Midea B8 device."""

    def __init__(
        self,
        *,
        customize: str,  # noqa: ARG002
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Midea B8 device."""
        self._has_reported_status = False
        super().__init__(
            device_type=DeviceType.B8,
            **kwargs,
            attributes={
                DeviceAttributes.work_status: B8WorkStatus.NONE.name.lower(),
                DeviceAttributes.function_type: B8FunctionType.NONE.name.lower(),
                DeviceAttributes.control_type: B8ControlType.NONE.name.lower(),
                DeviceAttributes.move_direction: B8Moviment.NONE.name.lower(),
                DeviceAttributes.clean_mode: B8CleanMode.NONE.name.lower(),
                DeviceAttributes.fan_level: B8FanLevel.OFF.name.lower(),
                DeviceAttributes.area: 0,
                DeviceAttributes.water_level: B8WaterLevel.OFF.name.lower(),
                DeviceAttributes.speak_level: B8SpeakLevel.NONE.name.lower(),
                DeviceAttributes.zone_id: 0,
                DeviceAttributes.voice_volume: 0,
                DeviceAttributes.disturb_switch: False,
                DeviceAttributes.disturb_start_time: "00:00",
                DeviceAttributes.disturb_end_time: "00:00",
                DeviceAttributes.side_brush_rest_time: 0,
                DeviceAttributes.side_brush_life_time: 0,
                DeviceAttributes.filter_net_rest_time: 0,
                DeviceAttributes.filter_net_life_time: 0,
                DeviceAttributes.roll_brush_rest_time: 0,
                DeviceAttributes.roll_brush_life_time: 0,
                DeviceAttributes.mop: B8MopState.OFF.name.lower(),
                DeviceAttributes.carpet_switch: False,
                DeviceAttributes.speed: B8Speed.HIGH.name.lower(),
                DeviceAttributes.have_reserve_task: False,
                DeviceAttributes.battery_percent: 0,
                DeviceAttributes.work_time: 0,
                DeviceAttributes.uv_switch: False,
                DeviceAttributes.wifi_switch: False,
                DeviceAttributes.voice_switch: False,
                DeviceAttributes.command_source: False,
                DeviceAttributes.error_type: B8ErrorType.NO.name.lower(),
                DeviceAttributes.error_desc: B8ErrorCanFixDescription.NO.name.lower(),
                DeviceAttributes.device_error: False,
                DeviceAttributes.board_communication_error: False,
                DeviceAttributes.laser_sensor_shelter: False,
                DeviceAttributes.laser_sensor_error: False,
            },
        )

    @property
    def clean_modes(self) -> list[str]:
        """Return supported clean mode option names."""
        return list(B8_CLEAN_MODES)

    @property
    def fan_levels(self) -> list[str]:
        """Return supported fan level option names."""
        return list(B8_FAN_LEVELS)

    @property
    def water_levels(self) -> list[str]:
        """Return supported water level option names."""
        return list(B8_WATER_LEVELS)

    @property
    def speak_levels(self) -> list[str]:
        """Return supported speak level option names."""
        return list(B8_SPEAK_LEVELS)

    @property
    def move_directions(self) -> list[str]:
        """Return supported movement direction option names."""
        return list(B8_MOVE_DIRECTIONS)

    @property
    def work_status_controls(self) -> list[str]:
        """Return supported work status control option names."""
        return list(B8_WORK_STATUS_CONTROLS)

    def build_query(self) -> list[MessageQuery]:
        """Midea B8 device build query."""
        return [
            MessageQuery(self._message_protocol_version),
            MessageQuery(
                self._message_protocol_version,
                status_type=B8StatusType.X05,
            ),
            MessageQuery(
                self._message_protocol_version,
                body_type=ListTypes.X35,
                status_type=B8StatusType.X01,
            ),
        ]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea B8 device process message."""
        message = MessageB8Response(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        if hasattr(message, str(DeviceAttributes.work_status)):
            self._has_reported_status = True
        new_status = {}
        for status in self._attributes:
            if hasattr(message, str(status)):
                value = getattr(message, str(status))
                if isinstance(value, IntEnum):  # lowercase name for IntEnums
                    value = value.name.lower()
                self._attributes[status] = value
                new_status[str(status)] = self._attributes[status]
        return new_status

    def _gen_set_msg_default_values(self) -> MessageSet:
        msg = MessageSet(self._message_protocol_version)
        if not self._has_reported_status:
            return msg
        msg.clean_mode = B8CleanMode[
            self.attributes[DeviceAttributes.clean_mode].upper()
        ]
        msg.fan_level = B8FanLevel[self.attributes[DeviceAttributes.fan_level].upper()]
        msg.water_level = B8WaterLevel[
            self.attributes[DeviceAttributes.water_level].upper()
        ]
        msg.speak_level = B8SpeakLevel[
            self.attributes[DeviceAttributes.speak_level].upper()
        ]
        msg.zone_id = self.attributes[DeviceAttributes.zone_id]
        return msg

    def set_work_mode(self, work_mode: B8WorkMode) -> None:
        """Midea B8 device set work mode."""
        if work_mode == B8WorkMode.WORK:
            if not self._has_reported_status:
                self.build_send(self._gen_set_msg_default_values())
                return
            self.set_attribute(
                DeviceAttributes.clean_mode,
                self.attributes[DeviceAttributes.clean_mode],
            )
            return

        msg = MessageSetCommand(self._message_protocol_version, work_mode=work_mode)
        self.build_send(msg)

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea B8 device set attribute."""
        if attr == DeviceAttributes.work_status:
            try:
                self.set_work_mode(B8WorkMode[str(value).upper()])
            except KeyError:
                _LOGGER.exception("Wrong value for attribute %s: %s", attr, value)
            return

        msg: MessageSet | MessageSetMovement | MessageSetVoiceVolume | None = None
        try:
            if attr == DeviceAttributes.clean_mode:
                msg = self._gen_set_msg_default_values()
                msg.clean_mode = B8CleanMode[str(value).upper()]
            elif attr == DeviceAttributes.fan_level:
                msg = self._gen_set_msg_default_values()
                msg.fan_level = B8FanLevel[str(value).upper()]
            elif attr == DeviceAttributes.water_level:
                msg = self._gen_set_msg_default_values()
                msg.water_level = B8WaterLevel[str(value).upper()]
            elif attr == DeviceAttributes.speak_level:
                msg = self._gen_set_msg_default_values()
                msg.speak_level = B8SpeakLevel[str(value).upper()]
            elif attr == DeviceAttributes.zone_id:
                msg = self._gen_set_msg_default_values()
                msg.zone_id = int(value)
            elif attr == DeviceAttributes.move_direction:
                msg = MessageSetMovement(
                    self._message_protocol_version,
                    B8Moviment[str(value).upper()],
                )
            elif attr == DeviceAttributes.voice_volume:
                msg = MessageSetVoiceVolume(self._message_protocol_version, int(value))

            if msg is not None:
                self.build_send(msg)
        except (KeyError, TypeError, ValueError, OverflowError):
            _LOGGER.exception("Wrong value for attribute %s: %s", attr, value)


class MideaAppliance(MideaB8Device):
    """Midea B8 appliance."""
