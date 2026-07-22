"""Test FB message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.fb.message import (
    MessageFBBase,
    MessageQuery,
    MessageSet,
)
from midealocal.message import MessageType


class TestMessageFBBase:
    """Test FB Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageFBBase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test FB Message Query."""

    def test_query_body(self) -> None:
        """Test query body is empty."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([])
        assert msg._body == bytearray([])


class TestMessageSet:
    """Test FB Message Set."""

    def test_set_body_defaults(self) -> None:
        """Test set body with default values."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1, subtype=1)
        expected = bytearray(20)
        expected[18] = 0xFF  # child_lock unset
        assert msg.body == expected
        assert msg._body == bytearray([])

    def test_set_body_with_values(self) -> None:
        """Test set body with power on and valid values."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1, subtype=1)
        msg.power = True
        msg.mode = 0x03
        msg.heating_level = 5
        msg.target_temperature = 25
        msg.child_lock = True
        body = msg.body
        assert len(body) == 20
        assert body[0] == 0x01
        assert body[4] == 0x03
        assert body[5] == 5
        assert body[6] == 66
        assert body[18] == 0x01

    def test_set_body_power_off_and_out_of_range(self) -> None:
        """Test set body with power off and out-of-range values zeroed."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1, subtype=1)
        msg.power = False
        msg.heating_level = 20  # above MAX_HEATING_LEVEL
        msg.target_temperature = 60  # above MAX_TARGET_TEMP
        msg.child_lock = False
        body = msg.body
        assert body[0] == 0x02
        assert body[5] == 0x00
        assert body[6] == 0x00
        assert body[18] == 0x00

    @pytest.mark.parametrize("target_temperature", [0x80, 87])
    def test_set_body_special_target_temperature(
        self,
        target_temperature: int,
    ) -> None:
        """Test set body with special target temperature values."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1, subtype=1)
        msg.target_temperature = target_temperature
        assert msg.body[6] == 0x80

    def test_set_body_large_subtype(self) -> None:
        """Test set body is extended for subtypes above 0x05."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1, subtype=6)
        assert len(msg.body) == 23
