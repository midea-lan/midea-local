"""Midea local CF device."""

import logging
import math
from enum import StrEnum
from typing import Any, Unpack

from midealocal.const import DeviceType
from midealocal.device import MideaDevice, MideaDeviceInitKwargs
from midealocal.exceptions import ValueWrongType

from .message import MessageCFResponse, MessageQuery, MessageSet

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Midea CF device attributes."""

    power = "power"
    mode = "mode"
    target_temperature = "target_temperature"
    aux_heating = "aux_heating"
    current_temperature = "current_temperature"
    max_temperature = "max_temperature"
    min_temperature = "min_temperature"
    defrost = "defrost"
    freeze = "freeze"


class MideaCFDevice(MideaDevice):
    """Midea CF device."""

    def __init__(
        self,
        *,
        customize: str,  # noqa: ARG002
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Midea CF device."""
        super().__init__(
            device_type=DeviceType.CF,
            **kwargs,
            attributes={
                DeviceAttributes.power: False,
                DeviceAttributes.mode: 0,
                DeviceAttributes.defrost: False,
                DeviceAttributes.freeze: False,
                DeviceAttributes.target_temperature: None,
                DeviceAttributes.aux_heating: False,
                DeviceAttributes.current_temperature: 0,
                DeviceAttributes.max_temperature: 55,
                DeviceAttributes.min_temperature: 5,
            },
        )

    def build_query(self) -> list[MessageQuery]:
        """Midea CF device build query."""
        return [MessageQuery(self._message_protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea CF device process message."""
        message = MessageCFResponse(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        new_status = {}
        for status in self._attributes:
            if hasattr(message, str(status)):
                self._attributes[status] = getattr(message, str(status))
                new_status[str(status)] = getattr(message, str(status))
        return new_status

    def set_target_temperature(
        self,
        target_temperature: float,
        mode: int | None,
        zone: int | None = None,  # noqa: ARG002
    ) -> None:
        """Midea CF device set target temperature."""
        message = MessageSet(self._message_protocol_version)
        message.power = True
        message.mode = self._attributes[DeviceAttributes.mode]
        message.target_temperature = target_temperature
        if mode is not None:
            message.mode = mode
        self.build_send(message)

    @staticmethod
    def _parse_float(value: bool | float | str, expected: str) -> float:
        if isinstance(value, bool):
            raise ValueWrongType(f"[cf] Expected {expected}")
        try:
            number = float(value)
        except (TypeError, ValueError) as err:
            raise ValueWrongType(f"[cf] Expected {expected}") from err
        if not math.isfinite(number):
            raise ValueWrongType(f"[cf] Expected {expected}")
        return number

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea CF device set attribute."""
        message = MessageSet(self._message_protocol_version)
        message.power = True
        message.mode = self._attributes[DeviceAttributes.mode]
        if attr in (DeviceAttributes.power, DeviceAttributes.aux_heating):
            if not isinstance(value, bool):
                raise ValueWrongType("[cf] Expected bool")
            setattr(message, attr, value)
        elif attr == DeviceAttributes.mode:
            mode_value = self._parse_float(value, "int")
            if not mode_value.is_integer():
                raise ValueWrongType("[cf] Expected int")
            message.mode = int(mode_value)
        elif attr == DeviceAttributes.target_temperature:
            message.target_temperature = self._parse_float(value, "float")
        else:
            raise ValueError(f"[cf] Unsupported attribute: {attr}")
        self.build_send(message)


class MideaAppliance(MideaCFDevice):
    """Midea CF appliance."""
