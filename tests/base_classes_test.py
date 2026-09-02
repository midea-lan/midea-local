"""Midea Local shared base classes test."""

import pytest

from midealocal.base_classes import MideaClimateDevice
from midealocal.const import DeviceType, ProtocolVersion


class _MinimalClimateDevice(MideaClimateDevice):
    """A climate device overriding only the mandatory members."""

    @property
    def hvac_modes(self) -> list[str]:
        return ["off", "auto"]

    def hvac_mode(self, zone: int | None = None) -> str | None:  # noqa: ARG002
        return "auto"

    def set_hvac_mode(self, hvac_mode: str, zone: int | None = None) -> None:  # noqa: ARG002
        self._attributes["hvac_mode"] = hvac_mode

    def set_target_temperature(
        self,
        target_temperature: float,
        mode: int | None,  # noqa: ARG002
        zone: int | None = None,  # noqa: ARG002
    ) -> None:
        self._attributes["target_temperature"] = target_temperature


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
        assert self.device.fan_modes is None
        assert self.device.fan_mode is None
        with pytest.raises(NotImplementedError, match="Fan mode"):
            self.device.set_fan_mode("auto")

    def test_swing_capability_defaults_to_unsupported(self) -> None:
        """Test swing_modes/swing_mode default to None and set_swing_mode raises."""
        assert self.device.swing_modes is None
        assert self.device.swing_mode is None
        with pytest.raises(NotImplementedError, match="Swing mode"):
            self.device.set_swing_mode("on")

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
