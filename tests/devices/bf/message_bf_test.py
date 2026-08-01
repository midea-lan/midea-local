"""Test BF message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.bf.message import (
    FirePower,
    MessageBFBody,
    MessageBFResponse,
    MessageQuery,
    MessageSet,
    WorkStatus,
    work_mode_to_bytes,
    work_mode_to_name,
)
from midealocal.message import ListTypes, MessageType


class TestMessageQuery:
    """Test MessageQuery."""

    def test_query_body(self) -> None:
        """Test query body."""
        query = MessageQuery(protocol_version=ProtocolVersion.V1)
        # body_type 0x01 prepended by framework, content is [0x01]
        assert query.body == bytearray([ListTypes.X01, 0x01])


class TestWorkModeHelpers:
    """Test work mode mapping helpers."""

    def test_work_mode_to_bytes_known(self) -> None:
        """Test known work mode conversion."""
        assert work_mode_to_bytes("microwave") == (0x01, 0x00)
        assert work_mode_to_bytes("pure_steam") == (0x29, 0x00)
        assert work_mode_to_bytes("above_tube") == (0x51, 0x00)
        assert work_mode_to_bytes("eco") == (0xA2, 0x00)

    def test_work_mode_to_bytes_unknown(self) -> None:
        """Test unknown work mode returns 0xFF."""
        assert work_mode_to_bytes("nonexistent_mode") == (0xFF, 0xFF)

    def test_work_mode_to_bytes_none(self) -> None:
        """Test None mode returns 0xFF."""
        assert work_mode_to_bytes(None) == (0xFF, 0xFF)

    def test_work_mode_to_name_known(self) -> None:
        """Test known work mode reverse conversion."""
        assert work_mode_to_name(0x01, 0x00) == "microwave"
        assert work_mode_to_name(0x29, 0x00) == "pure_steam"
        assert work_mode_to_name(0x51, 0x00) == "above_tube"

    def test_work_mode_to_name_unknown(self) -> None:
        """Test unknown bytes return 'unknown'."""
        assert work_mode_to_name(0xFF, 0xFF) == "unknown"

    def test_work_mode_to_bytes_low_variant(self) -> None:
        """Test work mode with low byte variant."""
        assert work_mode_to_bytes("microwave_1") == (0x01, 0x01)
        assert work_mode_to_bytes("pure_steam_5") == (0x29, 0x05)

    def test_work_mode_roundtrip(self) -> None:
        """Test roundtrip: name -> bytes -> name."""
        for name in {
            "microwave": (0x01, 0x00),
            "eco": (0xA2, 0x00),
            "scale_clean": (0x79, 0x00),
        }:
            result = work_mode_to_name(*work_mode_to_bytes(name))
            assert result == name


class TestFirePower:
    """Test FirePower enum."""

    def test_values(self) -> None:
        """Test FirePower values."""
        assert FirePower.fire_power_0.value == 0x00
        assert FirePower.fire_power_10.value == 0x0A

    def test_all_values(self) -> None:
        """Test all FirePower enum values cover 0..10."""
        for i in range(11):
            assert FirePower(i).value == i

    def test_invalid_value(self) -> None:
        """Test invalid FirePower value raises ValueError."""
        with pytest.raises(ValueError, match=r".*"):
            FirePower(0x0B)


class TestWorkStatus:
    """Test WorkStatus enum."""

    def test_values(self) -> None:
        """Test WorkStatus values."""
        assert WorkStatus.save_power.value == 0x01
        assert WorkStatus.standby.value == 0x02
        assert WorkStatus.work.value == 0x03
        assert WorkStatus.pause.value == 0x06

    def test_all_defined_values(self) -> None:
        """Test all defined WorkStatus members."""
        assert WorkStatus.work_finish.value == 0x04
        assert WorkStatus.order.value == 0x05
        assert WorkStatus.pause_c.value == 0x07
        assert WorkStatus.self_inspection.value == 0x0A
        assert WorkStatus.wait_to_start.value == 0x10

    def test_invalid_value(self) -> None:
        """Test invalid WorkStatus value raises ValueError."""
        with pytest.raises(ValueError, match=r".*"):
            WorkStatus(0x00)
