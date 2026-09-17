"""Midea Local shared base classes test."""

from collections.abc import Mapping
from typing import cast

import pytest

from midealocal.base_classes.climate import (
    DEFAULT_MAX_TARGET_TEMPERATURE,
    DEFAULT_MIN_TARGET_TEMPERATURE,
    MideaClimateDevice,
    MideaFanMode,
    MideaHVACMode,
    MideaPreset,
    MideaSwingMode,
)
from midealocal.const import DeviceType, ProtocolVersion


class _MinimalClimateDevice(MideaClimateDevice):
    """A climate device overriding only the mandatory members."""

    @property
    def hvac_modes(self) -> set[MideaHVACMode]:
        return {DummyHVACMode.OFF, DummyHVACMode.AUTO}

    def hvac_mode(self, zone: int | None = None) -> MideaHVACMode | None:  # noqa: ARG002
        return DummyHVACMode.AUTO

    def set_hvac_mode(
        self,
        hvac_mode: MideaHVACMode,
        zone: int | None = None,  # noqa: ARG002
    ) -> None:
        self._attributes["hvac_mode"] = hvac_mode

    def set_target_temperature(
        self,
        target_temperature: float,
        hvac_mode: MideaHVACMode | None,
        zone: int | None = None,  # noqa: ARG002
    ) -> None:
        self._attributes["target_temperature"] = target_temperature
        if hvac_mode is not None:
            self._attributes["hvac_mode"] = hvac_mode

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        self._attributes[attr] = value

    def current_temperature(self) -> float | None:
        return cast("float | None", self._attributes.get("current_temperature"))

    def target_temperature(self, zone: int | None = None) -> float | None:  # noqa: ARG002
        return cast("float | None", self._attributes.get("target_temperature"))

    def turn_on(self, zone: int | None = None) -> None:  # noqa: ARG002
        self._attributes["power"] = True

    def turn_off(self, zone: int | None = None) -> None:  # noqa: ARG002
        self._attributes["power"] = False

    def current_humidity(self) -> float | None:
        return cast("float | None", self._attributes.get("current_humidity"))


class _FlagPresetClimateDevice(_MinimalClimateDevice):
    """A climate device using the shared flag-style preset implementation."""

    @property
    def _preset_attributes(self) -> Mapping[MideaPreset, str]:
        return {
            MideaPreset.ECO: "eco_mode",
            MideaPreset.SLEEP: "sleep_mode",
        }


class DummyFanMode(MideaFanMode):
    """Test dummy fan mode."""

    OFF = 0
    ON = 1
    INVALID = 99


class DummySwingMode(MideaSwingMode):
    """Test dummy swing mode."""

    OFF = "off"
    ON = "on"
    INVALID = "invalid"


class DummyHVACMode(MideaHVACMode):
    """Test dummy swing mode."""

    OFF = 0
    AUTO = 1
    INVALID = 99


class TestMideaClimateDevice:
    """Test the shared climate device base class defaults."""

    device: _MinimalClimateDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Minimal climate device setup."""
        self.device = _MinimalClimateDevice(
            device_type=DeviceType.AC,
            attributes={},
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.1",
            port=12345,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model="test_model",
            subtype=1,
        )

    def test_fan_capability_defaults_to_unsupported(self) -> None:
        """Test fan_modes/fan_mode default to None and set_fan_mode raises."""
        assert self.device.raw_fan_modes is not None
        assert len(self.device.raw_fan_modes) == 0
        assert self.device.raw_fan_mode is None
        with pytest.raises(ValueError, match="Unsupported fan mode"):
            self.device.set_raw_fan_mode("auto")
        with pytest.raises(NotImplementedError, match="Fan mode"):
            self.device.set_fan_mode(DummyFanMode.OFF)

    def test_swing_capability_defaults_to_unsupported(self) -> None:
        """Test swing_modes/swing_mode default to None and set_swing_mode raises."""
        assert self.device.raw_swing_modes is not None
        assert len(self.device.raw_swing_modes) == 0
        assert self.device.raw_swing_mode is None
        with pytest.raises(ValueError, match="Unsupported swing mode"):
            self.device.set_raw_swing_mode("on")
        with pytest.raises(NotImplementedError, match="Swing mode"):
            self.device.set_swing_mode(DummySwingMode.OFF)

    def test_temperature_step_defaults_to_none(self) -> None:
        """Test temperature_step defaults to None."""
        assert self.device.temperature_step is None

    def test_target_temperature_bounds_default(self) -> None:
        """Test min/max target temperature fall back to the shared defaults."""
        assert self.device.min_temperature() == DEFAULT_MIN_TARGET_TEMPERATURE
        assert self.device.max_temperature() == DEFAULT_MAX_TARGET_TEMPERATURE
        # the zone argument is accepted and ignored by the default implementation
        assert self.device.min_temperature(zone=1) == DEFAULT_MIN_TARGET_TEMPERATURE

    def test_preset_capability_defaults_to_unsupported(self) -> None:
        """Test preset_modes/preset_mode default to empty/None and setting raises."""
        assert list(self.device.preset_modes) == []
        assert self.device.preset_mode is None
        with pytest.raises(NotImplementedError, match="Preset mode"):
            self.device.set_preset_mode("eco")

    def test_flag_style_presets(self) -> None:
        """Test the shared flag-style preset read/write via _preset_attributes."""
        device = _FlagPresetClimateDevice(
            device_type=DeviceType.AC,
            attributes={"eco_mode": False, "sleep_mode": False},
            name="Test Device",
            device_id=3,
            ip_address="192.168.1.3",
            port=12345,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model="test_model",
            subtype=1,
        )

        assert list(device.preset_modes) == ["none", "eco", "sleep"]
        assert device.preset_mode == "none"

        device.set_preset_mode("eco")
        assert device.get_attribute("eco_mode") is True
        assert device.preset_mode == "eco"

        # switching preset clears the previous flag
        device.set_preset_mode("none")
        assert device.get_attribute("eco_mode") is False
        assert device.preset_mode == "none"

        # clearing again with nothing active is a no-op
        device.set_preset_mode("none")
        assert device.preset_mode == "none"

        # a name outside MideaPreset entirely is rejected
        with pytest.raises(ValueError, match="Unsupported preset mode: bogus"):
            device.set_preset_mode("bogus")

        # a MideaPreset this device doesn't support is also rejected
        with pytest.raises(ValueError, match="Unsupported preset mode: boost"):
            device.set_preset_mode("boost")
        assert device.preset_mode == "none"

        # switching directly between two presets (skipping "none") normalizes
        # every flag, not just the one set_attribute() was called with --
        # set_attribute() alone doesn't know to clear the other preset's flag
        device.set_preset_mode("eco")
        device.set_preset_mode("sleep")
        assert device.preset_mode == "sleep"
        assert device.get_attribute("eco_mode") is False
        assert device.get_attribute("sleep_mode") is True

        # and an immediate clear right after activating reads back correctly,
        # since set_preset_mode() -- not set_attribute() -- caches the change
        device.set_preset_mode("none")
        assert device.preset_mode == "none"
        assert device.get_attribute("sleep_mode") is False

    def test_clear_preset_with_two_flags_active(self) -> None:
        """Clearing disables every active flag, not just the first one found.

        Real device state shouldn't have two preset flags active at once,
        but if it ever does (a stale read, a wire quirk), preset_mode()
        would only report one of them -- clearing must not stop there and
        leave the other stuck on.
        """
        device = _FlagPresetClimateDevice(
            device_type=DeviceType.AC,
            attributes={"eco_mode": True, "sleep_mode": True},
            name="Test Device",
            device_id=4,
            ip_address="192.168.1.4",
            port=12345,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model="test_model",
            subtype=1,
        )

        device.set_preset_mode("none")
        assert device.get_attribute("eco_mode") is False
        assert device.get_attribute("sleep_mode") is False
        assert device.preset_mode == "none"

    def test_mandatory_members_must_be_overridden(self) -> None:
        """Test a subclass missing a mandatory member can't be instantiated.

        hvac_modes/hvac_mode/set_hvac_mode/set_target_temperature have no
        sensible default, so they're abstract: a subclass that forgets one
        fails at instantiation, not only when that code path is exercised.
        """
        with pytest.raises(TypeError, match="abstract"):
            MideaClimateDevice(  # type: ignore[abstract]
                device_type=DeviceType.AC,
                attributes={},
                name="Test Device",
                device_id=2,
                ip_address="192.168.1.2",
                port=12345,
                token="AA",
                key="BB",
                device_protocol=ProtocolVersion.V1,
                model="test_model",
                subtype=1,
            )
