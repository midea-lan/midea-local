"""Midea local AC device."""

import json
import logging
from enum import StrEnum
from typing import Any, ClassVar

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.device import MideaDevice

from .message import (
    MessageACResponse,
    MessageCapabilitiesAdditionalQuery,
    MessageCapabilitiesQuery,
    MessageGeneralSet,
    MessageGroupZeroQuery,
    MessageHumidityQuery,
    MessageNewProtocolQuery,
    MessageNewProtocolSet,
    MessagePowerQuery,
    MessageQuery,
    MessageSubProtocolQuery,
    MessageSubProtocolSet,
    MessageToggleDisplay,
)

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Midea AC device attributes."""

    prompt_tone = "prompt_tone"
    power = "power"
    mode = "mode"
    target_temperature = "target_temperature"
    fan_speed = "fan_speed"
    swing_vertical = "swing_vertical"
    swing_horizontal = "swing_horizontal"
    boost_mode = "boost_mode"
    smart_eye = "smart_eye"
    dry = "dry"
    eco_mode = "eco_mode"
    aux_heating = "aux_heating"
    sleep_mode = "sleep_mode"
    natural_wind = "natural_wind"
    temp_fahrenheit = "temp_fahrenheit"
    screen_display = "screen_display"
    screen_display_alternate = "screen_display_alternate"
    full_dust = "full_dust"
    frost_protect = "frost_protect"
    comfort_mode = "comfort_mode"
    indoor_temperature = "indoor_temperature"
    outdoor_temperature = "outdoor_temperature"
    indirect_wind = "indirect_wind"
    indoor_humidity = "indoor_humidity"
    breezeless = "breezeless"
    fresh_air_power = "fresh_air_power"
    fresh_air_fan_speed = "fresh_air_fan_speed"
    fresh_air_mode = "fresh_air_mode"
    fresh_air_1 = "fresh_air_1"
    fresh_air_2 = "fresh_air_2"
    total_energy_consumption = "total_energy_consumption"
    total_operating_consumption = "total_operating_consumption"
    current_energy_consumption = "current_energy_consumption"
    realtime_power = "realtime_power"
    electrify_time = "electrify_time"
    total_operating_time = "total_operating_time"
    current_operating_time = "current_operating_time"
    wind_lr_angle = "wind_lr_angle"
    wind_ud_angle = "wind_ud_angle"


class MideaACDevice(MideaDevice):
    """Midea AC device."""

    _fresh_air_fan_speeds: ClassVar[dict[int, str]] = {
        0: "off",
        20: "silent",
        40: "low",
        60: "medium",
        80: "high",
        100: "full",
    }

    _wind_lr_angles: ClassVar[dict[int, str]] = {
        0: "off",
        1: "left",
        25: "left-mid",
        50: "middle",
        75: "right-mid",
        100: "right",
    }

    _wind_ud_angles: ClassVar[dict[int, str]] = {
        0: "off",
        1: "up",
        25: "up-mid",
        50: "middle",
        75: "down-mid",
        100: "down",
    }

    def __init__(
        self,
        name: str,
        device_id: int,
        ip_address: str,
        port: int,
        token: str,
        key: str,
        device_protocol: ProtocolVersion,
        model: str,
        subtype: int,
        customize: str,
    ) -> None:
        """Initialize Midea AC device."""
        super().__init__(
            name=name,
            device_id=device_id,
            device_type=DeviceType.AC,
            ip_address=ip_address,
            port=port,
            token=token,
            key=key,
            device_protocol=device_protocol,
            model=model,
            subtype=subtype,
            attributes={
                DeviceAttributes.prompt_tone: True,
                DeviceAttributes.power: False,
                DeviceAttributes.mode: 0,
                DeviceAttributes.target_temperature: 24.0,
                DeviceAttributes.fan_speed: 102,
                DeviceAttributes.swing_vertical: False,
                DeviceAttributes.swing_horizontal: False,
                DeviceAttributes.smart_eye: False,
                DeviceAttributes.dry: False,
                DeviceAttributes.aux_heating: False,
                DeviceAttributes.boost_mode: False,
                DeviceAttributes.sleep_mode: False,
                DeviceAttributes.frost_protect: False,
                DeviceAttributes.comfort_mode: False,
                DeviceAttributes.eco_mode: False,
                DeviceAttributes.natural_wind: False,
                DeviceAttributes.temp_fahrenheit: False,
                DeviceAttributes.screen_display: False,
                DeviceAttributes.screen_display_alternate: False,
                DeviceAttributes.full_dust: False,
                DeviceAttributes.indoor_temperature: None,
                DeviceAttributes.outdoor_temperature: None,
                DeviceAttributes.indirect_wind: False,
                DeviceAttributes.indoor_humidity: None,
                DeviceAttributes.breezeless: False,
                DeviceAttributes.total_energy_consumption: None,
                DeviceAttributes.total_operating_consumption: None,
                DeviceAttributes.current_energy_consumption: None,
                DeviceAttributes.realtime_power: None,
                DeviceAttributes.electrify_time: None,
                DeviceAttributes.total_operating_time: None,
                DeviceAttributes.current_operating_time: None,
                DeviceAttributes.fresh_air_power: False,
                DeviceAttributes.fresh_air_fan_speed: 0,
                DeviceAttributes.fresh_air_mode: None,
                DeviceAttributes.fresh_air_1: None,
                DeviceAttributes.fresh_air_2: None,
                DeviceAttributes.wind_lr_angle: None,
                DeviceAttributes.wind_ud_angle: None,
            },
        )
        self._fresh_air_version: DeviceAttributes | None = None
        self._default_temperature_step: float = 0.5
        self._temperature_step: float = 0.5
        self._used_subprotocol: bool = False
        self._bb_sn8_flag: bool = False
        self._bb_timer: bool = False
        self._power_analysis_method: int = 1
        self._default_power_analysis_method: int = 1
        self.set_customize(customize)

    @property
    def temperature_step(self) -> float | None:
        """Midea AC device temperature step."""
        return self._temperature_step

    @property
    def fresh_air_fan_speeds(self) -> list[str]:
        """Midea AC device fresh air fan speeds."""
        return list(MideaACDevice._fresh_air_fan_speeds.values())

    @property
    def wind_lr_angles(self) -> list[str]:
        """Midea AC device wind_lr_angle."""
        return list(MideaACDevice._wind_lr_angles.values())

    @property
    def wind_ud_angles(self) -> list[str]:
        """Midea AC device wind_ud_angle."""
        return list(MideaACDevice._wind_ud_angles.values())

    def build_query(
        self,
    ) -> list[
        MessageSubProtocolQuery
        | MessageQuery
        | MessageNewProtocolQuery
        | MessagePowerQuery
        | MessageHumidityQuery
        | MessageGroupZeroQuery
        | MessageCapabilitiesQuery
        | MessageCapabilitiesAdditionalQuery
    ]:
        """Midea AC device build query."""
        if self._used_subprotocol:
            return [
                MessageSubProtocolQuery(self._message_protocol_version, 0x10),
                MessageSubProtocolQuery(self._message_protocol_version, 0x11),
                MessageSubProtocolQuery(self._message_protocol_version, 0x30),
            ]
        return [
            MessageQuery(self._message_protocol_version),
            MessageNewProtocolQuery(self._message_protocol_version),
            MessagePowerQuery(self._message_protocol_version),
            MessageHumidityQuery(self._message_protocol_version),
            MessageGroupZeroQuery(self._message_protocol_version),
            MessageCapabilitiesQuery(self._message_protocol_version),
            MessageCapabilitiesAdditionalQuery(self._message_protocol_version),
        ]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea AC device process message."""
        message = MessageACResponse(bytearray(msg), self._power_analysis_method)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        new_status = {}
        has_fresh_air = False
        if hasattr(message, "used_subprotocol"):
            self._used_subprotocol = True
            if hasattr(message, "sn8_flag"):
                self._bb_sn8_flag = message.sn8_flag
            if hasattr(message, "timer"):
                self._bb_timer = message.timer
        for attr in self._attributes:
            if hasattr(message, str(attr)):
                value = getattr(message, str(attr))
                if attr == DeviceAttributes.fresh_air_power:
                    has_fresh_air = True
                # wind_lr_angle
                if attr == DeviceAttributes.wind_lr_angle:
                    self._attributes[attr] = MideaACDevice._wind_lr_angles.get(value)
                # wind_ud_angle
                elif attr == DeviceAttributes.wind_ud_angle:
                    self._attributes[attr] = MideaACDevice._wind_ud_angles.get(value)
                else:
                    self._attributes[attr] = value
                new_status[str(attr)] = self._attributes[attr]
        if has_fresh_air:
            if self._attributes[DeviceAttributes.fresh_air_power]:
                for k, v in MideaACDevice._fresh_air_fan_speeds.items():
                    if self._attributes[DeviceAttributes.fresh_air_fan_speed] < k:
                        break
                    self._attributes[DeviceAttributes.fresh_air_mode] = v
            else:
                self._attributes[DeviceAttributes.fresh_air_mode] = "off"
            new_status[DeviceAttributes.fresh_air_mode.value] = self._attributes[
                DeviceAttributes.fresh_air_mode
            ]
        if not self._attributes[DeviceAttributes.power] or (
            DeviceAttributes.swing_vertical in new_status
            and self._attributes[DeviceAttributes.swing_vertical]
        ):
            self._attributes[DeviceAttributes.indirect_wind] = False
            new_status[DeviceAttributes.indirect_wind.value] = False
        if not self._attributes[DeviceAttributes.power]:
            self._attributes[DeviceAttributes.screen_display] = False
            new_status[DeviceAttributes.screen_display.value] = False
        if self._attributes[DeviceAttributes.fresh_air_1] is not None:
            self._fresh_air_version = DeviceAttributes.fresh_air_1
        elif self._attributes[DeviceAttributes.fresh_air_2] is not None:
            self._fresh_air_version = DeviceAttributes.fresh_air_2
        return new_status

    def make_message_set(self) -> MessageGeneralSet:
        """Midea AC device make message set."""
        message = MessageGeneralSet(self._message_protocol_version)
        message.power = self._attributes[DeviceAttributes.power]
        message.prompt_tone = self._attributes[DeviceAttributes.prompt_tone]
        message.mode = self._attributes[DeviceAttributes.mode]
        message.target_temperature = self._attributes[
            DeviceAttributes.target_temperature
        ]
        message.fan_speed = self._attributes[DeviceAttributes.fan_speed]
        message.swing_vertical = self._attributes[DeviceAttributes.swing_vertical]
        message.swing_horizontal = self._attributes[DeviceAttributes.swing_horizontal]
        message.boost_mode = self._attributes[DeviceAttributes.boost_mode]
        message.smart_eye = self._attributes[DeviceAttributes.smart_eye]
        message.dry = self._attributes[DeviceAttributes.dry]
        message.eco_mode = self._attributes[DeviceAttributes.eco_mode]
        message.aux_heating = self._attributes[DeviceAttributes.aux_heating]
        message.sleep_mode = self._attributes[DeviceAttributes.sleep_mode]
        message.natural_wind = self._attributes[DeviceAttributes.natural_wind]
        message.temp_fahrenheit = self._attributes[DeviceAttributes.temp_fahrenheit]
        message.frost_protect = self._attributes[DeviceAttributes.frost_protect]
        message.comfort_mode = self._attributes[DeviceAttributes.comfort_mode]
        return message

    def make_newprotocol_message_set(
        self,
        attr: str,
        value: bool | int | str,
    ) -> MessageNewProtocolSet:
        """Midea AC device make newprotocol message set."""
        message = MessageNewProtocolSet(self._message_protocol_version)

        # wind_lr_angle
        if attr == DeviceAttributes.wind_lr_angle:
            message.wind_lr_angle = MideaACDevice.get_dict_key_by_value(
                "_wind_lr_angles",
                str(value),
            )
        # wind_ud_angle
        elif attr == DeviceAttributes.wind_ud_angle:
            message.wind_ud_angle = MideaACDevice.get_dict_key_by_value(
                "_wind_ud_angles",
                str(value),
            )
        # fresh_air_power
        elif attr == DeviceAttributes.fresh_air_power:
            if self._fresh_air_version is not None:
                setattr(
                    message,
                    str(self._fresh_air_version),
                    [value, self._attributes[DeviceAttributes.fresh_air_fan_speed]],
                )
        # fresh_air_mode
        elif attr == DeviceAttributes.fresh_air_mode:
            if value in MideaACDevice._fresh_air_fan_speeds.values():
                speed = list(MideaACDevice._fresh_air_fan_speeds.keys())[
                    list(MideaACDevice._fresh_air_fan_speeds.values()).index(
                        str(value),
                    )
                ]
                fresh_air = (
                    [True, speed]
                    if speed > 0
                    else [
                        False,
                        self._attributes[DeviceAttributes.fresh_air_fan_speed],
                    ]
                )
                setattr(message, str(self._fresh_air_version), fresh_air)
            elif not value:
                setattr(
                    message,
                    str(self._fresh_air_version),
                    [False, self._attributes[DeviceAttributes.fresh_air_fan_speed]],
                )
        # fresh_air_fan_speed
        elif attr == DeviceAttributes.fresh_air_fan_speed:
            if self._fresh_air_version is not None:
                fresh_air = (
                    [True, int(value)]
                    if int(value) > 0
                    else [
                        False,
                        self._attributes[DeviceAttributes.fresh_air_fan_speed],
                    ]
                )
                setattr(message, str(self._fresh_air_version), fresh_air)
        # indirect_wind, screen_display_alternate, breezeless
        else:
            setattr(message, str(attr), value)
        # read current prompt_tone for current set action
        message.prompt_tone = self._attributes[DeviceAttributes.prompt_tone]

        return message

    def make_subprotocol_message_set(self) -> MessageSubProtocolSet:
        """Midea AC device make subprotocol message set."""
        message = MessageSubProtocolSet(self._message_protocol_version)
        message.power = self._attributes[DeviceAttributes.power]
        message.prompt_tone = self._attributes[DeviceAttributes.prompt_tone]
        message.aux_heating = self._attributes[DeviceAttributes.aux_heating]
        message.mode = self._attributes[DeviceAttributes.mode]
        message.target_temperature = self._attributes[
            DeviceAttributes.target_temperature
        ]
        message.fan_speed = self._attributes[DeviceAttributes.fan_speed]
        message.boost_mode = self._attributes[DeviceAttributes.boost_mode]
        message.dry = self._attributes[DeviceAttributes.dry]
        message.eco_mode = self._attributes[DeviceAttributes.eco_mode]
        message.sleep_mode = self._attributes[DeviceAttributes.sleep_mode]
        message.sn8_flag = self._bb_sn8_flag
        message.timer = self._bb_timer
        return message

    def make_message_uniq_set(self) -> MessageSubProtocolSet | MessageGeneralSet:
        """Midea AC device make message unique set."""
        message: MessageSubProtocolSet | MessageGeneralSet
        if self._used_subprotocol:
            message = self.make_subprotocol_message_set()
        else:
            message = self.make_message_set()
        return message

    def set_attribute(self, attr: str, value: bool | int | str) -> None:
        """Midea AC device set attribute."""
        # if nat a sensor
        message: (
            MessageToggleDisplay
            | MessageNewProtocolSet
            | MessageSubProtocolSet
            | MessageGeneralSet
            | None
        ) = None
        if attr not in [
            DeviceAttributes.indoor_temperature,
            DeviceAttributes.outdoor_temperature,
            DeviceAttributes.indoor_humidity,
            DeviceAttributes.full_dust,
            DeviceAttributes.total_energy_consumption,
            DeviceAttributes.current_energy_consumption,
            DeviceAttributes.realtime_power,
        ]:
            if attr == DeviceAttributes.prompt_tone:
                self._attributes[DeviceAttributes.prompt_tone] = value
                self.update_all({DeviceAttributes.prompt_tone.value: value})
            elif attr == DeviceAttributes.screen_display:
                message = MessageToggleDisplay(self._message_protocol_version)
                message.prompt_tone = self._attributes[DeviceAttributes.prompt_tone]
            elif attr in [
                DeviceAttributes.indirect_wind,
                DeviceAttributes.breezeless,
                DeviceAttributes.screen_display_alternate,
                DeviceAttributes.fresh_air_power,
                DeviceAttributes.fresh_air_fan_speed,
                DeviceAttributes.fresh_air_mode,
                DeviceAttributes.wind_lr_angle,
                DeviceAttributes.wind_ud_angle,
            ]:
                message = self.make_newprotocol_message_set(attr=attr, value=value)
            elif attr in self._attributes:
                message = self.make_message_uniq_set()
                if attr in [
                    DeviceAttributes.boost_mode,
                    DeviceAttributes.sleep_mode,
                    DeviceAttributes.frost_protect,
                    DeviceAttributes.comfort_mode,
                    DeviceAttributes.eco_mode,
                ]:
                    message.boost_mode = False
                    message.sleep_mode = False
                    message.eco_mode = False
                    if not isinstance(message, MessageSubProtocolSet):
                        message.comfort_mode = False
                        message.frost_protect = False
                setattr(message, str(attr), value)
                if attr == DeviceAttributes.mode:
                    setattr(message, str(DeviceAttributes.power.value), True)
                    # Reset dry flag when changing mode to avoid conflicts
                    # The dry flag (byte 9, bit 0x04) can block mode changes
                    # when transitioning from DRY mode to other modes
                    message.dry = False
                    # Force fan_speed to AUTO when leaving DRY mode (mode 3)
                    if self._attributes[DeviceAttributes.mode] == 3:
                        message.fan_speed = 102
        if message is not None:
            self.build_send(message)

    def set_target_temperature(
        self,
        target_temperature: float,
        mode: int | None,
        zone: int | None = None,  # noqa: ARG002
    ) -> None:
        """Midea AC device set target temperature."""
        message: MessageSubProtocolSet | MessageGeneralSet = (
            self.make_message_uniq_set()
        )
        message.target_temperature = target_temperature
        if mode is not None:
            message.power = True
            message.mode = mode
        self.build_send(message)

    def set_swing(self, swing_vertical: bool, swing_horizontal: bool) -> None:
        """Midea AC device set swing."""
        message: MessageSubProtocolSet | MessageGeneralSet = (
            self.make_message_uniq_set()
        )
        if isinstance(message, MessageGeneralSet):
            message.swing_vertical = swing_vertical
            message.swing_horizontal = swing_horizontal
        self.build_send(message)

    def set_customize(self, customize: str) -> None:
        """Midea AC device set custommize."""
        self._temperature_step = self._default_temperature_step
        self._power_analysis_method = self._default_power_analysis_method
        if customize and len(customize) > 0:
            try:
                params = json.loads(customize)
                if params and "temperature_step" in params:
                    self._temperature_step = params.get("temperature_step")
                if params and "power_analysis_method" in params:
                    self._power_analysis_method = params.get("power_analysis_method")
            except Exception:
                _LOGGER.exception("[%s] Set customize error", self.device_id)
            self.update_all({"temperature_step": self._temperature_step})


class MideaAppliance(MideaACDevice):
    """Midea AC appliance."""
