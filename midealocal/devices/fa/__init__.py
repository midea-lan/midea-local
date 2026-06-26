"""Midea local FA device."""

import json
import logging
from enum import StrEnum
from typing import Any, ClassVar

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.device import MideaDevice

from .message import MessageFAResponse, MessageNewSet, MessageQuery, MessageSet

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Midea FA device attributes."""

    power = "power"
    child_lock = "child_lock"
    mode = "mode"
    fan_speed = "fan_speed"
    oscillate = "oscillate"
    oscillation_angle = "oscillation_angle"
    tilting_angle = "tilting_angle"
    oscillation_mode = "oscillation_mode"
    voice = "voice"
    error_code = "error_code"
    scene = "scene"
    humidify = "humidify"
    auto_power_off = "auto_power_off"
    target_temerature = "target_temerature"
    target_humidity = "target_humidity"
    humidity = "humidity"
    anophelifuge = "anophelifuge"
    anion = "anion"
    humidify_feedback = "humidify_feedback"
    temperature_feedback = "temperature_feedback"
    body_feeling_scan = "body_feeling_scan"


class MideaFADevice(MideaDevice):
    """Midea FA device."""

    _oscillation_angles: ClassVar[dict[int, str]] = {
        0x00: "Off",
        0x01: "30",
        0x02: "60",
        0x03: "90",
        0x04: "120",
        0x05: "180",
        0x06: "360",
    }

    _tilting_angles: ClassVar[dict[int, str]] = {
        0x00: "Off",
        0x01: "30",
        0x02: "60",
        0x03: "90",
        0x04: "120",
        0x05: "180",
        0x06: "360",
        0x07: "+60",
        0x08: "-60",
        0x09: "40",
    }

    _oscillation_modes: ClassVar[dict[int, str]] = {
        0x00: "invalid",
        0x01: "Oscillation",
        0x02: "Tilting",
        0x03: "Curve-W",
        0x04: "Curve-8",
        0x05: "invalid",
        0x06: "Both",
        0x07: "custom",
    }

    _voice: ClassVar[dict[int, str]] = {
        0x00: "invalid",
        0x01: "open_gps",
        0x02: "close_gps",
        0x03: "invalid",
        0x04: "open_buzzer",
        0x05: "open_tips",
        0x08: "close_buzzer",
        0x0A: "mute",
    }

    _humidify: ClassVar[dict[int, str]] = {
        0x01: "off",
        0x02: "no_change",
        0x03: "1",
        0x04: "2",
        0x05: "3",
        0x00: "invalid",
    }

    _modes: ClassVar[dict[int, str]] = {
        0x00: "Invalid",
        0x01: "Normal",
        0x02: "Natural",
        0x03: "Sleep",
        0x04: "Comfort",
        0x05: "Mute",
        0x06: "Baby",
        0x07: "Feel",
        0x08: "Storm",
        0x09: "Strong",
        0x0A: "Soft",
        0x0B: "Customize",
        0x0C: "Warm",
        0x0D: "Smart",
        0x0E: "Ionic",
        0x0F: "AI_Smart",
        0x10: "Double_Area",
        0x11: "Purified_Wind",
        0x12: "Sleeping_Wind",
        0x13: "Purify_Only",
        0x14: "Self_Selection",
    }

    _scene: ClassVar[dict[int, str]] = {
        0x00: "None",
        0x01: "Old",
        0x02: "Child",
        0x03: "Read",
        0x04: "Sleep",
        0x05: "AC",
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
        """Initialize Midea FA device."""
        super().__init__(
            name=name,
            device_id=device_id,
            device_type=DeviceType.FA,
            ip_address=ip_address,
            port=port,
            token=token,
            key=key,
            device_protocol=device_protocol,
            model=model,
            subtype=subtype,
            attributes={
                DeviceAttributes.power: False,
                DeviceAttributes.child_lock: False,
                DeviceAttributes.mode: 0,
                DeviceAttributes.fan_speed: 0,
                DeviceAttributes.oscillate: False,
                DeviceAttributes.oscillation_angle: None,
                DeviceAttributes.tilting_angle: None,
                DeviceAttributes.oscillation_mode: None,
                DeviceAttributes.voice: None,
                DeviceAttributes.error_code: None,
                DeviceAttributes.scene: None,
                DeviceAttributes.humidify: None,
                DeviceAttributes.auto_power_off: None,
                DeviceAttributes.target_temerature: None,
                DeviceAttributes.target_humidity: None,
                DeviceAttributes.humidity: None,
                DeviceAttributes.anophelifuge: None,
                DeviceAttributes.anion: None,
                DeviceAttributes.humidify_feedback: None,
                DeviceAttributes.temperature_feedback: None,
                DeviceAttributes.body_feeling_scan: None,
                DeviceAttributes.humidify_feedback: None,
            },
        )
        self._default_speed_count = 3
        self._speed_count: int = self._default_speed_count
        self.fa_protocol: int = 0
        self.set_customize(customize)

    @property
    def speed_count(self) -> int:
        """Return the speed count of the device."""
        return self._speed_count

    @property
    def oscillation_angles(self) -> list[str]:
        """Return the list of possible oscillation angles."""
        return list(MideaFADevice._oscillation_angles.values())

    @property
    def tilting_angles(self) -> list[str]:
        """Return the list of possible tilting angles."""
        return list(MideaFADevice._tilting_angles.values())

    @property
    def oscillation_modes(self) -> list[str]:
        """Return a list of available oscillation modes."""
        return list(MideaFADevice._oscillation_modes.values())

    @property
    def preset_modes(self) -> list[str]:
        """Return a list of preset modes."""
        return list(MideaFADevice._modes.values())

    def build_query(self) -> list[MessageQuery]:
        """Midea FA device build query."""
        return [MessageQuery(self._message_protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea FA device process message."""
        message = MessageFAResponse(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        # check fa_message_protocol v5, default is 0
        self.fa_protocol = getattr(message, "fa_message_protocol", 0)
        new_status = {}
        for attr in self._attributes:
            if hasattr(message, str(attr)):
                value = getattr(message, str(attr))
                # oscillation_angles
                if attr == DeviceAttributes.oscillation_angle:
                    if self.fa_protocol:
                        self._attributes[attr] = int(value * 5)
                    else:
                        self._attributes[attr] = MideaFADevice._oscillation_angles.get(
                            value,
                            value,
                        )
                # tilting_angle
                elif attr == DeviceAttributes.tilting_angle:
                    if self.fa_protocol:
                        self._attributes[attr] = int(value * 5)
                    else:
                        self._attributes[attr] = MideaFADevice._tilting_angles.get(
                            value,
                            value,
                        )
                # oscillation_mode
                elif attr == DeviceAttributes.oscillation_mode:
                    self._attributes[attr] = MideaFADevice._oscillation_modes.get(
                        value,
                        value,
                    )
                # modes
                elif attr == DeviceAttributes.mode:
                    self._attributes[attr] = MideaFADevice._modes.get(
                        value,
                        value,
                    )
                # humidify
                elif attr == DeviceAttributes.humidify:
                    self._attributes[attr] = MideaFADevice._humidify.get(
                        value,
                        value,
                    )
                # scene
                elif attr == DeviceAttributes.scene:
                    self._attributes[attr] = MideaFADevice._scene.get(
                        value,
                        value,
                    )
                # voice
                elif attr == DeviceAttributes.voice:
                    self._attributes[attr] = MideaFADevice._voice.get(
                        value,
                        value,
                    )
                elif attr == DeviceAttributes.power:
                    self._attributes[attr] = value
                    if not value:
                        self._attributes[DeviceAttributes.fan_speed] = 0
                elif (
                    attr == DeviceAttributes.fan_speed
                    and not self._attributes[DeviceAttributes.power]
                ):
                    self._attributes[attr] = 0
                else:
                    self._attributes[attr] = value
                new_status[str(attr)] = self._attributes[attr]
        return new_status

    def _set_oscillation_mode(self, message: MessageSet, value: str) -> None:
        if value == "Off" or not value:
            message.oscillate = False
        else:
            message.oscillate = True
            message.oscillation_mode = MideaFADevice.get_dict_key_by_value(
                "_oscillation_modes",
                value,
            )
            if value == "Oscillation":
                if self._attributes[DeviceAttributes.oscillation_angle] == "Off":
                    message.oscillation_angle = MideaFADevice.get_dict_key_by_value(
                        "_oscillation_angles",
                        "90",
                    )  # 90
                else:
                    message.oscillation_angle = MideaFADevice.get_dict_key_by_value(
                        "_oscillation_angles",
                        self._attributes[DeviceAttributes.oscillation_angle],
                    )
            elif value == "Tilting":
                if self._attributes[DeviceAttributes.tilting_angle] == "Off":
                    message.tilting_angle = MideaFADevice.get_dict_key_by_value(
                        "_tilting_angles",
                        "90",
                    )  # 90
                else:
                    message.tilting_angle = MideaFADevice.get_dict_key_by_value(
                        "_tilting_angles",
                        self._attributes[DeviceAttributes.tilting_angle],
                    )
            else:
                if self._attributes[DeviceAttributes.oscillation_angle] == "Off":
                    message.oscillation_angle = MideaFADevice.get_dict_key_by_value(
                        "_oscillation_angles",
                        "90",
                    )  # 90
                else:
                    message.oscillation_angle = MideaFADevice.get_dict_key_by_value(
                        "_oscillation_angles",
                        self._attributes[DeviceAttributes.oscillation_angle],
                    )
                if self._attributes[DeviceAttributes.tilting_angle] == "Off":
                    message.tilting_angle = MideaFADevice.get_dict_key_by_value(
                        "_tilting_angles",
                        "90",
                    )  # 90
                else:
                    message.tilting_angle = MideaFADevice.get_dict_key_by_value(
                        "_tilting_angles",
                        self._attributes[DeviceAttributes.tilting_angle],
                    )

    def _set_oscillation_angle(self, message: MessageSet, value: str) -> None:
        if value == "Off" or not value:
            if self._attributes[DeviceAttributes.tilting_angle] == "Off":
                message.oscillate = False
            else:
                message.oscillate = True
                message.oscillation_mode = MideaFADevice.get_dict_key_by_value(
                    "_oscillation_modes",
                    "Tilting",
                )  # Tilting
                message.tilting_angle = MideaFADevice.get_dict_key_by_value(
                    "_tilting_angles",
                    self._attributes[DeviceAttributes.tilting_angle],
                )
        else:
            message.oscillation_angle = MideaFADevice.get_dict_key_by_value(
                "_oscillation_angles",
                value,
            )
            message.oscillate = True
            if self._attributes[DeviceAttributes.tilting_angle] == "Off":
                message.oscillation_mode = MideaFADevice.get_dict_key_by_value(
                    "_oscillation_modes",
                    "Oscillation",
                )  # Oscillation
            elif self._attributes[DeviceAttributes.oscillation_mode] == "Tilting":
                message.oscillation_mode = MideaFADevice.get_dict_key_by_value(
                    "_oscillation_modes",
                    "Both",
                )  # Both
                message.tilting_angle = MideaFADevice.get_dict_key_by_value(
                    "_tilting_angles",
                    self._attributes[DeviceAttributes.tilting_angle],
                )

    def _set_tilting_angle(self, message: MessageSet, value: str) -> None:
        if value == "Off" or not value:
            if self._attributes[DeviceAttributes.oscillation_angle] == "Off":
                message.oscillate = False
            else:
                message.oscillate = True
                message.oscillation_mode = message.oscillation_mode = (
                    MideaFADevice.get_dict_key_by_value(
                        "_oscillation_modes",
                        "Oscillation",
                    )
                )  # Oscillation
                message.oscillation_angle = MideaFADevice.get_dict_key_by_value(
                    "_oscillation_angles",
                    self._attributes[DeviceAttributes.oscillation_angle],
                )
        else:
            message.tilting_angle = MideaFADevice.get_dict_key_by_value(
                "_tilting_angles",
                value,
            )
            message.oscillate = True
            if self._attributes[DeviceAttributes.oscillation_angle] == "Off":
                message.oscillation_mode = MideaFADevice.get_dict_key_by_value(
                    "_oscillation_modes",
                    "Tilting",
                )  # Tilting
            elif self._attributes[DeviceAttributes.oscillation_mode] == "Oscillation":
                message.oscillation_mode = MideaFADevice.get_dict_key_by_value(
                    "_oscillation_modes",
                    "Both",
                )  # Both
                message.oscillation_angle = MideaFADevice.get_dict_key_by_value(
                    "_oscillation_angles",
                    self._attributes[DeviceAttributes.oscillation_angle],
                )

    def set_oscillation(self, attr: str, value: int | str | bool) -> MessageSet | None:
        """Set oscillation mode."""
        message: MessageSet | None = None
        if self._attributes[attr] != value:
            if attr == DeviceAttributes.oscillate:
                message = MessageSet(self._message_protocol_version, self.subtype)
                message.oscillate = bool(value)
                if value:
                    message.oscillation_angle = MideaFADevice.get_dict_key_by_value(
                        "_oscillation_angles",
                        "90",
                    )  # default is 90
                    message.oscillation_mode = MideaFADevice.get_dict_key_by_value(
                        "_oscillation_modes",
                        "Oscillation",
                    )  # Oscillation
            elif attr == DeviceAttributes.oscillation_mode and (
                value in MideaFADevice._oscillation_modes.values()
            ):
                message = MessageSet(self._message_protocol_version, self.subtype)
                self._set_oscillation_mode(message, str(value))
            elif attr == DeviceAttributes.oscillation_angle and (
                value in MideaFADevice._oscillation_angles or not value
            ):
                message = MessageSet(self._message_protocol_version, self.subtype)
                self._set_oscillation_angle(message, str(value))
            elif attr == DeviceAttributes.tilting_angle and (
                value in MideaFADevice._tilting_angles or not value
            ):
                message = MessageSet(self._message_protocol_version, self.subtype)
                self._set_tilting_angle(message, str(value))
        return message

    def set_new_oscillation(
        self,
        attr: str,
        value: int | str | bool,
    ) -> MessageNewSet | None:
        """Set oscillation mode."""
        message: MessageNewSet | None = None
        if self._attributes[attr] != value:
            if attr == DeviceAttributes.oscillate:
                message = MessageNewSet(self._message_protocol_version, self.subtype)
                message.oscillate = bool(value)
                if value:
                    message.oscillation_angle = MideaFADevice.get_dict_key_by_value(
                        "_oscillation_angles",
                        "90",
                    )  # default is 90
                    message.oscillation_mode = MideaFADevice.get_dict_key_by_value(
                        "_oscillation_modes",
                        "Oscillation",
                    )  # Oscillation
            elif (
                attr == DeviceAttributes.oscillation_mode
                and (value in MideaFADevice._oscillation_modes.values())
                or attr == DeviceAttributes.oscillation_angle
                and (value in MideaFADevice._oscillation_angles or not value)
                or attr == DeviceAttributes.tilting_angle
                and (value in MideaFADevice._tilting_angles or not value)
            ):
                message = MessageNewSet(self._message_protocol_version, self.subtype)
                # to be done self._set_tilting_angle(message, str(value))
        return message

    def set_attribute(self, attr: str, value: bool | int | str) -> None:
        """Set attribute."""
        _LOGGER.debug(
            "[%s] set_attribute attr %s, value %s, fa_protocol %s, self %s",
            self.device_id,
            attr,
            value,
            self.fa_protocol,
            self,
        )
        message: MessageNewSet | MessageSet | None = None
        if attr in [
            DeviceAttributes.oscillate,
            DeviceAttributes.oscillation_mode,
            DeviceAttributes.oscillation_angle,
            DeviceAttributes.tilting_angle,
        ]:
            if self.fa_protocol:
                message = self.set_new_oscillation(attr, value)
            else:
                message = self.set_oscillation(attr, value)
        elif (
            attr == DeviceAttributes.fan_speed
            and int(value) > 0
            and not self._attributes[DeviceAttributes.power]
        ):
            message = MessageSet(self._message_protocol_version, self.subtype)
            message.fan_speed = int(value)
            message.power = True
        elif attr == DeviceAttributes.mode:
            if value in MideaFADevice._modes:
                message = MessageSet(self._message_protocol_version, self.subtype)
                message.mode = MideaFADevice.get_dict_key_by_value("_modes", str(value))
        elif not (attr == DeviceAttributes.fan_speed and value == 0):
            message = MessageSet(self._message_protocol_version, self.subtype)
            setattr(message, str(attr), value)
        if message is not None:
            self.build_send(message)

    def turn_on(self, fan_speed: int | None = None, mode: str | None = None) -> None:
        """Turn on the device."""
        message = MessageSet(self._message_protocol_version, self.subtype)
        message.power = True
        if fan_speed is not None:
            message.fan_speed = fan_speed
        if mode is None:
            message.mode = mode
        self.build_send(message)

    def set_customize(self, customize: str) -> None:
        """Set customize."""
        self._speed_count = self._default_speed_count
        if customize and len(customize) > 0:
            try:
                params = json.loads(customize)
                if params and "speed_count" in params:
                    self._speed_count = params.get("speed_count")
            except Exception:
                _LOGGER.exception("[%s] Set customize error", self.device_id)
            self.update_all({"speed_count": self._speed_count})


class MideaAppliance(MideaFADevice):
    """Midea appliance device."""
