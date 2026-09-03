"""Midea Local shared base classes test."""

import pytest

from midealocal.base_classes.climate import (
    MideaClimateDevice,
    MideaFanMode,
    MideaHVACMode,
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
        assert self.device.raw_fan_modes is None
        assert self.device.raw_fan_mode is None
        with pytest.raises(ValueError, match="Unsupported fan mode"):
            self.device.set_raw_fan_mode("auto")
        with pytest.raises(NotImplementedError, match="Fan mode"):
            self.device.set_fan_mode(DummyFanMode.OFF)

    def test_swing_capability_defaults_to_unsupported(self) -> None:
        """Test swing_modes/swing_mode default to None and set_swing_mode raises."""
        assert self.device.raw_swing_modes is None
        assert self.device.raw_swing_mode is None
        with pytest.raises(ValueError, match="Unsupported swing mode"):
            self.device.set_raw_swing_mode("on")
        with pytest.raises(NotImplementedError, match="Swing mode"):
            self.device.set_swing_mode(DummySwingMode.OFF)

    def test_temperature_step_defaults_to_none(self) -> None:
        """Test temperature_step defaults to None."""
        assert self.device.temperature_step is None

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
