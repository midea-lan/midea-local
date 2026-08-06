"""Midea local ED device."""

import logging
from enum import StrEnum
from typing import Any, Unpack

from midealocal.const import DeviceType
from midealocal.device import MideaDevice, MideaDeviceInitKwargs
from midealocal.message import ListTypes

from .message import (
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
            **dict.fromkeys([290, 331, 332, 340], MessageQuery06),
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
        message = MessageEDResponse(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        new_status = {}
        if hasattr(message, "device_class"):
            self._device_class = message.device_class
        for status in self._attributes:
            if hasattr(message, str(status)):
                new_status[str(status)] = getattr(message, str(status))
                self._attributes[status] = getattr(message, str(status))
        return new_status

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea ED device set attribute."""
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
