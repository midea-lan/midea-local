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

    def test_message_newset_water_way(self) -> None:
        """Test MessageNewSet with water_way switch."""
        new_set = MessageNewSet(protocol_version=ProtocolVersion.V1)
        new_set.water_way = True
        body = new_set.body
        # pack(param=0x0200, value=0x01) -> [0x00, 0x02, 0x01, 0x00, 0x00]
        assert body[2] == 0x01  # pack_count
        assert body[3:8] == bytearray([0x00, 0x02, 0x01, 0x00, 0x00])


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
