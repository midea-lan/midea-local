"""Midea local AD device."""

import logging
from enum import StrEnum
from typing import Any

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.device import MideaDevice

from .message import Message21Query, Message31Query, MessageADResponse

_LOGGER = logging.getLogger(__name__)

STANDBY_DETECT_LENGTH = 2


class DeviceAttributes(StrEnum):
    """Midea AD device attributes."""

    temperature = "temperature"
    humidity = "humidity"
    tvoc = "tvoc"
    co2 = "co2"
    pm25 = "pm25"
    hcho = "hcho"
    presets_function = "presets_function"
    fall_asleep_status = "fall_asleep_status"
    portable_sense = "portable_sense"
    night_mode = "night_mode"
    screen_extinction_timeout = "screen_extinction_timeout"
    screen_status = "screen_status"
    led_status = "led_status"
    arofene_link = "arofene_link"
    header_exist = "header_exist"
    radar_exist = "radar_exist"
    header_led_status = "header_led_status"
    temperature_raw = "temperature_raw"
    humidity_raw = "humidity_raw"
    temperature_compensate = "temperature_compensate"
    humidity_compensate = "humidity_compensate"


class MideaADDevice(MideaDevice):
    """Midea AD device."""

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
        """Initialize Midea AD device."""
        super().__init__(
            name=name,
            device_id=device_id,
            device_type=DeviceType.AD,
            ip_address=ip_address,
            port=port,
            token=token,
            key=key,
            device_protocol=device_protocol,
            model=model,
            subtype=subtype,
            attributes={
                DeviceAttributes.temperature: None,
                DeviceAttributes.humidity: None,
                DeviceAttributes.tvoc: None,
                DeviceAttributes.co2: None,
                DeviceAttributes.pm25: None,
                DeviceAttributes.hcho: None,
                DeviceAttributes.presets_function: False,
                DeviceAttributes.fall_asleep_status: False,
                DeviceAttributes.portable_sense: False,
                DeviceAttributes.night_mode: False,
                DeviceAttributes.screen_extinction_timeout: None,
                DeviceAttributes.screen_status: False,
                DeviceAttributes.led_status: False,
                DeviceAttributes.arofene_link: False,
                DeviceAttributes.header_exist: False,
                DeviceAttributes.radar_exist: False,
                DeviceAttributes.header_led_status: False,
                DeviceAttributes.temperature_raw: None,
                DeviceAttributes.humidity_raw: None,
                DeviceAttributes.temperature_compensate: None,
                DeviceAttributes.humidity_compensate: None,
            },
        )

    def build_query(self) -> list[Message21Query | Message31Query]:
        """Midea AD device build query."""
        return [
            Message21Query(self._message_protocol_version),
            Message31Query(self._message_protocol_version),
        ]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea AD device process message."""
        message = MessageADResponse(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        new_status = {}
        for status in self._attributes:
            if hasattr(message, str(status)):
                value = getattr(message, str(status))
                self._attributes[status] = value
                new_status[str(status)] = self._attributes[status]
        return new_status

    def set_attribute(self, attr: str, value: bool | int | str) -> None:
        """Midea AD device set attribute."""

    def set_customize(self, customize: str) -> None:
        """Midea AD device set customize."""


class MideaAppliance(MideaADDevice):
    """Midea AD appliance."""
