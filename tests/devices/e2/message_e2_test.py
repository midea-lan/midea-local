"""Test E2 message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.e2.message import (
    E2GeneralMessageBody,
    MessageE2Base,
    MessageE2Response,
    MessageNewProtocolSet,
    MessagePower,
    MessageQuery,
    MessageSet,
)
from midealocal.message import ListTypes, MessageType


def _build_message(message_type: MessageType, body: bytearray) -> bytes:
    """Build a full E2 response message."""
    header = bytearray(
        [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
    )
    return bytes(header + body + bytearray([0x00]))


class TestMessageE2Base:
    """Test E2 Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageE2Base(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test E2 Message Query."""

    def test_query_body(self) -> None:
        """Test query body."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body_type == ListTypes.X01
        assert msg._body == bytearray([0x01])
        assert msg.body == bytearray([0x01, 0x01])


class TestMessagePower:
    """Test E2 Message Power."""

    def test_power_on(self) -> None:
        """Test power on switches the body type to 01."""
        msg = MessagePower(protocol_version=ProtocolVersion.V1)
        msg.power = True
        assert msg._body == bytearray([0x01])
        assert msg.body_type == ListTypes.X01

    def test_power_off(self) -> None:
        """Test power off switches the body type to 02."""
        msg = MessagePower(protocol_version=ProtocolVersion.V1)
        assert msg.power is False
        assert msg._body == bytearray([0x01])
        assert msg.body_type == ListTypes.X02


class TestMessageNewProtocolSet:
    """Test E2 Message New Protocol Set."""

    @pytest.mark.parametrize(
        ("attr", "value", "byte12", "byte13"),
        [
            ("target_temperature", 65, 0x07, 65),
            ("whole_tank_heating", True, 0x04, 0x02),
            ("whole_tank_heating", False, 0x04, 0x01),
            ("variable_heating", True, 0x10, 0x01),
            ("variable_heating", False, 0x10, 0x00),
            ("sterilization", True, 0x0D, 0x01),
            ("sterilization", False, 0x0D, 0x00),
            ("protect", True, 0x05, 0x01),
            ("protect", False, 0x05, 0x00),
            ("sleep", True, 0x0E, 0x01),
            ("sleep", False, 0x0E, 0x00),
            ("big_water", True, 0x11, 0x01),
            ("big_water", False, 0x11, 0x00),
            ("auto_off", True, 0x14, 0x01),
            ("auto_off", False, 0x14, 0x00),
            ("safe", True, 0x06, 0x01),
            ("safe", False, 0x06, 0x00),
            ("screen_off", True, 0x0F, 0x01),
            ("screen_off", False, 0x0F, 0x00),
            ("wash_temperature", 40, 0x16, 40),
            ("smart_sterilize", True, 0x1B, 0x01),
            ("smart_sterilize", False, 0x1B, 0x00),
            ("uv_sterilize", True, 0x1D, 0x01),
            ("uv_sterilize", False, 0x1D, 0x00),
        ],
    )
    def test_body_single_attribute(
        self,
        attr: str,
        value: bool | int,
        byte12: int,
        byte13: int,
    ) -> None:
        """Test new protocol set body for each single attribute."""
        msg = MessageNewProtocolSet(protocol_version=ProtocolVersion.V1)
        setattr(msg, attr, value)
        assert msg._body == bytearray([byte12, byte13])

    @pytest.mark.parametrize(
        ("memory", "flag"),
        [(True, 0x80), (False, 0x00)],
    )
    def test_body_memory(self, memory: bool, flag: int) -> None:
        """Test new protocol set body for the memory command."""
        msg = MessageNewProtocolSet(protocol_version=ProtocolVersion.V1)
        msg.memory = memory
        assert msg._body == bytearray(
            [0x03, 0x00, 0x00, flag, 0x00, 0x00, 0x00, 0x00, 0x00],
        )

    def test_body_defaults(self) -> None:
        """Test new protocol set body with no attribute set."""
        msg = MessageNewProtocolSet(protocol_version=ProtocolVersion.V1)
        assert msg._body == bytearray([0x00, 0x00])


class TestMessageSet:
    """Test E2 Message Set."""

    def test_body_defaults(self) -> None:
        """Test set body defaults."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        body = msg._body
        assert len(body) == 18
        assert body[0] == 0x01
        assert body[2] == 0x80
        assert body[3] == 0x01  # half tank, no protection
        assert body[4] == 0x00  # target temperature
        assert body[8] == 0x00  # variable heating off

    def test_body_custom(self) -> None:
        """Test set body with custom values."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.protection = True
        msg.whole_tank_heating = True
        msg.target_temperature = 55
        msg.variable_heating = True
        body = msg._body
        assert body[3] == 0x06  # whole tank | protection
        assert body[4] == 55
        assert body[8] == 0x10


class TestE2GeneralMessageBody:
    """Test E2 general message body."""

    def test_short_body(self) -> None:
        """Test short body skips the optional trailing fields."""
        raw = bytearray(17)
        raw[0] = 0x01
        raw[2] = 0x01 | 0x04  # power and heating
        raw[4] = 45  # current temperature
        raw[7] = 0x08  # whole tank heating
        raw[9] = 1  # end time hours
        raw[10] = 30  # end time minutes
        raw[11] = 65  # target temperature
        body = E2GeneralMessageBody(raw)
        assert body.power is True
        assert body.fast_hot_power is False
        assert body.heating is True
        assert body.keep_warm is False
        assert body.water_flow is False
        assert body.sterilization is False
        assert body.variable_heating is False
        assert body.current_temperature == 45.0
        assert body.whole_tank_heating is True
        assert body.heating_time_remaining == 90
        assert body.target_temperature == 65.0
        assert body.in_temperature is None
        assert body.protection is False
        assert body.memory is None
        assert not hasattr(body, "day_water_consumption")
        assert not hasattr(body, "water_consumption")
        assert not hasattr(body, "volume")
        assert not hasattr(body, "rate")
        assert not hasattr(body, "heating_power")

    def test_full_body(self) -> None:
        """Test full body parses every field."""
        raw = bytearray(35)
        raw[0] = 0x01
        raw[2] = 0xDF  # every switch bit
        raw[4] = 45  # current temperature
        raw[5] = 3  # heat water level
        raw[7] = 0xFF  # eplus..night bits
        raw[8] = 0xF8  # screen_off..now_wash bits
        raw[9] = 1  # end time hours
        raw[10] = 30  # end time minutes
        raw[11] = 65  # target temperature
        raw[12] = 0xE0  # sterilize bits
        raw[13] = 2  # discharge status
        raw[14] = 70  # top temperature
        raw[15] = 0x83  # bottom/top heat, water cyclic
        raw[16] = 1  # water system
        raw[18] = 20  # in temperature
        raw[20] = 0x10  # day water consumption low byte
        raw[21] = 0x01  # day water consumption high byte
        raw[22] = 0x02  # protection
        raw[23] = 0x08  # memory
        raw[24] = 0x20  # water consumption low byte
        raw[25] = 0x02  # water consumption high byte
        raw[27] = 5  # volume
        raw[28] = 3  # rate
        raw[34] = 20  # heating power
        body = E2GeneralMessageBody(raw)
        assert body.power is True
        assert body.fast_hot_power is True
        assert body.heating is True
        assert body.keep_warm is True
        assert body.water_flow is True
        assert body.sterilization is True
        assert body.variable_heating is True
        assert body.current_temperature == 45.0
        assert body.heat_water_level == 3
        assert body.eplus is True
        assert body.fast_wash is True
        assert body.half_heat is True
        assert body.whole_tank_heating is True
        assert body.summer is True
        assert body.winter is True
        assert body.efficient is True
        assert body.night is True
        assert body.screen_off is True
        assert body.sleep is True
        assert body.cloud is True
        assert body.appoint_wash is True
        assert body.now_wash is True
        assert body.heating_time_remaining == 90
        assert body.target_temperature == 65.0
        assert body.smart_sterilize is True
        assert body.sterilize_high_temp is True
        assert body.uv_sterilize is True
        assert body.discharge_status == 2
        assert body.top_temp == 70
        assert body.bottom_heat is True
        assert body.top_heat is True
        assert body.water_cyclic is True
        assert body.water_system == 1
        assert body.in_temperature == 20.0
        assert body.protection is True
        assert body.memory is True
        assert body.day_water_consumption == 272
        assert body.water_consumption == 544
        assert body.volume == 5
        assert body.rate == 300
        assert body.heating_power == 2000


class TestMessageE2Response:
    """Test E2 Message Response."""

    @pytest.mark.parametrize(
        ("message_type", "body_type"),
        [
            (MessageType.query, 0x01),
            (MessageType.notify1, 0x01),
            (MessageType.set, 0x01),
            (MessageType.set, 0x02),
            (MessageType.set, 0x04),
            (MessageType.set, 0x14),
        ],
    )
    def test_response_parsed(
        self,
        message_type: MessageType,
        body_type: int,
    ) -> None:
        """Test response with a handled type parses attributes."""
        body = bytearray(35)
        body[0] = body_type
        body[2] = 0x01  # power
        msg = MessageE2Response(_build_message(message_type, body))
        assert getattr(msg, "power", None) is True
        assert getattr(msg, "heating", None) is False

    @pytest.mark.parametrize(
        ("message_type", "body_type"),
        [
            (MessageType.query, 0x02),
            (MessageType.set, 0x03),
            (MessageType.notify2, 0x01),
        ],
    )
    def test_response_not_parsed(
        self,
        message_type: MessageType,
        body_type: int,
    ) -> None:
        """Test response with an unhandled type parses nothing."""
        body = bytearray(35)
        body[0] = body_type
        body[2] = 0x01
        msg = MessageE2Response(_build_message(message_type, body))
        assert not hasattr(msg, "power")
