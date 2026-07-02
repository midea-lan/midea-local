"""Midea local CC device."""

import logging
from enum import StrEnum
from typing import Any, ClassVar, Unpack

from midealocal.const import DeviceType
from midealocal.device import MideaDevice, MideaDeviceInitKwargs

from .message import (
    INDEX_TO_FE_MODE,
    CCControlId,
    MessageCCResponse,
    MessageFEControl,
    MessageQuery,
    MessageSet,
)

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Midea CC device attributes."""

    power = "power"
    mode = "mode"
    target_temperature = "target_temperature"
    fan_speed = "fan_speed"
    eco_mode = "eco_mode"
    sleep_mode = "sleep_mode"
    night_light = "night_light"
    aux_heating = "aux_heating"
    swing = "swing"
    ventilation = "ventilation"
    temperature_precision = "temperature_precision"
    fan_speed_level = "fan_speed_level"
    indoor_temperature = "indoor_temperature"
    aux_heat_status = "aux_heat_status"
    auto_aux_heat_running = "auto_aux_heat_running"
    temp_fahrenheit = "temp_fahrenheit"


class MideaCCDevice(MideaDevice):
    """Midea CC device."""

    _fan_speeds_7level: ClassVar[dict[int, str]] = {
        0x01: "Level 1",
        0x02: "Level 2",
        0x04: "Level 3",
        0x08: "Level 4",
        0x10: "Level 5",
        0x20: "Level 6",
        0x40: "Level 7",
        0x80: "Auto",
    }
    _fan_speeds_3level: ClassVar[dict[int, str]] = {
        0x01: "Low",
        0x08: "Medium",
        0x40: "High",
        0x80: "Auto",
    }
    # 0xFE VRF panels report fan speed as 1-7 (+8=auto), not as a bitmask
    _fan_speeds_fe: ClassVar[dict[int, str]] = {
        0x01: "Level 1",
        0x02: "Level 2",
        0x03: "Level 3",
        0x04: "Level 4",
        0x05: "Level 5",
        0x06: "Level 6",
        0x07: "Level 7",
        0x08: "Auto",
    }

    def __init__(
        self,
        *,
        customize: str,  # noqa: ARG002
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Midea CC device."""
        super().__init__(
            device_type=DeviceType.CC,
            **kwargs,
            attributes={
                DeviceAttributes.power: False,
                DeviceAttributes.mode: 1,
                DeviceAttributes.target_temperature: 26.0,
                DeviceAttributes.fan_speed: 0x80,
                DeviceAttributes.sleep_mode: False,
                DeviceAttributes.eco_mode: False,
                DeviceAttributes.night_light: False,
                DeviceAttributes.ventilation: False,
                DeviceAttributes.aux_heating: False,
                DeviceAttributes.aux_heat_status: 0,
                DeviceAttributes.auto_aux_heat_running: False,
                DeviceAttributes.swing: False,
                DeviceAttributes.fan_speed_level: None,
                DeviceAttributes.indoor_temperature: None,
                DeviceAttributes.temperature_precision: 1,
                DeviceAttributes.temp_fahrenheit: False,
            },
        )
        self._fan_speeds: dict[int, str] | None = None
        # set once a 0xFE-format response is seen; selects the VRF control path
        self._is_fe_format = False

    @property
    def fan_modes(self) -> list[str] | None:
        """Midea CC device fan modes."""
        return None if self._fan_speeds is None else list(self._fan_speeds.values())

    def build_query(self) -> list[MessageQuery]:
        """Midea CC device build query."""
        return [MessageQuery(self._message_protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea CC device process message."""
        message = MessageCCResponse(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        if getattr(message, "is_fe_format", False):
            self._is_fe_format = True
            _LOGGER.debug("[%s] _is_fe_format option True", self.device_id)
        new_status = {}
        fan_speed: int | None = None
        for status in self._attributes:
            if hasattr(message, str(status)):
                value = getattr(message, str(status))
                if status == DeviceAttributes.fan_speed:
                    fan_speed = value
                else:
                    self._attributes[status] = getattr(message, str(status))
                    new_status[str(status)] = getattr(message, str(status))
        if (
            fan_speed is not None
            and self._attributes[DeviceAttributes.fan_speed_level] is not None
        ):
            if self._is_fe_format:
                self._fan_speeds = MideaCCDevice._fan_speeds_fe
            elif self._fan_speeds is None:
                if self._attributes[DeviceAttributes.fan_speed_level]:
                    self._fan_speeds = MideaCCDevice._fan_speeds_3level
                else:
                    self._fan_speeds = MideaCCDevice._fan_speeds_7level
            if fan_speed in self._fan_speeds:
                self._attributes[DeviceAttributes.fan_speed] = self._fan_speeds.get(
                    fan_speed,
                )
            else:
                self._attributes[DeviceAttributes.fan_speed] = None
            new_status[DeviceAttributes.fan_speed.value] = self._attributes[
                DeviceAttributes.fan_speed
            ]
        aux_heating = (
            self._attributes[DeviceAttributes.aux_heat_status] == 1
            or self._attributes[DeviceAttributes.auto_aux_heat_running]
        )
        if self._attributes[DeviceAttributes.aux_heating] != aux_heating:
            self._attributes[DeviceAttributes.aux_heating] = aux_heating
            new_status[DeviceAttributes.aux_heating.value] = self._attributes[
                DeviceAttributes.aux_heating
            ]
        return new_status

    def make_message_set(self) -> MessageSet:
        """Midea CC device make message set."""
        message = MessageSet(self._message_protocol_version)
        message.power = self._attributes[DeviceAttributes.power]
        message.mode = self._attributes[DeviceAttributes.mode]
        message.target_temperature = self._attributes[
            DeviceAttributes.target_temperature
        ]
        if self._fan_speeds:
            message.fan_speed = list(self._fan_speeds.keys())[
                list(self._fan_speeds.values()).index(
                    self._attributes[DeviceAttributes.fan_speed],
                )
            ]
        message.eco_mode = self._attributes[DeviceAttributes.eco_mode]
        message.sleep_mode = self._attributes[DeviceAttributes.sleep_mode]
        message.night_light = self._attributes[DeviceAttributes.night_light]
        message.aux_heat_status = self._attributes[DeviceAttributes.aux_heat_status]
        message.swing = self._attributes[DeviceAttributes.swing]
        return message

    def _fe_temperature_value(self, target_temperature: float) -> int:
        """Encode a target temperature for the 0xFE control protocol."""
        return int(target_temperature * 2 + 80) & 0xFF

    def _send_fe_control(self, controls: list[tuple[CCControlId, int]]) -> None:
        """Build and send a 0xFE key-value control frame."""
        self.build_send(
            MessageFEControl(self._message_protocol_version, controls),
        )

    def set_target_temperature(
        self,
        target_temperature: float,
        mode: int | None,
        zone: int | None = None,  # noqa: ARG002
    ) -> None:
        """Midea CC device set target temperature."""
        if self._is_fe_format:
            controls: list[tuple[CCControlId, int]] = []
            if mode is not None:
                controls.append((CCControlId.POWER, 1))
                controls.append((CCControlId.MODE, INDEX_TO_FE_MODE.get(mode, 0x02)))
            controls.append(
                (
                    CCControlId.TARGET_TEMPERATURE,
                    self._fe_temperature_value(target_temperature),
                ),
            )
            self._send_fe_control(controls)
            return
        message = self.make_message_set()
        message.target_temperature = target_temperature
        if mode is not None:
            message.power = True
            message.mode = mode
        self.build_send(message)

    def _set_attribute_fe(self, attr: str, value: bool | int | str) -> None:
        """Set an attribute on a 0xFE VRF panel via key-value control frames."""
        if attr == DeviceAttributes.power:
            self._send_fe_control([(CCControlId.POWER, 1 if value else 0)])
        elif attr == DeviceAttributes.mode:
            self._send_fe_control(
                [
                    (CCControlId.POWER, 1),
                    (CCControlId.MODE, INDEX_TO_FE_MODE.get(int(value), 0x02)),
                ],
            )
        elif attr == DeviceAttributes.fan_speed:
            if self._fan_speeds and value in self._fan_speeds.values():
                speed = list(self._fan_speeds.keys())[
                    list(self._fan_speeds.values()).index(str(value))
                ]
                self._send_fe_control([(CCControlId.FAN_SPEED, speed)])
        elif attr == DeviceAttributes.eco_mode:
            self._send_fe_control([(CCControlId.ECO, 1 if value else 0)])
        elif attr == DeviceAttributes.sleep_mode:
            self._send_fe_control([(CCControlId.SLEEP, 1 if value else 0)])
        elif attr == DeviceAttributes.swing:
            self._send_fe_control([(CCControlId.SWING, 0x06 if value else 0x00)])
        # other attributes are not supported by the 0xFE control protocol

    def set_attribute(self, attr: str, value: bool | int | str) -> None:
        """Midea CC device set attribute."""
        if self._is_fe_format:
            self._set_attribute_fe(attr, value)
            return
        # if nat a sensor
        if attr not in [
            DeviceAttributes.indoor_temperature,
            DeviceAttributes.temperature_precision,
            DeviceAttributes.fan_speed_level,
            DeviceAttributes.aux_heat_status,
            DeviceAttributes.auto_aux_heat_running,
        ]:
            message = self.make_message_set()
            if attr == DeviceAttributes.fan_speed:
                if self._fan_speeds and value in self._fan_speeds.values():
                    message.fan_speed = list(self._fan_speeds.keys())[
                        list(self._fan_speeds.values()).index(str(value))
                    ]
            else:
                setattr(message, str(attr), value)
                if attr == DeviceAttributes.mode:
                    setattr(message, str(DeviceAttributes.power.value), True)
                elif attr == DeviceAttributes.eco_mode and value:
                    setattr(message, str(DeviceAttributes.sleep_mode.value), False)
                elif attr == DeviceAttributes.sleep_mode and value:
                    setattr(message, str(DeviceAttributes.eco_mode.value), False)
                elif attr == DeviceAttributes.aux_heating:
                    if value:
                        setattr(message, DeviceAttributes.aux_heat_status, 1)
                    else:
                        setattr(message, DeviceAttributes.aux_heat_status, 2)
            self.build_send(message)


class MideaAppliance(MideaCCDevice):
    """Midea CC appliance."""
