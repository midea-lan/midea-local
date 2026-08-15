"""Test E6 message."""

import pytest

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.devices.e6.message import (
    E6GeneralMessageBody,
    MessageE6Base,
    MessageE6Response,
    MessageQuery,
    MessageSet,
)
from midealocal.message import MessageType


class TestMessageE6Base:
    """Test E6 Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageE6Base(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test E6 Message Query."""

    def test_query_body(self) -> None:
        """Test query body."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x01, 0x01] + [0x00] * 28)


class TestMessageSet:
    """Test E6 Message Set."""

    @pytest.mark.parametrize(
        ("attr", "value", "expected_prefix"),
        [
            ("main_power", True, [0x01, 0x01]),
            ("main_power", False, [0x02, 0x01]),
            ("heating_temperature", 50.5, [0x04, 0x13, 50]),
            ("bathing_temperature", 42.0, [0x04, 0x12, 42]),
            ("heating_power", True, [0x04, 0x01, 0x01]),
            ("heating_power", False, [0x04, 0x01, 0x02]),
            ("cold_water_single", True, [0x04, 0x1A, 0x01]),
            ("cold_water_single", False, [0x04, 0x1A, 0x00]),
            ("cold_water_dot", True, [0x04, 0x1B, 0x01]),
            ("cold_water_dot", False, [0x04, 0x1B, 0x00]),
            ("heating_modes", "normal", [0x04, 0x02, 0x01]),
            ("heating_modes", "out", [0x04, 0x02, 0x02]),
            ("heating_modes", "home", [0x04, 0x02, 0x04]),
            ("heating_modes", "sleep", [0x04, 0x02, 0x08]),
            ("heating_modes", "invalid", []),
        ],
    )
    def test_set_body(
        self,
        attr: str,
        value: bool | float | str,
        expected_prefix: list[int],
    ) -> None:
        """Test set body for each settable attribute."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        setattr(msg, attr, value)
        expected = bytearray(expected_prefix + [0x00] * (30 - len(expected_prefix)))
        assert msg.body == expected

    def test_set_body_default(self) -> None:
        """Test set body with no attribute set is empty padding."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x00] * 30)


class TestE6GeneralMessageBody:
    """Test E6 general message body parsing."""

    @staticmethod
    def _build_body(
        *,
        byte2: int = 0,
        byte4: int = 0,
        byte8: int = 0,
        byte10: int = 0,
        byte11: int = 0,
        byte12: int = 0,
        byte14: int = 0,
        byte15: int = 0,
        byte16: int = 0,
        byte17: int = 0,
        byte25: int = 0,
    ) -> bytearray:
        body = bytearray(30)
        body[2] = byte2
        body[4] = byte4
        body[8] = byte8
        body[10] = byte10
        body[11] = byte11
        body[12] = byte12
        body[14] = byte14
        body[15] = byte15
        body[16] = byte16
        body[17] = byte17
        body[25] = byte25
        return body

    def test_flags_and_temperatures(self) -> None:
        """Power/working/cold-water flags and temperature bytes parse."""
        body = self._build_body(
            byte2=0x04 | 0x10 | 0x20,
            byte4=0x01,
            byte8=38,
            byte10=60,
            byte11=35,
            byte12=40,
            byte14=43,
            byte15=80,
            byte16=30,
            byte17=45,
            byte25=0x01 | 0x02,
        )
        parsed = E6GeneralMessageBody(body)
        assert parsed.main_power is True
        assert parsed.heating_working is True
        assert parsed.bathing_working is True
        assert parsed.heating_power is True
        assert parsed.temperature_min == [30.0, 35.0]
        assert parsed.temperature_max == [80.0, 60.0]
        assert parsed.heating_temperature == 45.0
        assert parsed.bathing_temperature == 40.0
        assert parsed.heating_leaving_temperature == 43.0
        assert parsed.bathing_leaving_temperature == 38.0
        assert parsed.cold_water_single is True
        assert parsed.cold_water_dot is True

    def test_flags_all_off(self) -> None:
        """All flag bytes zeroed parse to False."""
        parsed = E6GeneralMessageBody(self._build_body())
        assert parsed.main_power is False
        assert parsed.heating_working is False
        assert parsed.bathing_working is False
        assert parsed.heating_power is False
        assert parsed.cold_water_single is False
        assert parsed.cold_water_dot is False

    @pytest.mark.parametrize(
        ("byte4", "expected_mode"),
        [
            (0x08, "out"),
            (0x04, "normal"),
            (0x10, "home"),
            (0x20, "sleep"),
            (0x00, "normal"),
        ],
    )
    def test_heating_modes(self, byte4: int, expected_mode: str) -> None:
        """Each heating mode bit decodes to the expected mode name."""
        body = self._build_body(byte4=byte4)
        assert E6GeneralMessageBody(body).heating_modes == expected_mode


class TestMessageE6Response:
    """Test E6 message response."""

    @staticmethod
    def _build_message(body: bytearray) -> bytes:
        header = bytearray([0xAA, 0x00, DeviceType.E6, 0x00, 0x00, 0x00, 0x00, 0x00])
        header += bytearray([ProtocolVersion.V1, MessageType.query])
        return bytes(header + body + bytearray([0x00]))

    def test_response_sets_attributes(self) -> None:
        """The response parses the body and exposes attributes."""
        body = TestE6GeneralMessageBody._build_body(
            byte2=0x04,
            byte4=0x01,
            byte17=45,
        )
        response = MessageE6Response(self._build_message(body))
        assert getattr(response, "main_power", None) is True
        assert getattr(response, "heating_power", None) is True
        assert getattr(response, "heating_temperature", None) == 45.0
