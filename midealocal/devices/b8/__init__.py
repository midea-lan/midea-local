"""Midea local B8 device."""

import logging
from enum import IntEnum, StrEnum
from typing import Any, Unpack

from midealocal.const import DeviceType
from midealocal.device import MideaDevice, MideaDeviceInitKwargs

from .message import (
    B8CleanMode,
    B8ControlType,
    B8ErrorCanFixDescription,
    B8ErrorType,
    B8FanLevel,
    B8FunctionType,
    B8MopState,
    B8Moviment,
    B8Speed,
    B8WaterLevel,
    B8WorkMode,
    B8WorkStatus,
    MessageB8Response,
    MessageQuery,
    MessageSet,
    MessageSetCommand,
)
from .message_v2 import (
    B8V2ConfigType,
    B8V2FanLevel,
    B8V2TaskControl,
    B8V2WaterLevel,
    MessageB8V2Response,
    MessageV2Query,
    MessageV2SetCommand,
    MessageV2SetConfig,
)

_LOGGER = logging.getLogger(__name__)

# Integer ``subType`` (Midea cloud API) of B8 models that speak the
# second-generation protocol (cloud plugin SN8 "750004CE"); see message_v2.py.
# Empty until a real device's subType is known -- it cannot be derived from the
# plugin, so v2 support stays inert until an entry is added here.
_V2_SUBTYPES: frozenset[int] = frozenset()

# v1 start/stop/charge/pause command -> v2 task-control code.
_WORK_MODE_TO_V2_TASK: dict[B8WorkMode, B8V2TaskControl] = {
    B8WorkMode.CHARGE: B8V2TaskControl.CHARGE,
    B8WorkMode.WORK: B8V2TaskControl.WORK,
    B8WorkMode.STOP: B8V2TaskControl.STOP,
    B8WorkMode.PAUSE: B8V2TaskControl.PAUSE,
}


def _translate_int_enum(v: Any) -> Any:  # noqa: ANN401
    return v.name.lower() if isinstance(v, IntEnum) else v


class DeviceAttributes(StrEnum):
    """Midea B8 device attributes."""

    work_status = "work_status"
    sub_work_status = "sub_work_status"
    sweep_mop_mode = "sweep_mop_mode"
    function_type = "function_type"
    control_type = "control_type"
    move_direction = "move_direction"
    clean_mode = "clean_mode"
    fan_level = "fan_level"
    area = "area"
    water_level = "water_level"
    voice_volume = "voice_volume"
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
        super().__init__(
            device_type=DeviceType.B8,
            **kwargs,
            attributes={
                DeviceAttributes.work_status: B8WorkStatus.NONE.name.lower(),
                # v2-only; stays "none" on v1 devices
                DeviceAttributes.sub_work_status: "none",
                DeviceAttributes.sweep_mop_mode: "none",
                DeviceAttributes.function_type: B8FunctionType.NONE.name.lower(),
                DeviceAttributes.control_type: B8ControlType.NONE.name.lower(),
                DeviceAttributes.move_direction: B8Moviment.NONE.name.lower(),
                DeviceAttributes.clean_mode: B8CleanMode.NONE.name.lower(),
                DeviceAttributes.fan_level: B8FanLevel.OFF.name.lower(),
                DeviceAttributes.area: 0,
                DeviceAttributes.water_level: B8WaterLevel.OFF.name.lower(),
                DeviceAttributes.voice_volume: 0,
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
    def _is_v2(self) -> bool:
        """Whether this device speaks the second-generation B8 protocol."""
        return self.subtype in _V2_SUBTYPES

    def build_query(self) -> list[MessageQuery | MessageV2Query]:
        """Midea B8 device build query."""
        if self._is_v2:
            return [MessageV2Query(self._message_protocol_version)]
        return [MessageQuery(self._message_protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea B8 device process message."""
        message: MessageB8Response | MessageB8V2Response = (
            MessageB8V2Response(msg) if self._is_v2 else MessageB8Response(msg)
        )
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        # lowercase name for IntEnums, pass through everything else unchanged
        return self.update_attributes_from_message(
            message,
            default_transform=_translate_int_enum,
        )

    def _gen_set_msg_default_values(self) -> MessageSet:
        msg = MessageSet(self._message_protocol_version)
        msg.clean_mode = B8CleanMode[
            self.attributes[DeviceAttributes.clean_mode].upper()
        ]
        msg.fan_level = B8FanLevel[self.attributes[DeviceAttributes.fan_level].upper()]
        msg.water_level = B8WaterLevel[
            self.attributes[DeviceAttributes.water_level].upper()
        ]
        msg.voice_volume = self.attributes[DeviceAttributes.voice_volume]
        return msg

    def set_work_mode(self, work_mode: B8WorkMode) -> None:
        """Midea B8 device set work mode."""
        if self._is_v2:
            task = _WORK_MODE_TO_V2_TASK.get(work_mode)
            if task is None:
                _LOGGER.warning("Unsupported v2 work mode: %s", work_mode)
                return
            self.build_send(
                MessageV2SetCommand(self._message_protocol_version, task),
            )
            return

        if work_mode == B8WorkMode.WORK:
            self.set_attribute(
                DeviceAttributes.clean_mode,
                self.attributes[DeviceAttributes.clean_mode],
            )
            return

        msg = MessageSetCommand(self._message_protocol_version, work_mode=work_mode)
        self.build_send(msg)

    def _set_attribute_v2(self, attr: str, value: bool | float | str) -> None:
        """Midea B8 v2 device set attribute (one frame per setting)."""
        try:
            if attr == DeviceAttributes.fan_level:
                msg: MessageV2SetConfig = MessageV2SetConfig(
                    self._message_protocol_version,
                    B8V2ConfigType.FAN,
                    B8V2FanLevel[str(value).upper()],
                )
            elif attr == DeviceAttributes.water_level:
                msg = MessageV2SetConfig(
                    self._message_protocol_version,
                    B8V2ConfigType.WATER,
                    B8V2WaterLevel[str(value).upper()],
                )
            elif attr == DeviceAttributes.voice_volume:
                msg = MessageV2SetConfig(
                    self._message_protocol_version,
                    B8V2ConfigType.VOICE,
                    max(1, min(int(value), 100)),
                )
            else:
                _LOGGER.warning("Unsupported v2 attribute set: %s", attr)
                return
            self.build_send(msg)
        except KeyError:
            _LOGGER.exception("Wrong value for attribute %s: %s", attr, value)

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea B8 device set attribute."""
        if self._is_v2:
            self._set_attribute_v2(attr, value)
            return
        try:
            msg = self._gen_set_msg_default_values()
            if attr == DeviceAttributes.clean_mode:
                msg.clean_mode = B8CleanMode[str(value).upper()]
            elif attr == DeviceAttributes.fan_level:
                msg.fan_level = B8FanLevel[str(value).upper()]
            elif attr == DeviceAttributes.water_level:
                msg.water_level = B8WaterLevel[str(value).upper()]
            elif attr == DeviceAttributes.voice_volume:
                msg.voice_volume = int(value)

            if msg is not None:
                self.build_send(msg)
        except KeyError:
            _LOGGER.exception("Wrong value for attribute %s: %s", attr, value)


class MideaAppliance(MideaB8Device):
    """Midea B8 appliance."""
