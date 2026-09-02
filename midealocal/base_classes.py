"""Shared base classes for Midea devices, grouped by capability.

Each class here defines the public shape every device supporting that
capability (climate, fan, humidifier, ...) exposes, so a consumer (Home
Assistant or any other caller) can treat them uniformly regardless of
protocol differences.
"""

from abc import ABC, abstractmethod
from collections.abc import Sequence

from midealocal.device import MideaDevice


class MideaClimateDevice(MideaDevice, ABC):
    """Base class for climate-capable Midea devices (ac, cc, cf, c3, fb).

    The mandatory members below have no sensible default and must be
    overridden. Capabilities a given device doesn't support (fan speed,
    swing, a configurable temperature step) keep this class's defaults,
    which report the capability as unsupported rather than raising for a
    routine read.
    """

    @property
    @abstractmethod
    def hvac_modes(self) -> Sequence[str]:
        """Return the generic HVAC mode names, in protocol-index order."""

    @abstractmethod
    def hvac_mode(self, zone: int | None = None) -> str | None:
        """Return the current HVAC mode name, or None if unknown.

        Takes a zone like set_target_temperature: ignored by every device
        except C3, where zone is the only way to know which zone's power
        attribute to read (its mode is shared across zones, but power isn't).
        """

    @abstractmethod
    def set_hvac_mode(self, hvac_mode: str, zone: int | None = None) -> None:
        """Set the HVAC mode by name. See hvac_mode for the zone parameter."""

    @abstractmethod
    def set_target_temperature(
        self,
        target_temperature: float,
        mode: int | None,
        zone: int | None = None,
    ) -> None:
        """Set the target temperature, optionally also changing HVAC mode."""

    @property
    def fan_modes(self) -> Sequence[str] | None:
        """Return the available fan modes, or None if unsupported."""
        return None

    @property
    def fan_mode(self) -> str | None:
        """Return the current fan mode, or None if unsupported/unknown."""
        return None

    def set_fan_mode(self, fan_mode: str) -> None:
        """Set the fan mode by name."""
        msg = "Fan mode is not supported by this device"
        raise NotImplementedError(msg)

    @property
    def swing_modes(self) -> Sequence[str] | None:
        """Return the available swing modes, or None if unsupported."""
        return None

    @property
    def swing_mode(self) -> str | None:
        """Return the current swing mode, or None if unsupported/unknown."""
        return None

    def set_swing_mode(self, swing_mode: str) -> None:
        """Set the swing mode by name."""
        msg = "Swing mode is not supported by this device"
        raise NotImplementedError(msg)

    @property
    def temperature_step(self) -> float | None:
        """Return the target temperature step, or None if fixed/unknown."""
        return None
