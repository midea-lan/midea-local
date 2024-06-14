import json
import logging
import sys
from typing import Any, ClassVar

from .message import Message13Response, MessageQuery, MessageSet

if sys.version_info < (3, 12):
    from midealocal.backports.enum import StrEnum
else:
    from enum import StrEnum

from midealocal.device import MideaDevice

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    brightness = "brightness"
    color_temperature = "color_temperature"
    rgb_color = "rgb_color"
    effect = "effect"
    power = "power"


class Midea13Device(MideaDevice):
    _effects: ClassVar[list[str]] = [
        "Manual",
        "Living",
        "Reading",
        "Mildly",
        "Cinema",
        "Night",
    ]

    def __init__(
        self,
        name: str,
        device_id: int,
        ip_address: str,
        port: int,
        token: str,
        key: str,
        protocol: int,
        model: str,
        subtype: int,
        customize: str,
    ) -> None:
        super().__init__(
            name=name,
            device_id=device_id,
            device_type=0x13,
            ip_address=ip_address,
            port=port,
            token=token,
            key=key,
            protocol=protocol,
            model=model,
            subtype=subtype,
            attributes={
                DeviceAttributes.brightness: None,
                DeviceAttributes.color_temperature: None,
                DeviceAttributes.rgb_color: None,
                DeviceAttributes.effect: None,
                DeviceAttributes.power: False,
            },
        )
        self._color_temp_range: list[int] = []
        self._default_color_temp_range: list[int] = [2700, 6500]
        self.set_customize(customize)

    @property
    def effects(self) -> list[str]:
        return Midea13Device._effects

    @property
    def color_temp_range(self) -> list[int]:
        return self._color_temp_range

    def kelvin_to_midea(self, kelvin: int) -> float:
        return round(
            (kelvin - self._color_temp_range[0])
            / (self._color_temp_range[1] - self._color_temp_range[0])
            * 255,
        )

    def midea_to_kelvin(self, midea: int) -> float:
        return (
            round((self._color_temp_range[1] - self._color_temp_range[0]) / 255 * midea)
            + self._color_temp_range[0]
        )

    def build_query(self) -> list[MessageQuery]:
        return [MessageQuery(self._protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        message = Message13Response(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        new_status: dict[str, Any] = {}
        if hasattr(message, "control_success"):
            new_status = {"control_success": message.control_success}
            if message.control_success:
                self.refresh_status()
        else:
            for status in self._attributes:
                if hasattr(message, str(status)):
                    value = getattr(message, str(status))
                    if status == DeviceAttributes.effect:
                        self._attributes[status] = Midea13Device._effects[value]
                    elif status == DeviceAttributes.color_temperature:
                        self._attributes[status] = self.midea_to_kelvin(value)
                    else:
                        self._attributes[status] = value
                    new_status[str(status)] = self._attributes[status]
        return new_status

    def set_attribute(self, attr: str, value: Any) -> None:
        if attr in [
            DeviceAttributes.brightness,
            DeviceAttributes.color_temperature,
            DeviceAttributes.effect,
            DeviceAttributes.power,
        ]:
            message = MessageSet(self._protocol_version)
            if attr == DeviceAttributes.effect and value in self._effects:
                setattr(message, str(attr), Midea13Device._effects.index(value))
            elif attr == DeviceAttributes.color_temperature:
                setattr(message, str(attr), self.kelvin_to_midea(value))
            else:
                setattr(message, str(attr), value)
            self.build_send(message)

    def set_customize(self, customize: str) -> None:
        self._color_temp_range = self._default_color_temp_range
        if customize and len(customize) > 0:
            try:
                params = json.loads(customize)
                if params and "color_temp_range_kelvin" in params:
                    self._color_temp_range = params.get("color_temp_range_kelvin")
            except Exception as e:
                _LOGGER.error("[%s] Set customize error: %s", self.device_id, repr(e))
            self.update_all({"color_temp_range": self._color_temp_range})


class MideaAppliance(Midea13Device):
    pass
