"""Test ac message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.crc8 import calculate
from midealocal.devices.ac.message import (
    MessageA0LongQuery,
    MessageA0Query,
    MessageACBase,
    MessageACResponse,
    MessageCapabilitiesQuery,
    MessageGeneralSet,
    MessageGroupDataQuery,
    MessageGroupOneQuery,
    MessageGroupSevenQuery,
    MessageGroupTwoQuery,
    MessageGroupZeroQuery,
    MessageHumidityQuery,
    MessageNewProtocolQuery,
    MessageNewProtocolSet,
    MessagePowerQuery,
    MessageQuery,
    MessageSubProtocol,
    MessageSubProtocolFreshAirSet,
    MessageSubProtocolQuery10,
    MessageSubProtocolQuery11,
    MessageSubProtocolQuery30,
    MessageSubProtocolSet,
    MessageToggleDisplay,
    NewProtocolQuery,
    NewProtocolTags,
    PowerFormats,
)
from midealocal.message import ListTypes, MessageBase, MessageType


class TestMessageACBase:
    """Test AC Message Base."""

    def test_message_id_increment(self) -> None:
        """Test message Id Increment."""
        msg = MessageACBase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )
        msg2 = MessageACBase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )
        assert msg2._message_id == msg._message_id + 1
        # test reset
        for _ in range(254 - msg2._message_id):
            msg = MessageACBase(
                protocol_version=ProtocolVersion.V1,
                message_type=MessageType.query,
                body_type=ListTypes.X01,
            )
        assert msg._message_id == 1

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageACBase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test Message Query."""

    def test_query_body(self) -> None:
        """Test query body."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray(
            [
                0x41,
                0x81,
                0x00,
                0xFF,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
            ],
        )
        assert msg.body[:-2] == expected_body


class TestMessageCapabilitiesQuery:
    """Test Message Capabilities Query."""

    def test_capabilities_query_body(self) -> None:
        """Test capabilities query body."""
        msg = MessageCapabilitiesQuery(ProtocolVersion.V1, False)
        expected_body = bytearray(
            [0xB5, 0x01, 0x00],
        )
        assert msg.body[:-2] == expected_body

    def test_capabilities_query_body_additional(self) -> None:
        """Test capabilities query body."""
        msg = MessageCapabilitiesQuery(ProtocolVersion.V1, True)
        expected_body = bytearray(
            [0xB5, 0x01, 0x01, 0x01],
        )
        assert msg.body[:-2] == expected_body


class TestMessageA0Query:
    """Test Message A0 Query."""

    def test_a0_query_body(self) -> None:
        """Test A0 query body."""
        msg = MessageA0Query(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0xA0, 0xA7])
        assert msg.body[:2] == expected_body
        assert len(msg.body) == 4  # body type + query + message id + crc

    def test_a0_long_query_body(self) -> None:
        """Test A0 long query body."""
        msg = MessageA0LongQuery(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0xA0] + [0x00] * 19)
        assert msg.body[:-2] == expected_body


class TestMessagePowerQuery:
    """Test Message Power Query."""

    def test_power_query_body(self) -> None:
        """Test power query body."""
        msg = MessagePowerQuery(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0x41, 0x21, 0x01, 0x44, 0x00, 0x01])
        assert msg.body[:-1] == expected_body


class TestMessageGroupDataQuery:
    """Test Message Group Data Query."""

    @pytest.mark.parametrize(
        ("message_class", "group"),
        [
            (MessageGroupZeroQuery, 0),
            (MessageGroupOneQuery, 1),
            (MessageGroupTwoQuery, 2),
            (MessagePowerQuery, 4),
            (MessageHumidityQuery, 5),
            (MessageGroupSevenQuery, 7),
        ],
    )
    def test_group_query_body(
        self,
        message_class: type[MessageGroupDataQuery],
        group: int,
    ) -> None:
        """Test that every group query encodes its group number."""
        msg = message_class(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0x41, 0x21, 0x01, 0x40 | group, 0x00, 0x01])
        assert msg.body[:-1] == expected_body


class TestMessageGroupZeroQuery:
    """Test Message Group Zero Query."""

    def test_group_zero_query_body(self) -> None:
        """Test group zero query body."""
        msg = MessageGroupZeroQuery(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0x41, 0x21, 0x01, 0x40, 0x00, 0x01])
        assert msg.body[:-1] == expected_body


class TestMessageHumidityQuery:
    """Test Message Humidity Query."""

    def test_humidity_query_body(self) -> None:
        """Test humidity query body."""
        msg = MessageHumidityQuery(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0x41, 0x21, 0x01, 0x45, 0x00, 0x01])
        assert msg.body[:-1] == expected_body


class TestMessageToggleDisplay:
    """Test Message Toggle Display."""

    def test_toggle_disply_body(self) -> None:
        """Test toggle display body."""
        msg = MessageToggleDisplay(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray(
            [
                0x41,
                0x02,
                0x00,
                0xFF,
                0x02,
                0x00,
                0x02,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
            ],
        )
        assert msg.body[:-2] == expected_body
        msg.prompt_tone = True
        expected_body = bytearray(
            [
                0x41,
                0x02 | 0x40,
                0x00,
                0xFF,
                0x02,
                0x00,
                0x02,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
            ],
        )
        assert msg.body[:-2] == expected_body


class TestMessageNewProtocolQuery:
    """Test Message New Protocol Query."""

    def test_new_protocol_query_body(self) -> None:
        """Test new protocol query body."""
        msg = MessageNewProtocolQuery(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray(
            [
                0xB1,
                0x0D,
                NewProtocolTags.indirect_wind & 0xFF,
                NewProtocolTags.indirect_wind >> 8,
                NewProtocolTags.breezeless & 0xFF,
                NewProtocolTags.breezeless >> 8,
                NewProtocolTags.indoor_humidity & 0xFF,
                NewProtocolTags.indoor_humidity >> 8,
                NewProtocolTags.screen_display & 0xFF,
                NewProtocolTags.screen_display >> 8,
                NewProtocolTags.fresh_air_1 & 0xFF,
                NewProtocolTags.fresh_air_1 >> 8,
                NewProtocolTags.fresh_air_2 & 0xFF,
                NewProtocolTags.fresh_air_2 >> 8,
                NewProtocolTags.wind_lr_angle & 0xFF,
                NewProtocolTags.wind_lr_angle >> 8,
                NewProtocolTags.wind_ud_angle & 0xFF,
                NewProtocolTags.wind_ud_angle >> 8,
                NewProtocolTags.rate_select & 0xFF,
                NewProtocolTags.rate_select >> 8,
                NewProtocolTags.out_silent & 0xFF,
                NewProtocolTags.out_silent >> 8,
                NewProtocolTags.buzzer_all & 0xFF,
                NewProtocolTags.buzzer_all >> 8,
                NewProtocolQuery.error_code_query & 0xFF,
                NewProtocolQuery.error_code_query >> 8,
                NewProtocolTags.b5_self_clean_active & 0xFF,
                NewProtocolTags.b5_self_clean_active >> 8,
            ],
        )
        assert msg.body[:-2] == expected_body


class TestMessageNewProtocolSetOutSilent:
    """Test Message New Protocol Set for out_silent."""

    @pytest.mark.parametrize(
        ("value", "expected_byte"),
        [(True, 0x03), (False, 0x00)],
    )
    def test_out_silent_on_off(self, value: bool, expected_byte: int) -> None:
        """Test out_silent set to on/off sends correct byte."""
        msg = MessageNewProtocolSet(protocol_version=ProtocolVersion.V1)
        msg.out_silent = value
        body = msg.body
        assert body[0] == 0xB0
        assert body[1] == 0x01  # 1 param packed
        assert body[2] == NewProtocolTags.out_silent & 0xFF  # 0xCD
        assert body[3] == NewProtocolTags.out_silent >> 8  # 0x00
        assert body[4] == 0x01  # length byte
        assert body[5] == expected_byte

    def test_out_silent_none_not_packed(self) -> None:
        """Test out_silent None does not add to payload."""
        msg = MessageNewProtocolSet(protocol_version=ProtocolVersion.V1)
        # out_silent defaults to None, should not be packed
        body = msg.body
        assert body[0] == 0xB0
        assert body[1] == 0x00  # 0 params packed


class TestMessageNewProtocolSetAngles:
    """Test Message New Protocol Set for wind angles and rate select."""

    @pytest.mark.parametrize(
        ("value", "expected_byte"),
        [(25, 25), (0, 0x00)],
    )
    def test_wind_lr_angle(self, value: int, expected_byte: int) -> None:
        """Test wind_lr_angle set sends correct byte."""
        msg = MessageNewProtocolSet(protocol_version=ProtocolVersion.V1)
        # source annotates wind_lr_angle as bytes | None but the device sets ints
        setattr(msg, "wind_lr_angle", value)  # noqa: B010
        body = msg.body
        assert body[0] == 0xB0
        assert body[1] == 0x01  # 1 param packed
        assert body[2] == NewProtocolTags.wind_lr_angle & 0xFF  # 0x0A
        assert body[3] == NewProtocolTags.wind_lr_angle >> 8  # 0x00
        assert body[4] == 0x01  # length byte
        assert body[5] == expected_byte

    @pytest.mark.parametrize(
        ("value", "expected_byte"),
        [(75, 75), (0, 0x00)],
    )
    def test_wind_ud_angle(self, value: int, expected_byte: int) -> None:
        """Test wind_ud_angle set sends correct byte."""
        msg = MessageNewProtocolSet(protocol_version=ProtocolVersion.V1)
        # source annotates wind_ud_angle as bytes | None but the device sets ints
        setattr(msg, "wind_ud_angle", value)  # noqa: B010
        body = msg.body
        assert body[0] == 0xB0
        assert body[1] == 0x01  # 1 param packed
        assert body[2] == NewProtocolTags.wind_ud_angle & 0xFF  # 0x09
        assert body[3] == NewProtocolTags.wind_ud_angle >> 8  # 0x00
        assert body[4] == 0x01  # length byte
        assert body[5] == expected_byte

    def test_rate_select(self) -> None:
        """Test rate_select set sends correct byte."""
        msg = MessageNewProtocolSet(protocol_version=ProtocolVersion.V1)
        msg.rate_select = 60
        body = msg.body
        assert body[0] == 0xB0
        assert body[1] == 0x01  # 1 param packed
        assert body[2] == NewProtocolTags.rate_select & 0xFF  # 0x48
        assert body[3] == NewProtocolTags.rate_select >> 8  # 0x00
        assert body[4] == 0x01  # length byte
        assert body[5] == 60


class TestMessageSubProtocol:
    """Test Message Sub Protocol."""

    def test_sub_protocol_body(self) -> None:
        """Test sub protocol body."""
        msg = MessageSubProtocol(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            subprotocol_query_type=0xCC,
        )
        expected_body = bytearray(
            [
                0xAA,
                0x08,
                0x00,
                0xFF,
                0xFF,
                0xCC,
            ],
        )
        assert msg.body[:-2] == expected_body

    def test_distinct_query_classes(self) -> None:
        """Test BB queries have independent protocol identities."""
        queries = [
            MessageSubProtocolQuery10(ProtocolVersion.V1),
            MessageSubProtocolQuery11(ProtocolVersion.V1),
            MessageSubProtocolQuery30(ProtocolVersion.V1),
        ]

        assert [query.body[5] for query in queries] == [0x10, 0x11, 0x30]
        assert len({query.__class__.__name__ for query in queries}) == 3


class TestMessageGroupOneQuery:
    """Test AC C1 group 0x41 query."""

    def test_query_body(self) -> None:
        """Test exact group 0x41 query body."""
        message = MessageGroupOneQuery(ProtocolVersion.V1)

        assert message.body.hex() == "4121014100013c"


class TestMessageSubProtocolFreshAirSet:
    """Test BB fresh-air single-control commands."""

    @pytest.mark.parametrize(
        ("power", "speed", "exhaust", "expected"),
        [
            (
                True,
                60,
                False,
                (
                    "aa6800ffffc0000101000000000000000001c002540000000000000404000000"
                    "0000000000000000000000000000000000000000000000000000000000000000"
                    "000000000000000000000000bc00000000000000000000000000000000000000"
                    "000000000026002d"
                ),
            ),
            (
                False,
                60,
                False,
                (
                    "aa6800ffffc0000101000000000000000001c002540000000000000400000000"
                    "0000000000000000000000000000000000000000000000000000000000000000"
                    "000000000000000000000000bc00000000000000000000000000000000000000"
                    "00000000002a1c11"
                ),
            ),
            (
                True,
                80,
                True,
                (
                    "aa6800ffffc0000101000000000000000001c002540000000000000808000000"
                    "0000000000000000000000000000000000000000000000000000000000000000"
                    "00000000000000000000000000d0000000000000000000000000000000000000"
                    "00000000000af23b"
                ),
            ),
            (
                False,
                80,
                True,
                (
                    "aa6800ffffc0000101000000000000000001c002540000000000000800000000"
                    "0000000000000000000000000000000000000000000000000000000000000000"
                    "00000000000000000000000000d0000000000000000000000000000000000000"
                    "000000000012ca63"
                ),
            ),
        ],
    )
    def test_command_body(
        self,
        power: bool,
        speed: int,
        exhaust: bool,
        expected: str,
    ) -> None:
        """Test exact intake and exhaust command bytes."""
        message = MessageSubProtocolFreshAirSet(
            ProtocolVersion.V1,
            power,
            speed,
            exhaust=exhaust,
        )

        assert message.body.hex() == expected


class TestMessageSubProtocolSet:
    """Test Message Sub Protocol Set."""

    def test_sub_protocol_set_body(self) -> None:
        """Test sub protocol set body."""
        msg = MessageSubProtocolSet(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray(
            [
                0xAA,
                45,
                0x00,
                0xFF,
                0xFF,
                0x20,
                0x02,
                0x80,
                0x00,
                0x00,
                0x00,
                0x00,
                20 * 2 + 30,
                102,
                0x32,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x01,
                0x01,
                0x00,
                0x01,
                19 * 2 + 50,
                0x00,
                20 * 2 + 30,
                0x32,
                0x66,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x08,
            ],
        )
        assert msg.body[:-2] == expected_body

        msg.power = True
        msg.mode = 6
        msg.target_temperature = 24.0
        msg.fan_speed = 90
        msg.boost_mode = True
        msg.aux_heating = True
        msg.dry = True
        msg.eco_mode = True
        msg.sleep_mode = True
        msg.sn8_flag = True
        msg.timer = True
        msg.prompt_tone = True
        expected_body[6] = 0x02 | 0x20 | 0x01 | 0x10
        expected_body[7] = 0x40
        expected_body[8] = 0x80
        expected_body[11] = 0x02
        expected_body[12] = 24 * 2 + 30
        expected_body[13] = 90
        expected_body[25] = 23 * 2 + 50
        expected_body[26] = 0x01
        expected_body[27] = 24 * 2 + 30
        expected_body[31] = 0x40 | 0x04
        assert msg.body[:-2] == expected_body


class TestMessageGeneralSet:
    """Test Message General Set."""

    def test_general_set_body(self) -> None:
        """Test general set body."""
        msg = MessageGeneralSet(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray(
            [
                0x40,
                0x40,
                0x00 | (20 & 0xF) | (0x10 if 20 % 2 != 0 else 0),
                102 & 0x7F,
                0x00,
                0x00,
                0x00,
                0x30,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
            ],
        )
        assert msg.body[:-2] == expected_body
        msg.power = True
        msg.prompt_tone = False
        msg.mode = 2
        msg.target_temperature = 24.0
        msg.fan_speed = 92
        msg.swing_vertical = True
        msg.swing_horizontal = True
        msg.boost_mode = True
        msg.power_saving = True
        msg.smart_eye = True
        msg.dry = True
        msg.aux_heating = True
        msg.eco_mode = True
        msg.temp_fahrenheit = True
        msg.sleep_mode = True
        msg.natural_wind = True
        msg.frost_protect = True
        msg.comfort_mode = True
        expected_body[1] = 0x01
        expected_body[2] = (
            (0x02 << 5) & 0xE0 | (24 & 0xF) | (0x10 if 24 % 2 != 0 else 0)
        )
        expected_body[3] = 92 & 0x7F
        expected_body[7] = 0x30 | 0x0C | 0x03
        expected_body[8] = 0x20 | 0x08
        expected_body[9] = 0x01 | 0x04 | 0x08 | 0x80
        expected_body[10] = 0x04 | 0x01 | 0x02
        expected_body[17] = 0x40
        expected_body[21] = 0x80
        expected_body[22] = 0x01
        assert msg.body[:-2] == expected_body


class TestMessageACResponse:
    """Test Message AC Response."""

    @pytest.fixture(autouse=True)
    def _setup_header(self) -> None:
        """Do setup header."""
        self.header = bytearray(
            [
                0xAA,
                0x00,
                0xAC,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x01,
                0x05,
            ],
        )

    def test_message_notify2_a0(self) -> None:
        """Test Message parse notify2 A0."""
        body = bytearray(18)
        body[0] = 0xA0  # Body type
        body[1] = 0b01011111  # Power on, target temperature with 0.5 increment
        body[2] = 0b11100000  # Mode
        body[3] = 0b01111111  # Fan speed
        body[7] = 0b00001111  # Swing vertical and horizontal
        body[8] = 0b00101000  # Boost mode, power saving
        body[9] = 0b00011101  # Smart eye, dry, aux heating, eco mode
        body[10] = 0b01000011  # Sleep mode, natural wind
        body[13] = 0b00100000  # Full dust
        body[14] = 0b00000001  # Comfort mode

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "power")
        assert hasattr(response, "target_temperature")
        assert response.target_temperature == 27.5  # ((31 >> 1) - 4 + 16 + 0.5) = 27.5
        assert hasattr(response, "mode")
        assert response.mode == 7
        assert hasattr(response, "fan_speed")
        assert response.fan_speed == 127
        assert hasattr(response, "swing_vertical")
        assert hasattr(response, "swing_horizontal")
        assert hasattr(response, "boost_mode")
        assert hasattr(response, "power_saving")
        assert response.power_saving is True
        assert hasattr(response, "smart_eye")
        assert hasattr(response, "dry")
        assert hasattr(response, "aux_heating")
        assert hasattr(response, "eco_mode")
        assert hasattr(response, "sleep_mode")
        assert hasattr(response, "natural_wind")
        assert hasattr(response, "full_dust")
        assert hasattr(response, "comfort_mode")

    def test_message_notify2_a0_fresh_filter(self) -> None:
        """Test Message parse notify2 A0 with fresh filter bytes."""
        body = bytearray(30)  # stripped body length 29 >= FRESH_AIR_C0_MIN_LENGTH
        body[0] = 0xA0  # Body type
        body[13] = 0x40  # Fresh filter timeout bit
        body[15] = 0x20  # Fresh filter time use low byte
        body[16] = 0x02  # Fresh filter time use high byte
        body[24] = 0x10  # Fresh filter time total low byte
        body[25] = 0x01  # Fresh filter time total high byte

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "fresh_filter_time_total")
        assert response.fresh_filter_time_total == 0x01 * 256 + 0x10
        assert hasattr(response, "fresh_filter_time_use")
        assert response.fresh_filter_time_use == 0x02 * 256 + 0x20
        assert hasattr(response, "fresh_filter_timeout")
        assert response.fresh_filter_timeout == 1

    def test_message_notify1_a1(self) -> None:
        """Test Message parse notify1 A1."""
        self.header[9] = 0x04
        body = bytearray(22)
        body[0] = 0xA1  # Body type
        body[13] = 100  # Indoor temperature byte
        body[14] = 60  # Outdoor temperature byte
        body[17] = 50  # Indoor humidity byte
        body[18] = 0xF3  # Decimal part for temperature
        response = MessageACResponse(self.header + body)

        assert hasattr(response, "indoor_temperature")
        assert response.indoor_temperature == 25.3  # ((100 - 50) / 2) + 0.3 = 25.3
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature == 6.5  # ((60 - 50) / 2) + 1.5 = 6.5
        assert hasattr(response, "indoor_humidity")
        assert response.indoor_humidity == 50

        body[14] = 0xFF  # Outdoor temperature byte
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature is None

        body[13] = 48  # Indoor temperature byte
        body[14] = 40  # Outdoor temperature byte
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "indoor_temperature")
        assert response.indoor_temperature == -1.3  # ((49 - 50) / 2) - 0.3 = -1.3
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature == -6.5  # ((40 - 50) / 2) - 1.5 = -6.5

    def test_message_query_b5(self) -> None:
        """Test message query b5."""
        body = bytearray(
            [
                0xB5,
                0x05,
                0x15,  # indoor_humidity
                0x00,
                0x01,  # length
                0x00,  # value
                0x17,  # screen_display_alternate
                0x00,
                0x01,  # length
                0x00,  # value
                0x18,  # breezeless
                0x00,
                0x01,  # length
                0x00,  # value
                0x09,  # wind_ud_angle
                0x00,
                0x01,  # length
                0x00,  # value
                0x0A,  # wind_lr_angle
                0x00,
                0x01,  # length
                0x00,  # value
                0x01,
                0xD6,
            ],
        )
        response = MessageACResponse(self.header + body)
        # query message
        assert hasattr(response, "indoor_humidity")
        assert hasattr(response, "screen_display_alternate")
        assert hasattr(response, "breezeless")
        assert hasattr(response, "wind_ud_angle")
        assert hasattr(response, "wind_lr_angle")
        assert not hasattr(response, "indirect_wind")

    def test_message_notify2_b0(self) -> None:
        """Test Message parse notify2 B0."""
        body = bytearray(29)
        body[0] = 0xB0  # Body type
        body[1] = 0x05  # Params count
        body[2] = NewProtocolTags.indirect_wind & 0xFF  # Low byte param
        body[3] = NewProtocolTags.indirect_wind >> 8  # High byte param
        body[5] = 0x01  # Value length
        body[6] = 0x02  # Value True
        body[7] = NewProtocolTags.indoor_humidity & 0xFF  # Low byte param
        body[8] = NewProtocolTags.indoor_humidity >> 8  # High byte param
        body[10] = 0x01  # Value length
        body[11] = 30  # Value 30
        body[12] = NewProtocolTags.breezeless & 0xFF  # Low byte param
        body[13] = NewProtocolTags.breezeless >> 8  # High byte param
        body[15] = 0x01  # Value length
        body[16] = 0x01  # Value True
        body[17] = NewProtocolTags.screen_display & 0xFF  # Low byte param
        body[18] = NewProtocolTags.screen_display >> 8  # High byte param
        body[20] = 0x01  # Value length
        body[21] = 0x01  # Value True
        body[22] = NewProtocolTags.fresh_air_1 & 0xFF  # Low byte param
        body[23] = NewProtocolTags.fresh_air_1 >> 8  # High byte param
        body[25] = 0x02  # Value length
        body[26] = 0x02  # Value Power True
        body[27] = 10  # Value Speed 10

        response = MessageACResponse(self.header + body)

        assert hasattr(response, "indirect_wind")
        assert hasattr(response, "indoor_humidity")
        assert response.indoor_humidity == 30
        assert hasattr(response, "breezeless")
        assert hasattr(response, "screen_display_alternate")
        assert hasattr(response, "screen_display_new")
        assert hasattr(response, "fresh_air_1")
        assert hasattr(response, "fresh_air_power")
        assert hasattr(response, "fresh_air_fan_speed")
        assert response.fresh_air_fan_speed == 10

        body[22] = NewProtocolTags.fresh_air_2 & 0xFF  # Low byte param
        body[23] = NewProtocolTags.fresh_air_2 >> 8  # High byte param
        body[25] = 0x02  # Value length
        body[26] = 0x01  # Value Power True
        body[27] = 20  # Value Speed 20

        response = MessageACResponse(self.header + body)
        assert not hasattr(response, "fresh_air_1")
        assert hasattr(response, "fresh_air_2")
        assert hasattr(response, "fresh_air_power")
        assert hasattr(response, "fresh_air_fan_speed")
        assert response.fresh_air_fan_speed == 20

    def test_message_notify2_b0_rate_select(self) -> None:
        """Test Message parse notify2 B0 with rate_select."""
        body = bytearray(10)
        body[0] = 0xB0  # Body type
        body[1] = 0x01  # Params count
        body[2] = NewProtocolTags.rate_select & 0xFF  # Low byte 0x48
        body[3] = NewProtocolTags.rate_select >> 8  # High byte 0x00
        body[4] = 0x00  # Padding
        body[5] = 0x01  # Value length
        body[6] = 40  # Value 40

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "rate_select")
        assert response.rate_select == 40

    def test_message_query_b5_capabilities(self) -> None:
        """Test Message parse query B5 capabilities."""
        self.header[9] = 0x03
        body = bytearray([0xB5, 0x0B])  # Body type, params count
        body += bytearray([0x14, 0x02, 0x01, 7])  # b5_mode
        body += bytearray([0x15, 0x02, 0x01, 1])  # b5_wind_swing
        body += bytearray([0x10, 0x02, 0x01, 5])  # b5_wind_speed
        body += bytearray([0x12, 0x02, 0x01, 1])  # b5_eco
        body += bytearray([0x1E, 0x02, 0x01, 1])  # b5_anion
        body += bytearray([0x17, 0x02, 0x01, 1])  # b5_filter_remind
        body += bytearray([0x1A, 0x02, 0x01, 1])  # b5_strong_wind
        body += bytearray([0x25, 0x02, 0x07, 34, 60, 34, 60, 34, 60, 0])  # temperature
        body += bytearray([0x24, 0x02, 0x01, 1])  # b5_screen_display
        body += bytearray([0x2C, 0x02, 0x01, 1])  # b5_sound
        body += bytearray([0x1F, 0x02, 0x01, 1])  # b5_humidity
        body += bytearray(1)  # trailing checksum byte (stripped by MessageResponse)

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "b5_mode")
        assert response.b5_mode == 7
        assert hasattr(response, "b5_anion")
        assert response.b5_anion == 1
        assert hasattr(response, "b5_filter_remind")
        assert response.b5_filter_remind == 1
        assert hasattr(response, "b5_strong_wind")
        assert response.b5_strong_wind == 1
        assert hasattr(response, "b5_wind_speed")
        assert response.b5_wind_speed == 5
        assert hasattr(response, "b5_screen_display")
        assert response.b5_screen_display == 1
        assert hasattr(response, "b5_sound")
        assert response.b5_sound == 1
        assert hasattr(response, "b5_humidity")
        assert response.b5_humidity == 1
        assert hasattr(response, "b5_temperature0")
        assert response.b5_temperature0 == 34
        assert hasattr(response, "b5_temperature6")
        assert response.b5_temperature6 == 0
        assert hasattr(response, "temperature_limits")
        assert response.temperature_limits == {
            1: (17.0, 30.0),
            2: (17.0, 30.0),
            3: (17.0, 30.0),
            4: (17.0, 30.0),
            5: (17.0, 30.0),
        }
        assert hasattr(response, "capabilities")
        assert response.capabilities == {
            "heat_mode": True,
            "cool_mode": True,
            "dry_mode": False,
            "auto_mode": True,
            "swing_horizontal": True,
            "swing_vertical": True,
            "fan_silent": False,
            "fan_low": True,
            "fan_medium": True,
            "fan_high": True,
            "fan_auto": True,
            "fan_custom": False,
            "eco": True,
            "anion": True,
            "turbo_cool": True,
            "turbo_heat": True,
            "display_control": True,
        }

    def test_message_query_b5_custom_fan_supports_named_speeds(self) -> None:
        """Test B5 fan custom profile includes named fan speeds."""
        self.header[9] = 0x03
        body = bytearray([0xB5, 0x01])  # Body type, params count
        body += bytearray([0x10, 0x02, 0x01, 1])  # b5_wind_speed: fan_custom
        body += bytearray(1)  # trailing checksum byte (stripped by MessageResponse)

        response = MessageACResponse(self.header + body)

        assert hasattr(response, "capabilities")
        assert response.capabilities == {
            "fan_silent": True,
            "fan_low": True,
            "fan_medium": True,
            "fan_high": True,
            "fan_auto": True,
            "fan_custom": True,
        }

    def test_message_query_b5_value_9_fan_supports_silent_low_high_auto(
        self,
    ) -> None:
        """Test B5 fan profile 9 includes silent, low, high, and auto."""
        self.header[9] = 0x03
        body = bytearray([0xB5, 0x01])  # Body type, params count
        body += bytearray([0x10, 0x02, 0x01, 9])  # b5_wind_speed: profile 9
        body += bytearray(1)  # trailing checksum byte (stripped by MessageResponse)

        response = MessageACResponse(self.header + body)

        assert hasattr(response, "capabilities")
        assert response.capabilities == {
            "fan_silent": True,
            "fan_low": True,
            "fan_medium": False,
            "fan_high": True,
            "fan_auto": True,
            "fan_custom": False,
        }

    @pytest.mark.parametrize(
        ("raw_value", "expected"),
        [(0x03, True), (0x00, False)],
    )
    def test_message_notify2_b0_out_silent(
        self,
        raw_value: int,
        expected: bool,
    ) -> None:
        """Test Message parse notify2 B0 with out_silent."""
        body = bytearray(10)
        body[0] = 0xB0  # Body type
        body[1] = 0x01  # Params count
        body[2] = NewProtocolTags.out_silent & 0xFF  # Low byte 0xCD
        body[3] = NewProtocolTags.out_silent >> 8  # High byte 0x00
        body[4] = 0x00  # Padding
        body[5] = 0x01  # Value length
        body[6] = raw_value

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "out_silent")
        assert response.out_silent is expected

    @pytest.mark.parametrize(
        ("byte12", "expected"),
        [(0x3C, True), (0x00, False)],
    )
    def test_message_notify2_b5_self_clean_active(
        self,
        byte12: int,
        expected: bool,
    ) -> None:
        """Test Message parse notify2 B5 with self_clean_active."""
        # B5 push body: body_type(1) + count(1) + tag(2) + length(1) + value(39)
        payload = bytearray(39)
        payload[12] = byte12
        body = bytearray(2)
        body[0] = 0xB5  # Body type
        body[1] = 0x01  # Params count
        body += bytearray(
            [
                NewProtocolTags.b5_self_clean_active & 0xFF,  # tag low 0xE2
                NewProtocolTags.b5_self_clean_active >> 8,  # tag high 0x00
                len(payload),  # length 39
            ],
        )
        body += payload
        body += bytearray(1)  # trailing checksum byte (stripped by MessageResponse)

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "self_clean_active")
        assert response.self_clean_active is expected

    def test_message_query_c0(self) -> None:
        """Test Message parse query C0."""
        self.header[9] = 0x03
        body = bytearray(24)
        body[0] = 0xC0  # Body type
        body[1] = 0b00000001  # Power on
        body[2] = 0b10101110  # Mode (5), target temperature (14), 0.5 increment
        body[3] = 0b01111111  # Fan speed
        body[7] = 0b00001111  # Swing vertical and horizontal
        body[8] = 0b01101000  # Boost mode, smart eye, power saving
        body[9] = 0b00011110  # Natural wind, dry, eco mode, aux heating
        body[10] = 0b01000111  # Sleep mode, temp Fahrenheit, boost mode (alternative)
        body[11] = 0x64  # Indoor temperature byte
        body[12] = 0x64  # Outdoor temperature byte
        body[13] = 0b00100000  # Full dust
        body[14] = 0b01110000  # Screen display
        body[15] = 0b00110010  # Decimal parts for temperature
        body[21] = 0b10000000  # Frost protect
        body[22] = 0b00000001  # Comfort mode

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "power")
        assert hasattr(response, "mode")
        assert response.mode == 5
        assert hasattr(response, "target_temperature")
        assert response.target_temperature == 30  # 14 + 16
        assert hasattr(response, "fan_speed")
        assert response.fan_speed == 127
        assert hasattr(response, "swing_vertical")
        assert hasattr(response, "swing_horizontal")
        assert hasattr(response, "boost_mode")
        assert hasattr(response, "power_saving")
        assert response.power_saving is True
        assert hasattr(response, "smart_eye")
        assert hasattr(response, "natural_wind")
        assert hasattr(response, "dry")
        assert hasattr(response, "eco_mode")
        assert hasattr(response, "aux_heating")
        assert hasattr(response, "temp_fahrenheit")
        assert hasattr(response, "sleep_mode")
        assert hasattr(response, "indoor_temperature")
        assert response.indoor_temperature == 25.2  # ((100 - 50) / 2) + 0.2
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature == 25.3  # ((100 - 50) / 2) + 0.3
        assert hasattr(response, "full_dust")
        assert hasattr(response, "screen_display")
        assert response.screen_display is False
        assert hasattr(response, "frost_protect")
        assert hasattr(response, "comfort_mode")

        body[11] = 40  # Indoor temperature byte
        body[12] = 40  # Outdoor temperature byte
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "indoor_temperature")
        assert response.indoor_temperature == -5.2  # ((40 - 50) / 2) - 0.2
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature == -5.3  # ((40 - 50) / 2) - 0.3

        body[12] = 0xFF  # Outdoor temperature byte
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature is None

    def test_message_query_c0_fresh_filter(self) -> None:
        """Test Message parse query C0 with fresh filter bytes."""
        self.header[9] = 0x03
        body = bytearray(30)  # stripped body length 29 >= FRESH_AIR_C0_MIN_LENGTH
        body[0] = 0xC0  # Body type
        body[13] = 0x40  # Fresh filter timeout bit
        body[24] = 0x10  # Fresh filter time total low byte
        body[25] = 0x01  # Fresh filter time total high byte
        body[26] = 0x20  # Fresh filter time use low byte
        body[27] = 0x02  # Fresh filter time use high byte

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "fresh_filter_time_total")
        assert response.fresh_filter_time_total == 0x01 * 256 + 0x10
        assert hasattr(response, "fresh_filter_time_use")
        assert response.fresh_filter_time_use == 0x02 * 256 + 0x20
        assert hasattr(response, "fresh_filter_timeout")
        assert response.fresh_filter_timeout == 1

    def test_message_query_c1_0x45(self) -> None:
        """Test Message parse query C1 0x45 indoor humidity."""
        self.header[9] = 0x03
        body = bytearray(20)
        body[0] = 0xC1  # Body type
        body[3] = 0x45  # Set the type to 0x45
        body[4] = 55  # Indoor humidity
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "indoor_humidity")
        assert response.indoor_humidity == 55

        body[4] = 0  # Indoor humidity unavailable
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "indoor_humidity")
        assert response.indoor_humidity is None

    def test_message_query_c1_unknown_method(self) -> None:
        """Test Message parse query C1 with an unknown analysis method."""
        self.header[9] = 0x03
        body = bytearray(20)
        body[0] = 0xC1  # Body type
        body[3] = 0x44  # Set the type to 0x44
        body[4] = 0x12  # Total energy consumption byte, ignored
        body[16] = 0x11  # Real-time power byte, ignored
        response = MessageACResponse(self.header + body, 5)
        assert hasattr(response, "total_energy_consumption")
        assert response.total_energy_consumption == 0.0
        assert hasattr(response, "current_energy_consumption")
        assert response.current_energy_consumption == 0.0
        assert hasattr(response, "realtime_power")
        assert response.realtime_power == 0.0

    def test_message_query_c1_method1(self) -> None:
        """Test Message parse query C1 method1."""
        self.header[9] = 0x03
        body = bytearray(20)
        body[0] = 0xC1  # Body type
        body[3] = 0x44  # Set the type to 0x44

        # Total energy consumption bytes
        body[4] = 0x12  # High nibble: 1, Low nibble: 2 (value: 12)
        body[5] = 0x34  # High nibble: 3, Low nibble: 4 (value: 34)
        body[6] = 0x56  # High nibble: 5, Low nibble: 6 (value: 56)
        body[7] = 0x78  # High nibble: 7, Low nibble: 8 (value: 78)
        expected_total_energy = float(12 * 1000000 + 34 * 10000 + 56 * 100 + 78) / 100

        # Current energy consumption bytes
        body[12] = 0x87  # High nibble: 8, Low nibble: 7 (value: 87)
        body[13] = 0x65  # High nibble: 6, Low nibble: 5 (value: 65)
        body[14] = 0x43  # High nibble: 4, Low nibble: 3 (value: 43)
        body[15] = 0x21  # High nibble: 2, Low nibble: 1 (value: 21)
        expected_current_energy = float(87 * 1000000 + 65 * 10000 + 43 * 100 + 21) / 100

        # Real-time power bytes
        body[16] = 0x11  # High nibble: 1, Low nibble: 1 (value: 11)
        body[17] = 0x22  # High nibble: 2, Low nibble: 2 (value: 22)
        body[18] = 0x33  # High nibble: 3, Low nibble: 3 (value: 33)
        expected_realtime_power = float(11 * 10000 + 22 * 100 + 33) / 10

        response = MessageACResponse(self.header + body, 1)

        assert hasattr(response, "total_energy_consumption")
        assert response.total_energy_consumption == expected_total_energy
        assert hasattr(response, "current_energy_consumption")
        assert response.current_energy_consumption == expected_current_energy
        assert hasattr(response, "realtime_power")
        assert response.realtime_power == expected_realtime_power

    def _assert_message_query_c1_method2(self, method: int) -> None:
        """Assert Message parse query C1 method2 (and 12)."""
        self.header[9] = 0x03
        body = bytearray(20)
        body[0] = 0xC1  # Body type
        body[3] = 0x44  # Set the type to 0x44

        # method 12 is like 2, but with 0.01kWh resolution instead of 0.1kWh
        energy_divisor = 10 if method == 2 else 100

        # Total energy consumption bytes
        body[4] = 0x01
        body[5] = 0x23
        body[6] = 0x45
        body[7] = 0x67
        expected_total_energy = (
            float((0x01 << 24) + (0x23 << 16) + (0x45 << 8) + 0x67) / energy_divisor
        )

        # Current energy consumption bytes
        body[12] = 0x89
        body[13] = 0xAB
        body[14] = 0xCD
        body[15] = 0xEF
        expected_current_energy = (
            float((0x89 << 24) + (0xAB << 16) + (0xCD << 8) + 0xEF) / energy_divisor
        )

        # Real-time power bytes
        body[16] = 0x12
        body[17] = 0x34
        body[18] = 0x56
        expected_realtime_power = float((0x12 << 16) + (0x34 << 8) + 0x56) / 10

        response = MessageACResponse(self.header + body, method)

        assert hasattr(response, "total_energy_consumption")
        assert response.total_energy_consumption == expected_total_energy
        assert hasattr(response, "current_energy_consumption")
        assert response.current_energy_consumption == expected_current_energy
        assert hasattr(response, "realtime_power")
        assert response.realtime_power == expected_realtime_power

    def test_message_query_c1_method2(self) -> None:
        """Test Message parse query C1 method2."""
        self._assert_message_query_c1_method2(2)

    def test_message_query_c1_method12(self) -> None:
        """Test Message parse query C1 method12."""
        self._assert_message_query_c1_method2(12)

    def test_message_query_c1_bcd_energy_binary_power(self) -> None:
        """Test C1 format with BCD energy counters and binary realtime watts."""
        self.header[9] = 0x03
        samples = [
            (
                "c12101440000005800000000000000160016b700000001a9",
                0.58,
                0.16,
                581.5,
            ),
            (
                "c12101440000005900000000000000170016a30000000105",
                0.59,
                0.17,
                579.5,
            ),
            (
                "c12101440000005a000000000000001800162b0000000187",
                0.60,
                0.18,
                567.5,
            ),
        ]

        for payload, total_kwh, current_kwh, watts in samples:
            response = MessageACResponse(
                self.header + bytearray.fromhex(payload),
                PowerFormats.BCD_ENERGY_BINARY_POWER,
            )

            assert hasattr(response, "total_energy_consumption")
            assert response.total_energy_consumption == total_kwh
            assert hasattr(response, "current_energy_consumption")
            assert response.current_energy_consumption == current_kwh
            assert hasattr(response, "realtime_power")
            assert response.realtime_power == watts

    def test_message_query_c1_method3(self) -> None:
        """Test Message parse query C1 method3."""
        self.header[9] = 0x03
        body = bytearray(20)
        body[0] = 0xC1  # Body type
        body[3] = 0x44  # Set the type to 0x44
        # Total energy consumption bytes
        body[4] = 0x12
        body[5] = 0x34
        body[6] = 0x56
        body[7] = 0x78
        expected_total_energy = (
            float(0x12 * 1000000 + 0x34 * 10000 + 0x56 * 100 + 0x78) / 100
        )

        # Current energy consumption bytes
        body[12] = 0x87
        body[13] = 0x65
        body[14] = 0x43
        body[15] = 0x21
        expected_current_energy = (
            float(0x87 * 1000000 + 0x65 * 10000 + 0x43 * 100 + 0x21) / 100
        )
        # Real-time power bytes
        body[16] = 0x11
        body[17] = 0x22
        body[18] = 0x33
        expected_realtime_power = float(0x11 * 10000 + 0x22 * 100 + 0x33) / 10
        response = MessageACResponse(self.header + body)

        assert hasattr(response, "total_energy_consumption")
        assert response.total_energy_consumption == expected_total_energy
        assert hasattr(response, "current_energy_consumption")
        assert response.current_energy_consumption == expected_current_energy
        assert hasattr(response, "realtime_power")
        assert response.realtime_power == expected_realtime_power

    def test_message_query_c1_0x40(self) -> None:
        """Test Message parse query C1 0x40."""
        self.header[9] = 0x03
        body = bytearray(20)
        body[0] = 0xC1  # Body type
        body[3] = 0x40
        response = MessageACResponse(self.header + body)
        assert not hasattr(response, "total_energy_consumption")
        assert not hasattr(response, "current_energy_consumption")
        assert not hasattr(response, "realtime_power")

    def test_message_query_c1_0x41(self) -> None:
        """Test Message parse query C1 0x41, compressor group data."""
        self.header[9] = 0x03
        body = bytearray(20)
        body[0] = 0xC1  # Body type
        body[3] = 0x41  # group 1
        body[4] = 28  # compressor frequency
        body[5] = 25  # target compressor frequency
        body[7] = 1  # compressor current
        body[8] = 232  # compressor voltage
        body[10] = 71  # T1: (71 - 30) / 2 = 20.5
        body[11] = 38  # T2: (38 - 30) / 2 = 4.0
        body[12] = 102  # T3: (102 - 50) / 2 = 26.0
        body[13] = 88  # T4: (88 - 50) / 2 = 19.0
        body[14] = 36  # TP: 36

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "compressor_frequency")
        assert response.compressor_frequency == 28
        assert hasattr(response, "target_compressor_frequency")
        assert response.target_compressor_frequency == 25
        assert hasattr(response, "compressor_current")
        assert response.compressor_current == 1
        assert hasattr(response, "compressor_voltage")
        assert response.compressor_voltage == 232
        assert hasattr(response, "indoor_ambient_temperature")
        assert response.indoor_ambient_temperature == 20.5
        assert hasattr(response, "indoor_coil_temperature")
        assert response.indoor_coil_temperature == 4.0
        assert hasattr(response, "outdoor_coil_temperature")
        assert response.outdoor_coil_temperature == 26.0
        assert hasattr(response, "outdoor_ambient_temperature")
        assert response.outdoor_ambient_temperature == 19.0
        assert hasattr(response, "discharge_pipe_temperature")
        assert response.discharge_pipe_temperature == 36

    def test_message_query_c1_0x41_short_body(self) -> None:
        """Test Message parse query C1 0x41 with a truncated body."""
        self.header[9] = 0x03
        body = bytearray(10)
        body[0] = 0xC1  # Body type
        body[3] = 0x41  # group 1

        response = MessageACResponse(self.header + body)
        assert not hasattr(response, "compressor_frequency")
        assert not hasattr(response, "discharge_pipe_temperature")

    def test_message_query_c1_0x42(self) -> None:
        """Test Message parse query C1 0x42, indoor fan group data."""
        self.header[9] = 0x03
        body = bytearray(20)
        body[0] = 0xC1  # Body type
        body[3] = 0x42  # group 2
        body[4] = 52  # target indoor fan speed: 52 * 8 = 416
        body[5] = 53  # indoor fan speed: 53 * 8 = 424
        body[8] = 0x10  # water pump running

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "target_indoor_fan_speed")
        assert response.target_indoor_fan_speed == 416
        assert hasattr(response, "indoor_fan_speed")
        assert response.indoor_fan_speed == 424
        assert hasattr(response, "water_pump_running")
        assert response.water_pump_running is True

    def test_message_query_c1_0x42_idle(self) -> None:
        """Test Message parse query C1 0x42 with fan and pump stopped."""
        self.header[9] = 0x03
        body = bytearray(20)
        body[0] = 0xC1  # Body type
        body[3] = 0x42  # group 2

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "indoor_fan_speed")
        assert response.indoor_fan_speed == 0
        assert hasattr(response, "water_pump_running")
        assert response.water_pump_running is False

    def test_message_query_c1_0x42_short_body(self) -> None:
        """Test Message parse query C1 0x42 with a truncated body."""
        self.header[9] = 0x03
        body = bytearray(9)
        body[0] = 0xC1  # Body type
        body[3] = 0x42  # group 2

        response = MessageACResponse(self.header + body)
        assert not hasattr(response, "indoor_fan_speed")
        assert not hasattr(response, "water_pump_running")

    def test_message_query_c1_0x47(self) -> None:
        """Test Message parse query C1 0x47, compressor power group data."""
        self.header[9] = 0x03
        body = bytearray(20)
        body[0] = 0xC1  # Body type
        body[3] = 0x47  # group 7
        body[10] = 13  # 13 + (1 << 8) = 269 W
        body[11] = 1

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "compressor_power")
        assert response.compressor_power == 269

    def test_message_query_c1_0x47_short_body(self) -> None:
        """Test Message parse query C1 0x47 with a truncated body."""
        self.header[9] = 0x03
        body = bytearray(10)
        body[0] = 0xC1  # Body type
        body[3] = 0x47  # group 7

        response = MessageACResponse(self.header + body)
        assert not hasattr(response, "compressor_power")

    def test_captured_c1_0x41_response(self) -> None:
        """Test a complete response captured from model 22390001 subtype 8."""
        frame = bytearray.fromhex(
            "aa29ac00000000000803c12101412b2b0403d6005446736c2600000000000000"
            "00000000000000019e8b",
        )

        response = MessageACResponse(frame)

        assert hasattr(response, "compressor_frequency")
        assert response.compressor_frequency == 43
        assert hasattr(response, "target_compressor_frequency")
        assert response.target_compressor_frequency == 43
        assert hasattr(response, "compressor_current")
        assert response.compressor_current == 3
        assert hasattr(response, "compressor_voltage")
        assert response.compressor_voltage == 214

    def test_short_c1_response_does_not_raise(self) -> None:
        """Test short C1 response ignores a missing group type."""
        self.header[9] = 0x03

        MessageACResponse(self.header + bytearray([0xC1, 0, 0]))

    @pytest.mark.parametrize("group_type", [0x40, 0x41, 0x42, 0x44, 0x45, 0x47])
    def test_recognized_short_c1_response_does_not_raise(
        self,
        group_type: int,
    ) -> None:
        """Test recognized C1 groups ignore fields missing from a short frame."""
        self.header[9] = 0x03
        body = bytearray([0xC1, 0, 0, group_type])

        MessageACResponse(self.header + body + bytearray([0]))

    def test_message_query_bb_0x20(self) -> None:
        """Test Message parse query BB 0x20."""
        self.header[9] = 0x03
        body = bytearray(100)
        body[:6] = bytearray([0xBB, 0, 0, 0, 0, 0x20])  # Set the header and data type
        body[6] = 0b00110001  # Power, dry, boost_mode
        body[7] = 0b01000000  # aux_heating
        body[8] = 0b10000000  # sleep_mode
        body[11] = 2  # Mode index for BB_AC_MODES
        body[12] = 0x3C  # Target temperature: ((60 - 30) / 2) = 15.0
        body[13] = 127  # Fan speed
        body[31] = 0b01000100  # Timer, eco_mode

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "power")
        assert hasattr(response, "dry")
        assert hasattr(response, "boost_mode")
        assert hasattr(response, "aux_heating")
        assert hasattr(response, "sleep_mode")
        assert hasattr(response, "mode")
        assert response.mode == 1
        assert hasattr(response, "target_temperature")
        assert response.target_temperature == 15.0
        assert hasattr(response, "fan_speed")
        assert response.fan_speed == 127
        assert hasattr(response, "timer")
        assert hasattr(response, "eco_mode")

        body[11] = 10  # Invalid mode index for BB_AC_MODES
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "mode")
        assert response.mode == 0

    def test_message_query_bb_0x11_fresh_air(self) -> None:
        """Test BB basic status parses independent intake and exhaust airflow."""
        self.header[9] = 0x03
        body = bytearray(56)
        body[:6] = bytearray([0xBB, 0, 0, 0, 0, 0x11])
        body[51] = 0x03
        body[52] = 60
        body[53] = 100

        response = MessageACResponse(self.header + body)

        assert hasattr(response, "bb_fresh_air_power")
        assert response.bb_fresh_air_power is True
        assert hasattr(response, "bb_fresh_air_fan_speed")
        assert response.bb_fresh_air_fan_speed == 60
        assert hasattr(response, "bb_fresh_air_exhaust_power")
        assert response.bb_fresh_air_exhaust_power is True
        assert hasattr(response, "bb_fresh_air_exhaust_speed")
        assert response.bb_fresh_air_exhaust_speed == 100

    def test_captured_bb_0x11_fresh_air_response(self) -> None:
        """Test a complete fresh-air response captured from model 23096633."""
        frame = bytearray.fromhex(
            "aa5aac00000000000803bb5000ffff1101800000000057663200000000320001"
            "2800007804523266000400000000000000000000000000000000000000413c64"
            "0000002f000001e00000400003002828003000000000000046b7ef",
        )

        response = MessageACResponse(frame)

        assert hasattr(response, "bb_fresh_air_power")
        assert response.bb_fresh_air_power is True
        assert hasattr(response, "bb_fresh_air_fan_speed")
        assert response.bb_fresh_air_fan_speed == 60
        assert hasattr(response, "bb_fresh_air_exhaust_power")
        assert response.bb_fresh_air_exhaust_power is False
        assert hasattr(response, "bb_fresh_air_exhaust_speed")
        assert response.bb_fresh_air_exhaust_speed == 100

    def test_message_query_bb_0x10(self) -> None:
        """Test Message parse query BB 0x20."""
        self.header[9] = 0x03
        body = bytearray(100)
        body[:6] = bytearray([0xBB, 0, 0, 0, 0, 0x10])  # Set the header and data type
        body[14] = 0x88  # Indoor temperature byte 2
        body[13] = 0x77  # Indoor temperature byte 1
        body[36] = 60  # Indoor humidity
        body[86] = 0x31  # sn8_flag

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "indoor_temperature")
        assert response.indoor_temperature == 349.35
        assert hasattr(response, "indoor_humidity")
        assert response.indoor_humidity == 60
        assert hasattr(response, "sn8_flag")

        body[14] = 0x78  # Indoor temperature byte 2
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "indoor_temperature")
        assert response.indoor_temperature == 308.39

    def test_message_query_bb_0x30(self) -> None:
        """Test Message parse query BB 0x30."""
        self.header[9] = 0x03
        body = bytearray(100)
        body[:6] = bytearray([0xBB, 0, 0, 0, 0, 0x30])  # Set the header and data type
        body[11] = 0x22  # Outdoor temperature byte 1
        body[12] = 0x80  # Outdoor temperature byte 2
        body[16] = 49  # Compressor target frequency
        body[17] = 47  # Compressor actual frequency

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature == 328.02
        assert hasattr(response, "target_compressor_frequency")
        assert response.target_compressor_frequency == 49
        assert hasattr(response, "compressor_frequency")
        assert response.compressor_frequency == 47

        body[12] = 0x65  # Outdoor temperature byte 2

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature == 258.9

    def test_captured_bb_0x30_frequency_response(self) -> None:
        """Test a complete frequency response captured from model 23096633."""
        frame = bytearray.fromhex(
            "aa6aac00000000000803bb6000ffff3000ff000000a60e8e12433131c000079b"
            "0000000000000000000000630000000000000000000000000000000000000000"
            "0000000000000000000000000000000000000000000000000000000000000000"
            "002f000000000000e5e6df",
        )

        assert len(frame) == frame[1] + 1
        assert len(frame[10:-1]) == frame[11]
        assert calculate(frame[10:-2]) == 0
        assert MessageBase.checksum(frame[1:-1]) == frame[-1]

        response = MessageACResponse(frame)

        assert hasattr(response, "target_compressor_frequency")
        assert response.target_compressor_frequency == 49
        assert hasattr(response, "compressor_frequency")
        assert response.compressor_frequency == 49

    @pytest.mark.parametrize("data_type", [0x10, 0x30])
    def test_short_bb_response_does_not_raise(
        self,
        data_type: int,
    ) -> None:
        """Test short BB responses enter parsing without reading absent fields."""
        self.header[9] = 0x03
        body = bytearray(21)
        body[:6] = bytearray([0xBB, 0, 0, 0, 0, data_type])

        response = MessageACResponse(self.header + body + bytearray([0]))

        assert response.used_subprotocol is True
        if data_type == 0x10:
            assert not hasattr(response, "indoor_humidity")
            assert not hasattr(response, "sn8_flag")

    def test_message_query_bb_unimplemented(self) -> None:
        """Test Message parse query BB unimplemented."""
        self.header[9] = 0x03
        body = bytearray(100)
        body[:6] = bytearray([0xBB, 0, 0, 0, 0, 0x12])  # Set the header and data type
        response = MessageACResponse(self.header + body)
        assert not hasattr(response, "power")

        body[5] = 0x13
        response = MessageACResponse(self.header + body)
        assert not hasattr(response, "power")

    def test_message_query_c0_anion(self) -> None:
        """Test anion parsed from C0 body (purifier bit 0x20 in byte 9)."""
        self.header[9] = 0x03
        body = bytearray(24)
        body[0] = 0xC0
        body[9] = 0x20  # purifier/anion bit set
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "anion")
        assert response.anion is True

        body[9] = 0x00
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "anion")
        assert response.anion is False

    def test_message_query_c0_pmv(self) -> None:
        """Test PMV parsed from C0 body (low nibble of byte 14)."""
        self.header[9] = 0x03
        body = bytearray(24)
        body[0] = 0xC0
        body[14] = 0x07  # PMV nibble = 7 → 7*0.5 - 3.5 = 0.0
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "pmv")
        assert response.pmv == 0.0

        body[14] = 0x00  # PMV nibble = 0 → 0*0.5 - 3.5 = -3.5
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "pmv")
        assert response.pmv == -3.5

    def test_message_b1_error_code(self) -> None:
        """Test error_code parsed from B1 response."""
        self.header[9] = 0x03
        body = bytearray(10)
        body[0] = 0xB1
        body[1] = 0x01  # 1 param
        body[2] = NewProtocolQuery.error_code_query & 0xFF
        body[3] = NewProtocolQuery.error_code_query >> 8
        body[4] = 0x00  # padding
        body[5] = 0x01  # length
        body[6] = 0x05  # error code 5
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "error_code")
        assert response.error_code == 5

    def test_message_b1_sound(self) -> None:
        """Test sound parsed from B1 response (buzzer_all tag)."""
        self.header[9] = 0x03
        body = bytearray(10)
        body[0] = 0xB1
        body[1] = 0x01
        body[2] = NewProtocolTags.buzzer_all & 0xFF
        body[3] = NewProtocolTags.buzzer_all >> 8
        body[4] = 0x00
        body[5] = 0x01
        body[6] = 0x01  # sound on
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "sound")
        assert response.sound is True

        body[6] = 0x00
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "sound")
        assert response.sound is False

    def test_message_b5_notify2_0x7e_temperature_parse(self) -> None:
        """Test 0x7e tag parsing for the model-22013279 temperature layout."""
        self.header[9] = 0x05
        body = bytearray(62)
        body[0] = 0xB5
        body[1] = 0x01
        body[2] = 0x7E
        body[3] = 0x00
        body[4] = 0x38

        # 0x7e payload (56 bytes)
        payload = bytearray(
            [
                0xA0,
                0x1D,  # (_t[1] & 0x3F)/2 + 11.5 -> 26.0
                0x41,
                0x66,
                0x7F,
                0x7F,
                0x00,
                0x00,
                0x00,
                0x04,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x78,
                0x00,
                0x4C,
                0x00,
                0xC0,
                0x00,
                0x00,
                0x00,
                0x00,
                0x64,
                0x00,
                0x64,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x6A,
                0x08,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x05,
                0x00,
            ],
        )
        body[5 : 5 + len(payload)] = payload

        response = MessageACResponse(self.header + body, new_protocol_temperature=True)
        assert hasattr(response, "has_new_protocol_temperature")
        assert response.has_new_protocol_temperature is True
        assert hasattr(response, "target_temperature")
        assert response.target_temperature == 26.0
        assert hasattr(response, "indoor_temperature")
        assert response.indoor_temperature == 28.8
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature is None

    def test_message_b5_notify2_0x7e_temperature_parse_fallback(self) -> None:
        """Fallback to legacy byte-3 mapping when byte-1 decoding is out of range."""
        self.header[9] = 0x05
        body = bytearray(62)
        body[0] = 0xB5
        body[1] = 0x01
        body[2] = 0x7E
        body[3] = 0x00
        body[4] = 0x38

        payload = bytearray(
            [
                0xA0,
                0x7F,  # byte-1 mapping would exceed sane range (>40)
                0x41,
                0x64,  # fallback byte-3 mapping -> (100 - 50) / 2 = 25.0
                0x7F,
                0x7F,
                0x00,
                0x00,
                0x00,
                0x04,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x78,
                0x00,
                0x4C,
                0x00,
                0xC0,
                0x00,
                0x00,
                0x00,
                0x00,
                0x64,
                0x00,
                0x64,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x6A,
                0x08,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x05,
                0x00,
            ],
        )
        body[5 : 5 + len(payload)] = payload

        response = MessageACResponse(self.header + body, new_protocol_temperature=True)
        assert hasattr(response, "target_temperature")
        assert response.target_temperature == 25.0

    def test_message_b5_notify2_0x7e_temperature_parse_fallback_invalid(self) -> None:
        """Fallback to legacy byte-3 mapping when byte-1 decoding is out of range."""
        self.header[9] = 0x05
        body = bytearray(62)
        body[0] = 0xB5
        body[1] = 0x01
        body[2] = 0x7E
        body[3] = 0x00
        body[4] = 0x38

        payload = bytearray(
            [
                0xA0,
                0x7F,  # byte-1 mapping would exceed sane range (>40)
                0x41,
                0x88,  # fallback byte-3 mapping -> (136 - 50) / 2 = 43.0 (>40)
                0x7F,
                0x7F,
                0x00,
                0x00,
                0x00,
                0x04,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x78,
                0x00,
                0x4C,
                0x00,
                0xC0,
                0x00,
                0x00,
                0x00,
                0x00,
                0x64,
                0x00,
                0x64,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x6A,
                0x08,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x05,
                0x00,
            ],
        )
        body[5 : 5 + len(payload)] = payload

        response = MessageACResponse(self.header + body, new_protocol_temperature=True)
        assert not hasattr(response, "target_temperature")

    def test_message_b5_notify2_0x7e_rejects_invalid_indoor_temperature(
        self,
    ) -> None:
        """Ignore a 0x7e payload whose decoded indoor temperature is invalid."""
        self.header[9] = 0x05
        body = bytearray(62)
        body[0] = 0xB5
        body[1] = 0x01
        body[2] = 0x7E
        body[3] = 0x00
        body[4] = 0x38
        payload = bytearray(56)
        payload[1] = 0x1D  # valid 26.0 C setpoint
        payload[40] = 0x00  # decodes to the reported invalid -25.0 C
        body[5 : 5 + len(payload)] = payload

        response = MessageACResponse(self.header + body, new_protocol_temperature=True)

        assert not hasattr(response, "has_new_protocol_temperature")
        assert not hasattr(response, "target_temperature")
        assert not hasattr(response, "indoor_temperature")
        assert not hasattr(response, "outdoor_temperature")

    def test_message_b5_notify2_0x7e_temperature_too_short(self) -> None:
        """Test the 0x7e tag is ignored when shorter than the expected payload."""
        self.header[9] = 0x05
        body = bytearray(16)
        body[0] = 0xB5
        body[1] = 0x01
        body[2] = 0x7E
        body[3] = 0x00
        body[4] = 0x0A  # length 10, at/below NEW_PROTOCOL_TEMPERATURE_MIN_LENGTH
        body[5 : 5 + 10] = bytearray(10)

        response = MessageACResponse(self.header + body, new_protocol_temperature=True)
        assert not hasattr(response, "has_new_protocol_temperature")
        assert not hasattr(response, "target_temperature")
        assert not hasattr(response, "indoor_temperature")
        assert not hasattr(response, "outdoor_temperature")

    def test_message_b5_notify2_0x7e_ignored_without_temperature_gate(self) -> None:
        """Test the 0x7e tag is ignored without the model-specific gate."""
        self.header[9] = 0x05
        body = bytearray(62)
        body[0] = 0xB5
        body[1] = 0x01
        body[2] = 0x7E
        body[3] = 0x00
        body[4] = 0x38
        payload = bytearray(56)
        payload[1] = 0x1D  # decodes to a plausible 26.0 C setpoint
        payload[40] = 0x6A  # decodes to a plausible 28.8 C indoor temperature
        payload[41] = 0x08
        body[5 : 5 + len(payload)] = payload

        response = MessageACResponse(self.header + body)

        # The payload decodes to in-range temperatures, so only the subtype
        # gate keeps another model's unrelated 0x7e content out.
        assert not hasattr(response, "has_new_protocol_temperature")
        assert not hasattr(response, "target_temperature")
        assert not hasattr(response, "indoor_temperature")
        assert not hasattr(response, "outdoor_temperature")


class TestMessageNewProtocolSetNewFeatures:
    """Test MessageNewProtocolSet for sound and self_clean."""

    @pytest.mark.parametrize(
        ("value", "expected_byte"),
        [(True, 0x01), (False, 0x00)],
    )
    def test_sound_on_off(self, value: bool, expected_byte: int) -> None:
        """Test sound set to on/off sends correct byte."""
        msg = MessageNewProtocolSet(protocol_version=ProtocolVersion.V1)
        msg.sound = value
        body = msg.body
        assert body[0] == 0xB0
        assert body[1] == 0x01
        assert body[2] == NewProtocolTags.buzzer_all & 0xFF
        assert body[3] == NewProtocolTags.buzzer_all >> 8
        assert body[4] == 0x01
        assert body[5] == expected_byte

    @pytest.mark.parametrize(
        ("value", "expected_byte"),
        [(True, 0x01), (False, 0x00)],
    )
    def test_self_clean_on_off(self, value: bool, expected_byte: int) -> None:
        """Test self_clean set to on/off sends correct byte."""
        msg = MessageNewProtocolSet(protocol_version=ProtocolVersion.V1)
        msg.self_clean = value
        body = msg.body
        assert body[0] == 0xB0
        assert body[1] == 0x01
        assert body[2] == NewProtocolTags.self_clean & 0xFF
        assert body[3] == NewProtocolTags.self_clean >> 8
        assert body[4] == 0x01
        assert body[5] == expected_byte


class TestMessageGeneralSetAnion:
    """Test MessageGeneralSet anion (purifier) bit."""

    @pytest.mark.parametrize(
        ("value", "expected_bit"),
        [(True, 0x20), (False, 0x00)],
    )
    def test_anion_bit_in_body(self, value: bool, expected_bit: int) -> None:
        """Test anion sets bit 0x20 in body byte index 8."""
        msg = MessageGeneralSet(protocol_version=ProtocolVersion.V1)
        msg.anion = value
        assert msg._body[8] & 0x20 == expected_bit
