"""Shared climate classes for Midea devices."""

from abc import ABC, abstractmethod
from collections.abc import Sequence
from enum import IntEnum, StrEnum
from typing import final

from midealocal.device import MideaDevice


class MideaHVACMode(IntEnum):
    """Midea HVAC Mode."""


class MideaFanMode(IntEnum):
    """Midea Fan Mode."""


class MideaSwingMode(StrEnum):
    """Midea Swing Mode."""


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
    def hvac_modes(self) -> set[MideaHVACMode]:
        """Return the supported HVAC modes."""

    @property
    @final
    def raw_hvac_modes(self) -> Sequence[str]:
        """Return the generic HVAC mode names, in protocol-index order."""
        return [mode.name.lower() for mode in sorted(self.hvac_modes)]

    @abstractmethod
    def hvac_mode(self, zone: int | None = None) -> MideaHVACMode | None:
        """Return the current HVAC mode name, or None if unknown.

        Takes a zone like set_target_temperature: ignored by every device
        except C3, where zone is the only way to know which zone's power
        attribute to read (its mode is shared across zones, but power isn't).
        """

    @final
    def raw_hvac_mode(self, zone: int | None = None) -> str | None:
        """Return the current HVAC mode name, or None if unknown.

        Takes a zone like set_target_temperature: ignored by every device
        except C3, where zone is the only way to know which zone's power
        attribute to read (its mode is shared across zones, but power isn't).
        """
        hvac_mode = self.hvac_mode(zone=zone)
        return hvac_mode.name.lower() if hvac_mode is not None else None

    @abstractmethod
    def set_hvac_mode(
        self,
        hvac_mode: MideaHVACMode,
        zone: int | None = None,
    ) -> None:
        """Set the HVAC mode by name. See hvac_mode for the zone parameter."""

    def _str_to_hvac(self, hvac_name: str | None) -> MideaHVACMode | None:
        """Get the correct MideaHVACMode based on name."""
        if hvac_name is None:
            return None
        for mode in self.hvac_modes:
            if mode.name.lower() == hvac_name:
                return mode
        return None

    @final
    def set_raw_hvac_mode(self, hvac_mode: str, zone: int | None = None) -> None:
        """Set the HVAC mode by name. See hvac_mode for the zone parameter."""
        hvac = self._str_to_hvac(hvac_mode)
        if hvac is not None:
            return self.set_hvac_mode(hvac_mode=hvac, zone=zone)
        raise ValueError("Unsupported hvac mode")

    @abstractmethod
    def set_target_temperature(
        self,
        target_temperature: float,
        hvac_mode: MideaHVACMode | None,
        zone: int | None = None,
    ) -> None:
        """Set the target temperature, optionally also changing HVAC mode."""

    @final
    def set_raw_target_temperature(
        self,
        target_temperature: float,
        hvac_mode: str | None,
        zone: int | None = None,
    ) -> None:
        """Set the target temperature, optionally also changing HVAC mode."""
        self.set_target_temperature(
            target_temperature=target_temperature,
            hvac_mode=self._str_to_hvac(hvac_mode),
            zone=zone,
        )

    @property
    def fan_modes(self) -> Sequence[MideaFanMode] | None:
        """Return the available fan modes, or None if unsupported."""
        return None

    @property
    @final
    def raw_fan_modes(self) -> Sequence[str] | None:
        """Return the available fan modes, or None if unsupported."""
        if self.fan_modes is None:
            return None
        return [fan_mode.name.lower() for fan_mode in sorted(self.fan_modes)]

    @property
    def fan_mode(self) -> MideaFanMode | None:
        """Return the current fan mode, or None if unsupported/unknown."""
        return None

    @property
    @final
    def raw_fan_mode(self) -> str | None:
        """Return the current fan mode, or None if unsupported/unknown."""
        return self.fan_mode.name.lower() if self.fan_mode is not None else None

    def _str_to_fan_mode(self, fan_mode: str) -> MideaFanMode | None:
        """Get the correct MideaFanMode based on name."""
        if self.fan_modes is None:
            return None
        for mode in self.fan_modes:
            if mode.name.lower() == fan_mode:
                return mode
        return None

    def set_fan_mode(self, fan_mode: MideaFanMode) -> None:
        """Set the device fan mode."""
        msg = "Fan mode is not supported by this device"
        raise NotImplementedError(msg)

    @final
    def set_raw_fan_mode(self, fan_mode: str) -> None:
        """Set the fan mode by name."""
        mode = self._str_to_fan_mode(fan_mode)
        if mode is None:
            raise ValueError("Unsupported fan mode")
        self.set_fan_mode(mode)

    @property
    def swing_modes(self) -> Sequence[MideaSwingMode] | None:
        """Return the available MideaSwingMode, or None if unsupported."""
        return None

    @property
    @final
    def raw_swing_modes(self) -> Sequence[str] | None:
        """Return the available swing modes, or None if unsupported."""
        return self.swing_modes

    @property
    def swing_mode(self) -> MideaSwingMode | None:
        """Return the current swing mode, or None if unsupported/unknown."""
        return None

    @property
    @final
    def raw_swing_mode(self) -> str | None:
        """Return the current swing mode, or None if unsupported/unknown."""
        return self.swing_mode

    def _str_to_swing_mode(self, swing_mode: str) -> MideaSwingMode | None:
        """Get the correct MideaFanMode based on name."""
        if self.swing_modes is None:
            return None
        for mode in self.swing_modes:
            if mode == swing_mode:
                return mode
        return None

    def set_swing_mode(self, swing_mode: MideaSwingMode) -> None:
        """Set the swing mode."""
        msg = "Swing mode is not supported by this device"
        raise NotImplementedError(msg)

    @final
    def set_raw_swing_mode(self, swing_mode: str) -> None:
        """Set the swing mode by name."""
        mode = self._str_to_swing_mode(swing_mode)
        if mode is None:
            raise ValueError("Unsupported swing mode")
        self.set_swing_mode(mode)

    @property
    def temperature_step(self) -> float | None:
        """Return the target temperature step, or None if fixed/unknown."""
        return None
