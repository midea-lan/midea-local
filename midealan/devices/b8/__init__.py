"""Midea local B8 device."""

import logging
from enum import StrEnum
from typing import Any, ClassVar, Unpack

from midealan.const import DeviceType
from midealan.device import MideaDevice, MideaDeviceInitKwargs
from midealan.message import ListTypes

from .message import (
    B8StatusType,
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

    _status: ClassVar[dict[int, str]] = {
        0x00: "none",
        0x01: "charge",
        0x02: "work",
        0x03: "stop",
        0x04: "charging_on_dock",
        0x05: "reserve_task_finished",
        0x06: "charge_finish",
        0x07: "charging_with_wire",
        0x08: "pause",
        0x09: "updating",
        0x0A: "saving_map",
        0x0B: "error",
        0x0C: "sleep",
        0x0D: "charge_pause",
        0x0E: "relocate",
        0x0F: "electrolysed_water_making",
        0x10: "dust_collecting",
        0x11: "back_dust_collecting",
        0x12: "sleep_in_station",
    }
    _work_mode: ClassVar[dict[int, str]] = {
        0x01: "charge",
        0x02: "work",
        0x03: "stop",
        0x1B: "pause",
    }
    _function_type: ClassVar[dict[int, str]] = {
        0x00: "none",
        0x01: "dust_box_cleaning",
        0x02: "water_tank_cleaning",
    }
    _control_type: ClassVar[dict[int, str]] = {
        0x00: "none",
        0x01: "manual",
        0x02: "auto",
    }
    _move_direction: ClassVar[dict[int, str]] = {
        0x00: "none",
        0x01: "forward",
        0x02: "back",
        0x03: "left",
        0x04: "right",
    }
    _clean_mode: ClassVar[dict[int, str]] = {
        0x00: "none",
        0x01: "random",
        0x02: "arc",
        0x03: "edge",
        0x04: "emphases",
        0x05: "screw",
        0x06: "bed",
        0x07: "wide_screw",
        0x08: "auto",
        0x09: "area",
        0x0A: "zone_index",
        0x0B: "zone_rect",
        0x0C: "path",
    }
    _fan_level: ClassVar[dict[int, str]] = {
        0x00: "off",
        0x01: "soft",
        0x02: "normal",
        0x03: "high",
        0x04: "low",
    }
    _water_level: ClassVar[dict[int, str]] = {
        0x00: "off",
        0x01: "low",
        0x02: "normal",
        0x03: "high",
    }
    _speak_level: ClassVar[dict[int, str]] = {
        0x00: "none",
        0x01: "off",
        0x02: "low",
        0x03: "normal",
        0x04: "high",
    }
    _mop: ClassVar[dict[int, str]] = {
        0x00: "off",
        0x01: "on",
        0x02: "lack_water",
    }
    _speed: ClassVar[dict[int, str]] = {
        0x00: "high",
        0x01: "low",
    }
    _error_type: ClassVar[dict[int, str]] = {
        0x00: "no",
        0x01: "can_fix",
        0x02: "reboot",
        0x03: "warning",
    }
    _error_can_fix_desc: ClassVar[dict[int, str]] = {
        0x00: "no",
        0x01: "fix_dust",
        0x02: "fix_wheel_hang",
        0x03: "fix_wheel_overload",
        0x04: "fix_side_brush_overload",
        0x05: "fix_roll_brush_overload",
        0x06: "fix_dust_engine",
        0x07: "fix_front_panel",
        0x08: "fix_radar_mask",
        0x09: "fix_drop_sensor",
        0x0A: "fix_low_battery",
        0x0B: "fix_abnormal_posture",
        0x0C: "fix_laser_sensor",
        0x0D: "fix_edge_sensor",
        0x0E: "fix_start_in_forbid_area",
        0x0F: "fix_start_in_strong_magnetic",
        0x10: "fix_laser_sensor_blocked",
    }
    _error_reboot_desc: ClassVar[dict[int, str]] = {
        0x00: "no",
        0x01: "reboot_laser_comm_fail",
        0x02: "reboot_robot_comm_fail",
        0x03: "reboot_inner_fail",
    }
    _error_warning_desc: ClassVar[dict[int, str]] = {
        0x00: "no",
        0x01: "warn_location_fail",
        0x02: "warn_low_battery",
        0x03: "warn_full_dust",
        0x04: "warn_low_water",
    }
    _attribute_dicts: ClassVar[dict[DeviceAttributes, str]] = {
        DeviceAttributes.work_status: "_status",
        DeviceAttributes.function_type: "_function_type",
        DeviceAttributes.control_type: "_control_type",
        DeviceAttributes.move_direction: "_move_direction",
        DeviceAttributes.clean_mode: "_clean_mode",
        DeviceAttributes.fan_level: "_fan_level",
        DeviceAttributes.water_level: "_water_level",
        DeviceAttributes.speak_level: "_speak_level",
        DeviceAttributes.mop: "_mop",
        DeviceAttributes.speed: "_speed",
        DeviceAttributes.error_type: "_error_type",
    }
    _attribute_fallbacks: ClassVar[dict[str, int]] = {
        "_mop": 0x02,
    }
    _set_control_attributes: ClassVar[dict[DeviceAttributes, tuple[str, str]]] = {
        DeviceAttributes.clean_mode: ("_clean_mode", "clean_mode"),
        DeviceAttributes.fan_level: ("_fan_level", "fan_level"),
        DeviceAttributes.water_level: ("_water_level", "water_level"),
        DeviceAttributes.speak_level: ("_speak_level", "speak_level"),
    }

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
                DeviceAttributes.work_status: self._status[0x00],
                DeviceAttributes.function_type: self._function_type[0x00],
                DeviceAttributes.control_type: self._control_type[0x00],
                DeviceAttributes.move_direction: self._move_direction[0x00],
                DeviceAttributes.clean_mode: self._clean_mode[0x00],
                DeviceAttributes.fan_level: self._fan_level[0x00],
                DeviceAttributes.area: 0,
                DeviceAttributes.water_level: self._water_level[0x00],
                DeviceAttributes.speak_level: self._speak_level[0x00],
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
                DeviceAttributes.mop: self._mop[0x00],
                DeviceAttributes.carpet_switch: False,
                DeviceAttributes.speed: self._speed[0x00],
                DeviceAttributes.have_reserve_task: False,
                DeviceAttributes.battery_percent: 0,
                DeviceAttributes.work_time: 0,
                DeviceAttributes.uv_switch: False,
                DeviceAttributes.wifi_switch: False,
                DeviceAttributes.voice_switch: False,
                DeviceAttributes.command_source: False,
                DeviceAttributes.error_type: self._error_type[0x00],
                DeviceAttributes.error_desc: self._error_can_fix_desc[0x00],
                DeviceAttributes.device_error: False,
                DeviceAttributes.board_communication_error: False,
                DeviceAttributes.laser_sensor_shelter: False,
                DeviceAttributes.laser_sensor_error: False,
            },
        )

    @property
    def clean_modes(self) -> list[str]:
        """Return supported clean mode option names."""
        return list(self._clean_mode.values())

    @property
    def fan_levels(self) -> list[str]:
        """Return supported fan level option names."""
        return list(self._fan_level.values())

    @property
    def water_levels(self) -> list[str]:
        """Return supported water level option names."""
        return list(self._water_level.values())

    @property
    def speak_levels(self) -> list[str]:
        """Return supported speak level option names."""
        return list(self._speak_level.values())

    @property
    def move_directions(self) -> list[str]:
        """Return supported movement direction option names."""
        return list(self._move_direction.values())

    @property
    def work_status_controls(self) -> list[str]:
        """Return supported work status control option names."""
        return list(self._work_mode.values())

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
                value = self._convert_message_value(status, value, message)
                self._attributes[status] = value
                new_status[str(status)] = self._attributes[status]
        return new_status

    def _get_error_desc(self, error_type: int, error_desc: int) -> str:
        default_error_desc = self._error_can_fix_desc[0x00]
        if error_type == self.get_dict_key_by_value("_error_type", "can_fix"):
            return self._error_can_fix_desc.get(error_desc, default_error_desc)
        if error_type == self.get_dict_key_by_value("_error_type", "reboot"):
            return self._error_reboot_desc.get(error_desc, default_error_desc)
        if error_type == self.get_dict_key_by_value("_error_type", "warning"):
            return self._error_warning_desc.get(
                error_desc,
                default_error_desc,
            )
        return default_error_desc

    def _convert_message_value(
        self,
        status: DeviceAttributes,
        value: Any,  # noqa: ANN401
        message: MessageB8Response,
    ) -> Any:  # noqa: ANN401
        if status == DeviceAttributes.error_desc:
            return self._get_error_desc(getattr(message, "error_type", 0x00), value)
        if status in self._attribute_dicts:
            dict_name = self._attribute_dicts[status]
            target_dict: dict[int, str] = getattr(self, dict_name)
            fallback = self._attribute_fallbacks.get(dict_name, 0x00)
            return target_dict.get(value, target_dict[fallback])
        return value

    def _gen_set_msg_default_values(self) -> MessageSet:
        msg = MessageSet(self._message_protocol_version)
        if not self._has_reported_status:
            return msg
        msg.clean_mode = self.get_dict_key_by_value(
            "_clean_mode",
            self.attributes[DeviceAttributes.clean_mode],
        )
        msg.fan_level = self.get_dict_key_by_value(
            "_fan_level",
            self.attributes[DeviceAttributes.fan_level],
        )
        msg.water_level = self.get_dict_key_by_value(
            "_water_level",
            self.attributes[DeviceAttributes.water_level],
        )
        msg.speak_level = self.get_dict_key_by_value(
            "_speak_level",
            self.attributes[DeviceAttributes.speak_level],
        )
        msg.zone_id = self.attributes[DeviceAttributes.zone_id]
        return msg

    def set_work_mode(self, work_mode: int) -> None:
        """Midea B8 device set work mode."""
        if work_mode == self.get_dict_key_by_value("_work_mode", "work"):
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
            work_mode = self.get_dict_key_by_value("_work_mode", str(value))
            if work_mode is None:
                _LOGGER.error("Wrong value for attribute %s: %s", attr, value)
                return
            self.set_work_mode(work_mode)
            return

        msg: MessageSet | MessageSetMovement | MessageSetVoiceVolume | None = None
        try:
            if attr in self._set_control_attributes:
                dict_name, msg_attr = self._set_control_attributes[
                    DeviceAttributes(attr)
                ]
                msg = self._gen_set_msg_default_values()
                control_value = self.get_dict_key_by_value(dict_name, str(value))
                if control_value is None:
                    _LOGGER.error("Wrong value for attribute %s: %s", attr, value)
                    msg = None
                else:
                    setattr(msg, msg_attr, control_value)
            elif attr == DeviceAttributes.zone_id:
                msg = self._gen_set_msg_default_values()
                msg.zone_id = int(value)
            elif attr == DeviceAttributes.move_direction:
                move_direction = self.get_dict_key_by_value(
                    "_move_direction",
                    str(value),
                )
                if move_direction is None:
                    _LOGGER.error("Wrong value for attribute %s: %s", attr, value)
                    return
                msg = MessageSetMovement(
                    self._message_protocol_version,
                    move_direction,
                )
            elif attr == DeviceAttributes.voice_volume:
                msg = MessageSetVoiceVolume(self._message_protocol_version, int(value))

            if msg is not None:
                self.build_send(msg)
        except (KeyError, TypeError, ValueError, OverflowError):
            _LOGGER.exception("Wrong value for attribute %s: %s", attr, value)


class MideaAppliance(MideaB8Device):
    """Midea B8 appliance."""
