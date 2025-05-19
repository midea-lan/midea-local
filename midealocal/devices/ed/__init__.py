"""Midea local ED device."""

import logging
from enum import StrEnum
from typing import Any

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.device import MideaDevice
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


class MideaEDDevice(MideaDevice):
    """Midea ED device."""

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
        customize: str,  # noqa: ARG002
    ) -> None:
        """Initialize Midea ED device."""
        super().__init__(
            name=name,
            device_id=device_id,
            device_type=DeviceType.ED,
            ip_address=ip_address,
            port=port,
            token=token,
            key=key,
            device_protocol=device_protocol,
            model=model,
            subtype=subtype,
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
        | MessageQueryFF
    ]:
        """Midea ED device build query."""
        # device can response for MessageQuery/MessageQuery01/MessageQuery03/etc
        # and only MessageQuery01 can return non-zero value.
        if self.subtype in [309, 310, 311, 313, 314, 315, 317, 330]:
            return [
                MessageQuery04(self._message_protocol_version),
            ]
        if self.subtype in [316, 318, 319, 320]:
            return [
                MessageQuery05(self._message_protocol_version),
            ]
        if self.subtype in [290, 331, 332, 340]:
            return [
                MessageQuery06(self._message_protocol_version),
            ]
        if self.subtype in [288, 307, 329, 349]:
            return [
                MessageQuery07(self._message_protocol_version),
            ]
        # for https://github.com/wuwentao/midea_ac_lan/issues/571
        # subtype 775 only can got non-zero value with MessageQuery01
        # more subtypes should using MessageQuery01, temp keep it in else
        # remove MessageQuery03 as it return 0
        # subtype 775
        if self.subtype in [775]:
            return [
                MessageQuery01(self._message_protocol_version),
            ]
        return [
            MessageQuery(self._message_protocol_version),
            MessageQuery01(self._message_protocol_version),
            MessageQueryFF(self._message_protocol_version),
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

    def set_attribute(self, attr: str, value: bool | int | str) -> None:
        """Midea ED device set attribute."""
        message: MessageNewSet | MessageOldSet | None = None
        if self._use_new_set():
            if attr in [DeviceAttributes.power, DeviceAttributes.child_lock]:
                message = MessageNewSet(self._message_protocol_version)
        elif attr in []:
            message = MessageOldSet(self._message_protocol_version)
        if message is not None:
            setattr(message, str(attr), value)
            self.build_send(message)


class MideaAppliance(MideaEDDevice):
    """Midea ED appliance."""
