"""Midea Local shared rice cooker base class test."""

from typing import ClassVar

from midealocal.base_classes.rice_cooker import MideaRiceCookerDevice


class _ExtraModeRiceCookerDevice(MideaRiceCookerDevice):
    """A rice cooker device with one extra protocol-specific mode."""

    _mode_list: ClassVar[list[str]] = [*MideaRiceCookerDevice._mode_list, "diy"]


class TestMideaRiceCookerDevice:
    """Test the shared rice cooker device base class."""

    def test_mode_options_drops_unknown_padding(self) -> None:
        """mode_options excludes the "unknown" padding entries."""
        options = MideaRiceCookerDevice.mode_options()
        assert "unknown" not in options
        assert len(options) == len(set(options))
        assert options[0] == "smart"
        assert options[-1] == "keep_warm"

    def test_subclass_extends_shared_mode_list(self) -> None:
        """A device with an extra mode extends, rather than retypes, the table."""
        options = _ExtraModeRiceCookerDevice.mode_options()
        assert options[:-1] == MideaRiceCookerDevice.mode_options()
        assert options[-1] == "diy"
