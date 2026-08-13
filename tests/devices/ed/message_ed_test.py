"""Test ED message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.ed.message import (
    EDMessageBody01,
    EDMessageBody03,
    EDMessageBody05,
    EDMessageBody06,
    EDMessageBody07,
    EDMessageBody09,
    EDMessageBodyFF,
    MessageEDBase,
    MessageEDResponse,
    MessageNewSet,
    MessageOldSet,
    MessageQuery,
    MessageQuery01,
    MessageQuery03,
    MessageQuery04,
    MessageQuery05,
    MessageQuery06,
    MessageQuery07,
    MessageQuery09,
    MessageQueryFF,
)
from midealocal.message import ListTypes, MessageType


class TestMessageEDBase:
    """Test ED Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageEDBase(
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
        query = MessageQuery(
            protocol_version=ProtocolVersion.V1,
        )
        expected_body = bytearray([0x00, 0x01])
        assert query.body == expected_body


class TestMessageQuery01:
    """Test Message Query01."""

    def test_query_body(self) -> None:
        """Test query body."""
        query = MessageQuery01(
            protocol_version=ProtocolVersion.V1,
        )
        expected_body = bytearray([0x01, 0x01])
        assert query.body == expected_body


class TestMessageQuery03:
    """Test Message Query03."""

    def test_query_body(self) -> None:
        """Test query body."""
        query = MessageQuery03(
            protocol_version=ProtocolVersion.V1,
        )
        expected_body = bytearray([0x03, 0x01])
        assert query.body == expected_body


class TestMessageQuery04:
    """Test Message Query04."""

    def test_query_body(self) -> None:
        """Test query body."""
        query = MessageQuery04(
            protocol_version=ProtocolVersion.V1,
        )
        expected_body = bytearray([0x04, 0x01])
        assert query.body == expected_body


class TestMessageQuery05:
    """Test Message Query05."""

    def test_query_body(self) -> None:
        """Test query body."""
        query = MessageQuery05(
            protocol_version=ProtocolVersion.V1,
        )
        expected_body = bytearray([0x05, 0x01])
        assert query.body == expected_body


class TestMessageQuery06:
    """Test Message Query06."""

    def test_query_body(self) -> None:
        """Test query body."""
        query = MessageQuery06(
            protocol_version=ProtocolVersion.V1,
        )
        expected_body = bytearray([0x06, 0x01])
        assert query.body == expected_body


class TestMessageQuery07:
    """Test Message Query07."""

    def test_query_body(self) -> None:
        """Test query body."""
        query = MessageQuery07(
            protocol_version=ProtocolVersion.V1,
        )
        expected_body = bytearray([0x07, 0x01])
        assert query.body == expected_body


class TestMessageQuery09:
    """Test Message Query09 (soft water machine)."""

    def test_query_body(self) -> None:
        """Test query body."""
        query = MessageQuery09(
            protocol_version=ProtocolVersion.V1,
        )
        expected_body = bytearray([ListTypes.X09, 0x01])
        assert query.body == expected_body

    def test_default_body_type(self) -> None:
        """Test default body_type is X09."""
        query = MessageQuery09(
            protocol_version=ProtocolVersion.V1,
        )
        assert query.body_type == ListTypes.X09


class TestMessageQueryFF:
    """Test Message QueryFF."""

    def test_query_body(self) -> None:
        """Test query body."""
        query = MessageQueryFF(
            protocol_version=ProtocolVersion.V1,
        )
        expected_body = bytearray([0xFF, 0x01])
        assert query.body == expected_body


class TestMessageNewSet:
    """Test MessageNewSet."""

    def test_message_newset(self) -> None:
        """Test MessageNewSet."""
        new_set = MessageNewSet(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0x15, 0x01, 0x00])
        assert new_set.body == expected_body
        new_set.power = True
        expected_body = bytearray([0x15, 0x01, 0x01, 0x00, 0x01, 0x01, 0x00, 0x00])
        assert new_set.body == expected_body
        new_set.lock = True
        expected_body = bytearray(
            [
                0x15,
                0x01,
                0x02,
                0x00,
                0x01,
                0x01,
                0x00,
                0x00,
                0x01,
                0x02,
                0x01,
                0x00,
                0x00,
            ],
        )
        assert new_set.body == expected_body
        new_set.power = None
        expected_body = bytearray([0x15, 0x01, 0x01, 0x01, 0x02, 0x01, 0x00, 0x00])
        assert new_set.body == expected_body

    def test_message_newset_tea_bar_start_to_target(self) -> None:
        """Encode the official Lua target-temperature and heat-start packs."""
        new_set = MessageNewSet(protocol_version=ProtocolVersion.V1)
        new_set.target_temperature = 80
        new_set.heating = True

        assert new_set.body == bytearray(
            [
                0x15,
                0x01,
                0x02,
                0x01,
                0x04,
                0x50,
                0x0A,
                0x00,
                0x05,
                0x04,
                0x01,
                0x00,
                0x00,
            ],
        )

    def test_message_newset_tea_bar_stop(self) -> None:
        """Encode the official Lua heat-start off pack."""
        new_set = MessageNewSet(protocol_version=ProtocolVersion.V1)
        new_set.heating = False

        assert new_set.body == bytearray(
            [0x15, 0x01, 0x01, 0x05, 0x04, 0x00, 0x00, 0x00],
        )

    @pytest.mark.parametrize(
        ("enabled", "duration", "raw_enabled"),
        [(True, 6, 0x01), (False, 24, 0x00)],
    )
    def test_message_newset_tea_bar_keep_warm(
        self,
        enabled: bool,
        duration: int,
        raw_enabled: int,
    ) -> None:
        """Encode the official Lua keep-warm command and duration."""
        new_set = MessageNewSet(protocol_version=ProtocolVersion.V1)
        new_set.keep_warm = enabled
        new_set.keep_warm_time = duration

        assert new_set.body == bytearray(
            [0x15, 0x01, 0x01, 0x08, 0x04, raw_enabled, duration, 0x00],
        )

    def test_message_newset_soften(self) -> None:
        """Test MessageNewSet with soften (soft water machine)."""
        new_set = MessageNewSet(protocol_version=ProtocolVersion.V1)
        new_set.soften = True
        body = new_set.body
        # Expected body layout:
        #   [body_type=0x15, _body[0]=0x01, pack_count=0x01, packed_params...]
        # pack(param=0x0108, value=0x01) yields bytes [0x08, 0x01, 0x01, 0x00, 0x00]
        assert body[2] == 0x01  # pack_count
        assert body[3:8] == bytearray([0x08, 0x01, 0x01, 0x00, 0x00])

    def test_message_newset_water_hardness(self) -> None:
        """Test MessageNewSet with water_hardness (addition param)."""
        new_set = MessageNewSet(protocol_version=ProtocolVersion.V1)
        new_set.water_hardness = 100
        body = new_set.body
        # pack(param=0x0100, value=0x00, addition=100) -> [0x00, 0x01, 0x00, 0x64, 0x00]
        assert body[2] == 0x01  # pack_count
        assert body[3:8] == bytearray([0x00, 0x01, 0x00, 0x64, 0x00])

    def test_message_newset_leak_water_protection_with_value(self) -> None:
        """Test MessageNewSet with leak_water_protection + value (//10 division)."""
        new_set = MessageNewSet(protocol_version=ProtocolVersion.V1)
        new_set.leak_water_protection = True
        new_set.leak_water_protection_value = 400  # 400 / 10 = 40
        body = new_set.body
        # pack(param=0x010A, value=0x01, addition=40) -> [0x0A, 0x01, 0x01, 0x28, 0x00]
        assert body[2] == 0x01  # pack_count
        assert body[3:8] == bytearray([0x0A, 0x01, 0x01, 0x28, 0x00])

    def test_message_newset_timing_regeneration(self) -> None:
        """Test MessageNewSet with timing_regeneration hour/min.

        Packed as (min<<8)|hour.
        """
        new_set = MessageNewSet(protocol_version=ProtocolVersion.V1)
        new_set.timing_regeneration_hour = 2
        new_set.timing_regeneration_min = 30
        body = new_set.body
        # pack(param=0x0102, value=0x00, addition=(30<<8)|2 = 0x1E02)
        # -> [0x02, 0x01, 0x00, 0x02, 0x1E]
        assert body[2] == 0x01  # pack_count
        assert body[3:8] == bytearray([0x02, 0x01, 0x00, 0x02, 0x1E])

    def test_message_newset_timing_regeneration_min_only(self) -> None:
        """Test minute-only timing_regeneration still packs the command."""
        new_set = MessageNewSet(protocol_version=ProtocolVersion.V1)
        new_set.timing_regeneration_min = 30
        body = new_set.body
        assert body[2] == 0x01  # pack_count
        assert body[3:8] == bytearray([0x02, 0x01, 0x00, 0x00, 0x1E])

    def test_message_newset_flushing_days(self) -> None:
        """Test MessageNewSet with flushing_days (addition param)."""
        new_set = MessageNewSet(protocol_version=ProtocolVersion.V1)
        new_set.flushing_days = 7
        body = new_set.body
        # pack(param=0x0101, value=0x00, addition=7) -> [0x01, 0x01, 0x00, 0x07, 0x00]
        assert body[2] == 0x01  # pack_count
        assert body[3:8] == bytearray([0x01, 0x01, 0x00, 0x07, 0x00])

    def test_message_newset_regeneration(self) -> None:
        """Test MessageNewSet with regeneration switch."""
        new_set = MessageNewSet(protocol_version=ProtocolVersion.V1)
        new_set.regeneration = True
        body = new_set.body
        # pack(param=0x0103, value=0x01) -> [0x03, 0x01, 0x01, 0x00, 0x00]
        assert body[2] == 0x01  # pack_count
        assert body[3:8] == bytearray([0x03, 0x01, 0x01, 0x00, 0x00])

    def test_message_newset_salt_setting(self) -> None:
        """Test MessageNewSet with salt_setting (addition param)."""
        new_set = MessageNewSet(protocol_version=ProtocolVersion.V1)
        new_set.salt_setting = 3
        body = new_set.body
        # pack(param=0x0104, value=0x00, addition=3) -> [0x04, 0x01, 0x00, 0x03, 0x00]
        assert body[2] == 0x01  # pack_count
        assert body[3:8] == bytearray([0x04, 0x01, 0x00, 0x03, 0x00])

    def test_message_newset_cl_sterilization(self) -> None:
        """Test MessageNewSet with cl_sterilization switch."""
        new_set = MessageNewSet(protocol_version=ProtocolVersion.V1)
        new_set.cl_sterilization = True
        body = new_set.body
        # pack(param=0x0109, value=0x01) -> [0x09, 0x01, 0x01, 0x00, 0x00]
        assert body[2] == 0x01  # pack_count
        assert body[3:8] == bytearray([0x09, 0x01, 0x01, 0x00, 0x00])

    def test_message_newset_water_way(self) -> None:
        """Test MessageNewSet with water_way switch."""
        new_set = MessageNewSet(protocol_version=ProtocolVersion.V1)
        new_set.water_way = True
        body = new_set.body
        # pack(param=0x0200, value=0x01) -> [0x00, 0x02, 0x01, 0x00, 0x00]
        assert body[2] == 0x01  # pack_count
        assert body[3:8] == bytearray([0x00, 0x02, 0x01, 0x00, 0x00])


class TestMessageOldSet:
    """Test MessageOldSet."""

    def test_message_oldset(self) -> None:
        """Test MessageOldSet has an empty body."""
        old_set = MessageOldSet(protocol_version=ProtocolVersion.V1)
        assert old_set.body == bytearray([])
        assert old_set._body == bytearray([])


class TestEDMessageBody01:
    """Test EDMessageBody01."""

    def test_ed_message01(self) -> None:
        """Test EDMessageBody01."""
        body = bytearray(40)
        body[0] = 0x01  # Body Type
        body[2] = 1  # Set power to True
        body[7] = 2  # Set water_consumption bit1
        body[8] = 3  # Set water_consumption bit2
        body[36] = 4  # Set in_tds bit1
        body[37] = 5  # Set in_tds bit2
        body[38] = 6  # Set out_tds bit1
        body[39] = 7  # Set out_tds bit2
        body[15] = 7  # Set child_lock
        body[25] = 4  # Set filter1 bit1
        body[26] = 5  # Set filter1 bit2
        body[27] = 5  # Set filter2 bit1
        body[28] = 6  # Set filter2 bit2
        body[29] = 6  # Set filter3 bit1
        body[30] = 7  # Set filter3 bit2
        body[16] = 2  # Set life1
        body[17] = 3  # Set life2
        body[18] = 4  # Set life3
        message = EDMessageBody01(body=body)
        assert hasattr(message, "body_type")
        assert message.body_type == 1
        assert hasattr(message, "power")
        assert message.power
        assert hasattr(message, "water_consumption")
        assert message.water_consumption == 770
        assert hasattr(message, "in_tds")
        assert message.in_tds == 1284
        assert hasattr(message, "out_tds")
        assert message.out_tds == 1798
        assert hasattr(message, "child_lock")
        assert message.child_lock
        assert hasattr(message, "filter1")
        assert message.filter1 == 54
        assert hasattr(message, "filter2")
        assert message.filter2 == 64
        assert hasattr(message, "filter3")
        assert message.filter3 == 75
        assert hasattr(message, "life1")
        assert message.life1 == 2
        assert hasattr(message, "life2")
        assert message.life2 == 3
        assert hasattr(message, "life3")
        assert message.life3 == 4


class TestEDMessageBody03:
    """Test EDMessageBody03."""

    def test_ed_message03(self) -> None:
        """Test EDMessageBody03."""
        body = bytearray(52)
        body[0] = 0x03  # Body Type
        body[51] = 1  # Set power to True
        body[20] = 2  # Set water_consumption bit1
        body[21] = 3  # Set water_consumption bit2
        body[27] = 4  # Set in_tds bit1
        body[28] = 5  # Set in_tds bit2
        body[29] = 6  # Set out_tds bit1
        body[30] = 7  # Set out_tds bit2
        body[22] = 2  # Set life1
        body[23] = 3  # Set life2
        body[24] = 4  # Set life3
        message = EDMessageBody03(body=body)
        assert hasattr(message, "body_type")
        assert message.body_type == 3
        assert hasattr(message, "power")
        assert message.power
        assert hasattr(message, "water_consumption")
        assert message.water_consumption == 770
        assert hasattr(message, "in_tds")
        assert message.in_tds == 1284
        assert hasattr(message, "out_tds")
        assert message.out_tds == 1798
        assert hasattr(message, "child_lock")
        assert not message.child_lock
        assert hasattr(message, "life1")
        assert message.life1 == 2
        assert hasattr(message, "life2")
        assert message.life2 == 3
        assert hasattr(message, "life3")
        assert message.life3 == 4


class TestEDMessageBody05:
    """Test EDMessageBody05."""

    def test_ed_message05(self) -> None:
        """Test EDMessageBody05."""
        body = bytearray(52)
        body[0] = 0x05  # Body Type
        body[51] = 1  # Set power to True
        body[20] = 2  # Set water_consumption bit1
        body[21] = 3  # Set water_consumption bit2
        message = EDMessageBody05(body=body)
        assert hasattr(message, "body_type")
        assert message.body_type == 5
        assert hasattr(message, "power")
        assert message.power
        assert hasattr(message, "water_consumption")
        assert message.water_consumption == 770
        assert hasattr(message, "child_lock")
        assert not message.child_lock


class TestEDMessageBody06:
    """Test EDMessageBody06."""

    def test_ed_message06(self) -> None:
        """Test EDMessageBody06."""
        body = bytearray(52)
        body[0] = 0x06  # Body Type
        body[51] = 1  # Set power to True
        body[25] = 2  # Set water_consumption bit1
        body[26] = 3  # Set water_consumption bit2
        message = EDMessageBody06(body=body)
        assert hasattr(message, "body_type")
        assert message.body_type == 6
        assert hasattr(message, "power")
        assert message.power
        assert hasattr(message, "water_consumption")
        assert message.water_consumption == 770
        assert hasattr(message, "child_lock")
        assert not message.child_lock

    @pytest.mark.parametrize(
        ("body_hex", "current_temperature", "heating", "dispensing"),
        [
            (
                "0601002064645a000000000000000000000000000000000000950a0000000000000000005600000000000000000000000000000100",
                32,
                False,
                False,
            ),
            (
                "0601002064645a000000000000000000000000000000000000950a0000000000000000005600000000000000000000000001000500",
                32,
                True,
                False,
            ),
            (
                "0601002164645a000000000000000000000000000000000000950a0000000000000000005600000000000000000000000000000100",
                33,
                False,
                False,
            ),
            (
                "0601002264645a000000000000000000000000000000000000950a0000000000000000005600000000000000000000000000000100",
                34,
                False,
                False,
            ),
            (
                "0601002664645a000000000000000000000000000000000000960a0000000000000000001c00000000000000000000000000000100",
                38,
                False,
                False,
            ),
            (
                "0601002664645a000000000000000000000000000000000000960a0000000000000000001e00000000000000000000000000005100",
                38,
                False,
                True,
            ),
            (
                "0601001c64645a000000000000000000000000000000000000970a0000000000000000000e00000000000000000000000000000100",
                28,
                False,
                False,
            ),
            (
                "0601006464645a000000000000000000000000000000000000970a0000000000000000000e00000000000000000000000000000100",
                100,
                False,
                False,
            ),
        ],
    )
    def test_tea_bar_status_reports(
        self,
        body_hex: str,
        current_temperature: int,
        heating: bool,
        dispensing: bool,
    ) -> None:
        """Parse subtype 395 status from captured reports."""
        message = EDMessageBody06(bytearray.fromhex(body_hex), subtype=395)
        assert message.current_temperature == current_temperature
        assert message.target_temperature is None
        assert message.heating is heating
        assert message.dispensing is dispensing
        assert message.sleep is False
        assert message.screen_display is True
        assert message.cooling is False
        assert message.lack_water is False
        assert message.standby is False
        assert message.fault_code == 0
        assert message.fault is False

    @pytest.mark.parametrize(
        (
            "body_hex",
            "current_temperature",
            "target_temperature",
            "heating",
            "dispensing",
        ),
        [
            (
                "0601004164645a000000460000000000000000000000000000970a0000000000000000002000000000000000000000000000005100",
                65,
                70,
                False,
                True,
            ),
            (
                "0601001e64645a000000460000000000000000000000000000980a0000000000000000000c00000000000000000000000001000500",
                30,
                70,
                True,
                False,
            ),
            (
                "0601004564645a000000460000000000000000000000000000980a0000000000000000000c00000000000000000000000000000100",
                69,
                70,
                False,
                False,
            ),
            (
                "0601003f64645a0000004b0000000000000000000000000000980a0000000000000000000c00000000000000000000000001000500",
                63,
                75,
                True,
                False,
            ),
            (
                "0601004b64645a0000004b0000000000000000000000000000980a0000000000000000000c00000000000000000000000000000100",
                75,
                75,
                False,
                False,
            ),
        ],
    )
    def test_tea_bar_voice_target_temperature_reports(
        self,
        body_hex: str,
        current_temperature: int,
        target_temperature: int,
        heating: bool,
        dispensing: bool,
    ) -> None:
        """Parse native targets throughout captured official voice flows."""
        message = EDMessageBody06(bytearray.fromhex(body_hex), subtype=395)
        assert message.current_temperature == current_temperature
        assert message.target_temperature == target_temperature
        assert message.heating is heating
        assert message.dispensing is dispensing

    def test_tea_bar_fields_are_not_parsed_for_other_subtypes(self) -> None:
        """Do not apply subtype 395 offsets to other ED appliances."""
        body = bytearray.fromhex(
            "0601002064645a000000000000000000000000000000000000950a0000000000000000005600000000000000000000000001000500",
        )
        message = EDMessageBody06(body, subtype=394)
        assert not hasattr(message, "current_temperature")
        assert not hasattr(message, "target_temperature")
        assert not hasattr(message, "heating")
        assert not hasattr(message, "dispensing")
        assert not hasattr(message, "keep_warm")
        assert not hasattr(message, "keep_warm_time")
        assert not hasattr(message, "keep_warm_remaining")
        assert not hasattr(message, "sleep")
        assert not hasattr(message, "screen_display")
        assert not hasattr(message, "cooling")
        assert not hasattr(message, "lack_water")
        assert not hasattr(message, "standby")
        assert not hasattr(message, "hot_water_dispensing")
        assert not hasattr(message, "fault_code")
        assert not hasattr(message, "fault")

    def test_tea_bar_keep_warm_status_uses_official_body06_layout(self) -> None:
        """Parse official keep-warm flag and half-hour duration encoding."""
        body = bytearray.fromhex(
            "0601002064645a000000000000000000000000000000000000950a0000000000000000005600000000000000000000000000000100",
        )
        body[33] = 6
        body[34] = 0x4D
        body[35] = 0x0E
        body[48] = 0x01

        message = EDMessageBody06(body, subtype=395)

        assert message.keep_warm is True
        assert message.keep_warm_time == 3
        assert message.keep_warm_remaining == 3661

    def test_tea_bar_extended_status_uses_official_body06_layout(self) -> None:
        """Parse screen, cooling, water, standby, and fault status fields."""
        body = bytearray.fromhex(
            "0601002064645a000000000000000000000000000000000000950a0000000000000000005600000000000000000000000000000100",
        )
        body[48] = 0x80
        body[50] = 0x01
        body[51] = 0xC3
        body[52] = 22

        message = EDMessageBody06(body, subtype=395)

        assert message.sleep is True
        assert message.screen_display is False
        assert message.cooling is True
        assert message.lack_water is True
        assert message.standby is True
        assert message.hot_water_dispensing is True
        assert message.fault_code == 22
        assert message.fault is True


class TestEDMessageBody07:
    """Test EDMessageBody07."""

    def test_ed_message07(self) -> None:
        """Test EDMessageBody07."""
        body = bytearray(52)
        body[0] = 0x07  # Body Type
        body[51] = 1  # Set power to True
        body[20] = 2  # Set water_consumption bit1
        body[21] = 3  # Set water_consumption bit2
        message = EDMessageBody07(body=body)
        assert hasattr(message, "body_type")
        assert message.body_type == 7
        assert hasattr(message, "power")
        assert message.power
        assert hasattr(message, "water_consumption")
        assert message.water_consumption == 770
        assert hasattr(message, "child_lock")
        assert not message.child_lock


class TestEDMessageBody09:
    """Test EDMessageBody09 (soft water machine)."""

    def _make_body(self, length: int = 60) -> bytearray:
        """Create a body for EDMessageBody09 with given length."""
        body = bytearray(length)
        body[0] = 0x09  # body_type
        return body

    def test_body_type(self) -> None:
        """Test body_type is 9."""
        body = self._make_body()
        msg = EDMessageBody09(body=body)
        assert msg.body_type == 9

    def test_velocity(self) -> None:
        """Test velocity parsing from byte 2."""
        body = self._make_body()
        body[2] = 5
        msg = EDMessageBody09(body=body)
        assert msg.velocity == 5

    def test_soft_available_little_endian(self) -> None:
        """Test soft_available 2-byte little-endian parsing."""
        body = self._make_body()
        body[3] = 0x34
        body[4] = 0x12
        msg = EDMessageBody09(body=body)
        assert msg.soft_available == 0x1234

    def test_water_consumption_little_endian(self) -> None:
        """Test water_consumption 2-byte little-endian parsing."""
        body = self._make_body()
        body[5] = 0x78
        body[6] = 0x56
        msg = EDMessageBody09(body=body)
        assert msg.water_consumption == 0x5678

    def test_left_salt(self) -> None:
        """Test left_salt parsing."""
        body = self._make_body()
        body[7] = 53
        msg = EDMessageBody09(body=body)
        assert msg.left_salt == 53

    def test_leak_water_protection_value_x10(self) -> None:
        """Test leak_water_protection_value is multiplied by 10."""
        body = self._make_body()
        body[8] = 40  # 40 * 10 = 400
        msg = EDMessageBody09(body=body)
        assert msg.leak_water_protection_value == 400

    def test_remaining_days_little_endian(self) -> None:
        """Test remaining_days 2-byte little-endian."""
        body = self._make_body()
        body[9] = 0x10
        body[10] = 0x00
        msg = EDMessageBody09(body=body)
        assert msg.remaining_days == 0x10

    def test_water_hardness_little_endian(self) -> None:
        """Test water_hardness 2-byte little-endian."""
        body = self._make_body()
        body[11] = 0x64
        body[12] = 0x00
        msg = EDMessageBody09(body=body)
        assert msg.water_hardness == 100

    def test_flushing_days(self) -> None:
        """Test flushing_days single byte."""
        body = self._make_body()
        body[13] = 7
        msg = EDMessageBody09(body=body)
        assert msg.flushing_days == 7

    def test_timing_regeneration_hour_min(self) -> None:
        """Test timing_regeneration_hour and _min parsing."""
        body = self._make_body()
        body[14] = 2  # hour
        body[15] = 30  # min
        msg = EDMessageBody09(body=body)
        assert msg.timing_regeneration_hour == 2
        assert msg.timing_regeneration_min == 30

    def test_regeneration_left_seconds_little_endian(self) -> None:
        """Test regeneration_left_seconds 2-byte little-endian."""
        body = self._make_body()
        body[16] = 0x34
        body[17] = 0x12
        msg = EDMessageBody09(body=body)
        assert msg.regeneration_left_seconds == 0x1234

    def test_use_days_little_endian(self) -> None:
        """Test use_days 2-byte little-endian."""
        body = self._make_body()
        body[18] = 0x78
        body[19] = 0x56
        msg = EDMessageBody09(body=body)
        assert msg.use_days == 0x5678

    def test_salt_setting(self) -> None:
        """Test salt_setting single byte."""
        body = self._make_body()
        body[20] = 10
        msg = EDMessageBody09(body=body)
        assert msg.salt_setting == 10

    def test_soft_available_big_4byte_little_endian(self) -> None:
        """Test soft_available_big 4-byte little-endian."""
        body = self._make_body(length=60)
        body[21] = 0x78
        body[22] = 0x56
        body[23] = 0x34
        body[24] = 0x12
        msg = EDMessageBody09(body=body)
        assert msg.soft_available_big == 0x12345678

    def test_water_consumption_big_divided_by_100(self) -> None:
        """Test water_consumption_big is divided by 100."""
        body = self._make_body(length=60)
        # 0x00017A82 = 96898, /100 = 968.98 (little-endian)
        body[25] = 0x82
        body[26] = 0x7A
        body[27] = 0x01
        body[28] = 0x00
        msg = EDMessageBody09(body=body)
        assert msg.water_consumption_big == 968.98

    def test_water_consumption_average_little_endian(self) -> None:
        """Test water_consumption_average 2-byte little-endian."""
        body = self._make_body(length=60)
        body[33] = 0x34
        body[34] = 0x12
        msg = EDMessageBody09(body=body)
        assert msg.water_consumption_average == 0x1234

    def test_switch_byte_flags(self) -> None:
        """Test switch byte flags (byte 51)."""
        body = self._make_body(length=60)
        # Bit flags in switch byte (byte 51):
        #   0x01=soften, 0x02=cl_sterilization, 0x04=leak_water_protection,
        #   0x08=leak_water, 0x10=water_way, 0x20=rsj_stand_by, 0x80=regeneration
        # 0x97 sets soften, cl_sterilization, leak_water_protection, water_way,
        # and regeneration
        body[51] = 0x97
        msg = EDMessageBody09(body=body)
        assert msg.soften is True
        assert msg.cl_sterilization is True
        assert msg.leak_water_protection is True
        assert msg.leak_water is False
        assert msg.water_way is True
        assert msg.rsj_stand_by is False
        assert msg.regeneration is True

    def test_error_byte(self) -> None:
        """Test error byte parsing."""
        body = self._make_body(length=60)
        body[52] = 1  # E1 error
        msg = EDMessageBody09(body=body)
        assert msg.error == 1


class TestEDMessageBodyFF:
    """Test EDMessageBodyFF."""

    def test_ed_message_ff(self) -> None:
        """Test EDMessageBodyFF."""
        body = bytearray(
            [
                0xFF,  # body_type
                0x01,
                0x07,  # category
                0x00,  # part 1, offset+1,  attr bit1, test 0x00/CHILD_LOCK
                0x40,  # part 1, offset+2,  attr bit2 and length bit
                0x00,  # part 1, offset+3,
                0x00,  # part 1, offset+4,
                0x01,  # part 1, offset+5, child_lock
                0x01,  # part 1, offset+6, power
                0x10,  # part 2, offset+1,  attr bit1, test 0x10/LIFE
                0x40,  # part 2, offset+2,  attr bit2 and length bit
                0x01,  # part 2, offset+3, life1
                0x02,  # part 2, offset+4, life2
                0x03,  # part 2, offset+5, life3
                0x00,  # part 2,
                0x11,  # part 3, offset+1,  attr bit1, test 0x11/WATER_CONSUMPTION
                0x40,  # part 3, offset+2,  attr bit2 and length bit
                0x01,  # part 3, offset+3, water_consumption bit1
                0x02,  # part 3, offset+4, water_consumption bit2
                0x03,  # part 3, offset+5, water_consumption bit3
                0x04,  # part 3, offset+6, water_consumption bit4
                0x13,  # part 4, offset+1,  attr bit1, test 0x13/TDS
                0x40,  # part 4, offset+2,  attr bit2 and length bit
                0x04,  # part 4, offset+3, in_tds bit1
                0x03,  # part 4, offset+4, in_tds bit2
                0x02,  # part 4, offset+5, out_tds bit1
                0x01,  # part 4, offset+6, out_tds bit2
            ],
        )

        message = EDMessageBodyFF(body=body)
        assert hasattr(message, "body_type")
        assert message.body_type == 255
        assert hasattr(message, "power")
        assert message.power
        assert hasattr(message, "water_consumption")
        assert message.water_consumption == 67305.985
        assert hasattr(message, "in_tds")
        assert message.in_tds == 772
        assert hasattr(message, "out_tds")
        assert message.out_tds == 258
        assert hasattr(message, "child_lock")
        assert message.child_lock

        assert hasattr(message, "life1")
        assert message.life1 == 1
        assert hasattr(message, "life2")
        assert message.life2 == 2
        assert hasattr(message, "life3")
        assert message.life3 == 3


class TestMessageEDResponse:
    """Test Message ED Response."""

    def test_tea_bar_new_set_status_acknowledgement(self) -> None:
        """Parse the real subtype-395 X15 acknowledgement after stopping heat."""
        raw = bytes.fromhex(
            "aa3fed000000000000021501004a64645a00000050000000000000000000000000"
            "0000980a0000000000000000005e00000000000000000000000000000100ff",
        )

        message = MessageEDResponse(raw, subtype=395)

        assert message.body_type == ListTypes.X15
        assert hasattr(message, "current_temperature")
        assert hasattr(message, "target_temperature")
        assert hasattr(message, "heating")
        assert hasattr(message, "dispensing")
        assert message.current_temperature == 74
        assert message.target_temperature == 80
        assert message.heating is False
        assert message.dispensing is False

    def test_ed_general_response(self) -> None:
        """Test general response."""
        header = bytearray(
            [
                0xAA,
                0x00,
                0xDA,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x01,
                0x03,
            ],
        )
        body = bytearray(
            [
                0xFF,  # body_type
                0x01,
                0x07,  # category
                0x00,  # part 1, offset+1,  attr bit1, test 0x00/CHILD_LOCK
                0x40,  # part 1, offset+2,  attr bit2 and length bit
                0x00,  # part 1, offset+3,
                0x00,  # part 1, offset+4,
                0x01,  # part 1, offset+5, child_lock
                0x01,  # part 1, offset+6, power
                0x10,  # part 2, offset+1,  attr bit1, test 0x10/LIFE
                0x40,  # part 2, offset+2,  attr bit2 and length bit
                0x01,  # part 2, offset+3, life1
                0x02,  # part 2, offset+4, life2
                0x03,  # part 2, offset+5, life3
                0x00,  # part 2,
                0x11,  # part 3, offset+1,  attr bit1, test 0x11/WATER_CONSUMPTION
                0x40,  # part 3, offset+2,  attr bit2 and length bit
                0x01,  # part 3, offset+3, water_consumption bit1
                0x02,  # part 3, offset+4, water_consumption bit2
                0x03,  # part 3, offset+5, water_consumption bit3
                0x04,  # part 3, offset+6, water_consumption bit4
                0x13,  # part 4, offset+1,  attr bit1, test 0x13/TDS
                0x40,  # part 4, offset+2,  attr bit2 and length bit
                0x04,  # part 4, offset+3, in_tds bit1
                0x03,  # part 4, offset+4, in_tds bit2
                0x02,  # part 4, offset+5, out_tds bit1
                0x01,  # part 4, offset+6, out_tds bit2
                0x00,
            ],
        )
        message = MessageEDResponse(bytes(header + body))
        assert hasattr(message, "body_type")
        assert message.body_type == 255
        assert hasattr(message, "power")
        assert message.power
        assert hasattr(message, "water_consumption")
        assert message.water_consumption == 67305.985
        assert hasattr(message, "in_tds")
        assert message.in_tds == 772
        assert hasattr(message, "out_tds")
        assert message.out_tds == 258
        assert hasattr(message, "child_lock")
        assert message.child_lock
        assert hasattr(message, "life1")
        assert message.life1 == 1
        assert hasattr(message, "life2")
        assert message.life2 == 2
        assert hasattr(message, "life3")
        assert message.life3 == 3

    @pytest.mark.parametrize(
        ("body_type", "body_size"),
        [
            (ListTypes.X01, 41),
            (ListTypes.X03, 53),
            (ListTypes.X04, 53),
            (ListTypes.X05, 53),
            (ListTypes.X06, 53),
            (ListTypes.X07, 53),
        ],
    )
    def test_ed_typed_body_response(
        self,
        body_type: ListTypes,
        body_size: int,
    ) -> None:
        """Test response dispatch to the body parser of each body type."""
        header = bytearray(
            [
                0xAA,
                0x00,
                0xDA,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x01,
                0x03,
            ],
        )
        body = bytearray(body_size)
        body[0] = body_type
        message = MessageEDResponse(bytes(header + body))
        assert hasattr(message, "device_class")
        assert message.device_class == body_type
        assert hasattr(message, "power")
        assert message.power is False
        assert hasattr(message, "water_consumption")
        assert message.water_consumption == 0
        assert hasattr(message, "child_lock")
        assert message.child_lock is False

    def test_ed_typed_body_response_x09(self) -> None:
        """Test response dispatch to the body parser for body type X09."""
        header = bytearray(
            [
                0xAA,
                0x00,
                0xDA,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x01,
                0x03,
            ],
        )
        body = bytearray(60)
        body[0] = ListTypes.X09
        message = MessageEDResponse(bytes(header + body))
        assert hasattr(message, "device_class")
        assert message.device_class == ListTypes.X09
        assert hasattr(message, "velocity")
        assert message.velocity == 0
        assert hasattr(message, "water_consumption")
        assert message.water_consumption == 0
