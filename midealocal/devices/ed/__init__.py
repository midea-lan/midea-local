"""Midea local ED device."""

import logging
from enum import StrEnum
from typing import Any, Unpack

from midealocal.const import DeviceType
from midealocal.device import MideaDevice, MideaDeviceInitKwargs
from midealocal.message import ListTypes

from .message import (
    TEA_BAR_SUBTYPE,
    MessageEDResponse,
    MessageNewSet,
    MessageOldSet,
    MessageQuery,
    MessageQuery01,
    MessageQuery03,
    MessageQuery04,
    MessageQuery05,
    MessageQuery06,
    MessageQuery07,
    MessageQuery09,
    MessageQueryFF,
)

_LOGGER = logging.getLogger(__name__)

TEA_BAR_MIN_TARGET_TEMPERATURE = 40
TEA_BAR_MAX_TARGET_TEMPERATURE = 100
TEA_BAR_DEFAULT_TARGET_TEMPERATURE = 100
TEA_BAR_MIN_KEEP_WARM_HOURS = 1.0
TEA_BAR_MAX_KEEP_WARM_HOURS = 12.0
TEA_BAR_MODEL = "63000622"


class DeviceAttributes(StrEnum):
    """Midea ED device attributes."""

    power = "power"
    water_consumption = "water_consumption"
    in_tds = "in_tds"
    out_tds = "out_tds"
    filter1 = "filter1"
    filter2 = "filter2"
    filter3 = "filter3"
    life1 = "life1"
    life2 = "life2"
    life3 = "life3"
    child_lock = "child_lock"
    current_temperature = "current_temperature"
    target_temperature = "target_temperature"
    heating = "heating"
    dispensing = "dispensing"
    boil_temperature = "boil_temperature"
    boiling = "boiling"
    keep_warm = "keep_warm"
    keep_warm_time = "keep_warm_time"
    keep_warm_remaining = "keep_warm_remaining"
    sleep = "sleep"
    screen_display = "screen_display"
    cooling = "cooling"
    lack_water = "lack_water"
    standby = "standby"
    hot_water_dispensing = "hot_water_dispensing"
    fault_code = "fault_code"
    fault = "fault"
    # Soft water machine (water softener) attributes
    velocity = "velocity"
    soft_available = "soft_available"
    left_salt = "left_salt"
    leak_water_protection_value = "leak_water_protection_value"
    remaining_days = "remaining_days"
    water_hardness = "water_hardness"
    flushing_days = "flushing_days"
    timing_regeneration_hour = "timing_regeneration_hour"
    timing_regeneration_min = "timing_regeneration_min"
    regeneration_left_seconds = "regeneration_left_seconds"
    use_days = "use_days"
    salt_setting = "salt_setting"
    soft_available_big = "soft_available_big"
    water_consumption_big = "water_consumption_big"
    water_consumption_average = "water_consumption_average"
    soften = "soften"
    cl_sterilization = "cl_sterilization"
    leak_water_protection = "leak_water_protection"
    leak_water = "leak_water"
    water_way = "water_way"
    rsj_stand_by = "rsj_stand_by"
    regeneration = "regeneration"
    error = "error"


class MideaEDDevice(MideaDevice):
    """Midea ED device."""

    def __init__(
        self,
        *,
        customize: str,  # noqa: ARG002
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Midea ED device."""
        super().__init__(
            device_type=DeviceType.ED,
            **kwargs,
            attributes={
                DeviceAttributes.power: False,
                DeviceAttributes.water_consumption: None,
                DeviceAttributes.in_tds: None,
                DeviceAttributes.out_tds: None,
                DeviceAttributes.filter1: None,
                DeviceAttributes.filter2: None,
                DeviceAttributes.filter3: None,
                DeviceAttributes.life1: None,
                DeviceAttributes.life2: None,
                DeviceAttributes.life3: None,
                DeviceAttributes.child_lock: False,
                # Soft water machine (water softener) attributes
                DeviceAttributes.velocity: None,
                DeviceAttributes.soft_available: None,
                DeviceAttributes.left_salt: None,
                DeviceAttributes.leak_water_protection_value: None,
                DeviceAttributes.remaining_days: None,
                DeviceAttributes.water_hardness: None,
                DeviceAttributes.flushing_days: None,
                DeviceAttributes.timing_regeneration_hour: None,
                DeviceAttributes.timing_regeneration_min: None,
                DeviceAttributes.regeneration_left_seconds: None,
                DeviceAttributes.use_days: None,
                DeviceAttributes.salt_setting: None,
                DeviceAttributes.soft_available_big: None,
                DeviceAttributes.water_consumption_big: None,
                DeviceAttributes.water_consumption_average: None,
                DeviceAttributes.soften: False,
                DeviceAttributes.cl_sterilization: False,
                DeviceAttributes.leak_water_protection: False,
                DeviceAttributes.leak_water: False,
                DeviceAttributes.water_way: False,
                DeviceAttributes.rsj_stand_by: False,
                DeviceAttributes.regeneration: False,
                DeviceAttributes.error: None,
            },
        )
        if self.subtype == TEA_BAR_SUBTYPE:
            self._attributes.update(
                {
                    DeviceAttributes.current_temperature: None,
                    DeviceAttributes.target_temperature: None,
                    DeviceAttributes.heating: False,
                    DeviceAttributes.dispensing: False,
                    DeviceAttributes.boil_temperature: None,
                    DeviceAttributes.boiling: False,
                    DeviceAttributes.keep_warm: False,
                    DeviceAttributes.keep_warm_time: None,
                    DeviceAttributes.keep_warm_remaining: None,
                    DeviceAttributes.sleep: False,
                    DeviceAttributes.screen_display: True,
                    DeviceAttributes.cooling: False,
                    DeviceAttributes.lack_water: False,
                    DeviceAttributes.standby: False,
                    DeviceAttributes.hot_water_dispensing: False,
                    DeviceAttributes.fault_code: 0,
                    DeviceAttributes.fault: False,
                },
            )
        self._device_class = ListTypes.X00

    def _use_new_set(self) -> bool:
        # if (self.sub_type > 342 or self.sub_type == 340) else False
        return True

    def build_query(
        self,
    ) -> list[
        MessageQuery
        | MessageQuery01
        | MessageQuery03
        | MessageQuery04
        | MessageQuery05
        | MessageQuery06
        | MessageQuery07
        | MessageQuery09
        | MessageQueryFF
    ]:
        """Midea ED device build query."""
        # device can response for MessageQuery/MessageQuery01/MessageQuery03/etc
        # and only MessageQuery01 can return non-zero value.
        pv = self._message_protocol_version
        # Build single-message query for known subtypes; fall back to
        # the multi-message query set for unknown subtypes.
        # Subtype -> query message class mapping (single-message subtypes)
        subtype_query: dict[int, Any] = {
            **dict.fromkeys(
                [309, 310, 311, 313, 314, 315, 317, 330],
                MessageQuery04,
            ),
            **dict.fromkeys([316, 318, 319, 320], MessageQuery05),
            **dict.fromkeys([290, 331, 332, 340, TEA_BAR_SUBTYPE], MessageQuery06),
            **dict.fromkeys([288, 307, 329, 349], MessageQuery07),
            # Soft water machine (water softener) subtypes
            # subtype 703: model 6360000A, confirmed from cloud API modelNumber
            703: MessageQuery09,
            # for https://github.com/wuwentao/midea_ac_lan/issues/571
            # subtype 775 only can got non-zero value with MessageQuery01
            # more subtypes should using MessageQuery01, temp keep it in else
            # remove MessageQuery03 as it return 0
            775: MessageQuery01,
        }
        query_cls = subtype_query.get(self.subtype)
        if query_cls is not None:
            return [query_cls(pv)]
        return [
            MessageQuery(pv),
            MessageQuery01(pv),
            MessageQueryFF(pv),
        ]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea ED device process message."""
        message = MessageEDResponse(msg, self.subtype)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        new_status = {}
        if hasattr(message, "device_class"):
            self._device_class = message.device_class
        for status in self._attributes:
            if hasattr(message, str(status)):
                new_status[str(status)] = getattr(message, str(status))
                self._attributes[status] = getattr(message, str(status))
        if self.subtype == TEA_BAR_SUBTYPE:
            if DeviceAttributes.target_temperature in new_status:
                target_temperature = new_status[DeviceAttributes.target_temperature]
                new_status[DeviceAttributes.boil_temperature] = target_temperature
                self._attributes[DeviceAttributes.boil_temperature] = target_temperature
            if DeviceAttributes.heating in new_status:
                heating = new_status[DeviceAttributes.heating]
                new_status[DeviceAttributes.boiling] = heating
                self._attributes[DeviceAttributes.boiling] = heating
        return new_status

    def _set_tea_bar_attribute(
        self,
        attr: str,
        value: bool | float | str,
    ) -> bool:
        """Build and send a subtype-395 tea bar control command."""
        if (
            self.subtype != TEA_BAR_SUBTYPE
            or self.model != TEA_BAR_MODEL
            or attr
            not in [
                DeviceAttributes.boil_temperature,
                DeviceAttributes.boiling,
                DeviceAttributes.child_lock,
                DeviceAttributes.keep_warm,
                DeviceAttributes.keep_warm_time,
                DeviceAttributes.sleep,
                DeviceAttributes.screen_display,
                DeviceAttributes.cooling,
            ]
        ):
            return False

        message = MessageNewSet(self._message_protocol_version)
        stored_value: bool | float | str
        if attr == DeviceAttributes.boil_temperature:
            target_temperature = int(value)
            if not (
                TEA_BAR_MIN_TARGET_TEMPERATURE
                <= target_temperature
                <= TEA_BAR_MAX_TARGET_TEMPERATURE
            ):
                msg = (
                    "Tea bar target temperature must be between "
                    f"{TEA_BAR_MIN_TARGET_TEMPERATURE} and "
                    f"{TEA_BAR_MAX_TARGET_TEMPERATURE}"
                )
                raise ValueError(msg)
            self._validate_tea_bar_target(target_temperature)
            message.target_temperature = target_temperature
            message.heating = True
            stored_value = target_temperature
        elif attr == DeviceAttributes.boiling:
            boiling = bool(value)
            # Model 63000622's official App TeaHeat control always sends both
            # custom_temperature_1=100 and the heat_start toggle. It does not
            # use the generic ED heat (0x0400) field.
            message.target_temperature = TEA_BAR_DEFAULT_TARGET_TEMPERATURE
            message.heating = boiling
            stored_value = boiling
        elif attr == DeviceAttributes.child_lock:
            # Model 63000622's official Lua lock control is
            # setbytes(0x01, 0x02, 0x01/0x00, 0x00, 0x00).
            child_lock = bool(value)
            message.lock = child_lock
            stored_value = child_lock
        elif attr == DeviceAttributes.sleep:
            sleep = bool(value)
            message.sleep = sleep
            stored_value = sleep
        elif attr == DeviceAttributes.screen_display:
            screen_display = bool(value)
            message.sleep = not screen_display
            stored_value = screen_display
        elif attr == DeviceAttributes.cooling:
            cooling = bool(value)
            if (
                not cooling
                and self._attributes.get(DeviceAttributes.dispensing) is True
            ):
                msg = "Tea bar cooling cannot be stopped while dispensing water"
                raise ValueError(msg)
            message.cooling = cooling
            stored_value = cooling
        else:
            keep_warm = (
                bool(value)
                if attr == DeviceAttributes.keep_warm
                else bool(self._attributes.get(DeviceAttributes.keep_warm))
            )
            keep_warm_time = (
                float(value)
                if attr == DeviceAttributes.keep_warm_time
                else self._attributes.get(DeviceAttributes.keep_warm_time)
            )
            raw_keep_warm_time = 0
            if isinstance(keep_warm_time, int | float):
                if not (
                    TEA_BAR_MIN_KEEP_WARM_HOURS
                    <= keep_warm_time
                    <= TEA_BAR_MAX_KEEP_WARM_HOURS
                    and (float(keep_warm_time) * 2).is_integer()
                ):
                    msg = (
                        "Tea bar keep-warm time must be between "
                        f"{TEA_BAR_MIN_KEEP_WARM_HOURS:g} and "
                        f"{TEA_BAR_MAX_KEEP_WARM_HOURS:g} hours in 0.5-hour steps"
                    )
                    raise ValueError(msg)
                raw_keep_warm_time = int(keep_warm_time * 2)
            message.keep_warm = keep_warm
            message.keep_warm_time = raw_keep_warm_time
            stored_value = (
                keep_warm if attr == DeviceAttributes.keep_warm else float(value)
            )

        self._attributes[attr] = stored_value
        self.build_send(message)
        return True

    def _validate_tea_bar_target(self, target_temperature: int) -> None:
        """Reject a target that cannot increase the current temperature."""
        current_temperature = self._attributes.get(
            DeviceAttributes.current_temperature,
        )
        if (
            isinstance(current_temperature, int | float)
            and current_temperature >= target_temperature
        ):
            msg = (
                f"Tea bar current temperature {current_temperature} is not "
                f"below target temperature {target_temperature}"
            )
            raise ValueError(msg)

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea ED device set attribute."""
        if self._set_tea_bar_attribute(attr, value):
            return
        message: MessageNewSet | MessageOldSet | None = None
        if self._use_new_set():
            if attr in [
                DeviceAttributes.power,
                DeviceAttributes.child_lock,
                DeviceAttributes.soften,
                DeviceAttributes.cl_sterilization,
                DeviceAttributes.leak_water_protection,
                DeviceAttributes.water_way,
                DeviceAttributes.regeneration,
                DeviceAttributes.water_hardness,
                DeviceAttributes.flushing_days,
                DeviceAttributes.timing_regeneration_hour,
                DeviceAttributes.timing_regeneration_min,
                DeviceAttributes.salt_setting,
                DeviceAttributes.leak_water_protection_value,
            ]:
                message = MessageNewSet(self._message_protocol_version)
        else:
            message = MessageOldSet(self._message_protocol_version)
        if message is not None:
            self._attributes[attr] = value
            setattr(message, str(attr), value)
            if attr == DeviceAttributes.leak_water_protection_value:
                current_protection = self._attributes.get(
                    DeviceAttributes.leak_water_protection,
                )
                if current_protection is not None:
                    setattr(
                        message,
                        str(DeviceAttributes.leak_water_protection),
                        current_protection,
                    )
            if attr == DeviceAttributes.timing_regeneration_hour:
                current_min = self._attributes.get(
                    DeviceAttributes.timing_regeneration_min,
                )
                if current_min is not None:
                    setattr(
                        message,
                        str(DeviceAttributes.timing_regeneration_min),
                        current_min,
                    )
            if attr == DeviceAttributes.timing_regeneration_min:
                current_hour = self._attributes.get(
                    DeviceAttributes.timing_regeneration_hour,
                )
                if current_hour is not None:
                    setattr(
                        message,
                        str(DeviceAttributes.timing_regeneration_hour),
                        current_hour,
                    )
            self.build_send(message)


class MideaAppliance(MideaEDDevice):
    """Midea ED appliance."""
