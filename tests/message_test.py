"""Midea local message test."""

import pytest

from midealocal.const import DeviceType
from midealocal.message import (
    BodyParser,
    BodyType,
    BoolParser,
    IntEnumParser,
    IntParser,
    ListTypes,
    MessageApplianceResponse,
    MessageBase,
    MessageBit,
    MessageBody,
    MessageLenError,
    MessageQueryAppliance,
    MessageQuestCustom,
    MessageRequest,
    MessageType,
    NewProtocolMessageBody,
    SubBodyType,
)


def test_init_validations() -> None:
    """Test body parser init validations."""
    with pytest.raises(
        ValueError,
        match=r"Length in bytes must be a positive value\.",
    ):
        BodyParser[int]("name", byte=3, length_in_bytes=-1)

    with pytest.raises(
        ValueError,
        match=r"\('Bit, if set, must be a valid value position for %d bytes\.', 2\)",
    ):
        BodyParser[int]("name", byte=3, length_in_bytes=2, bit=-1)

    with pytest.raises(
        ValueError,
        match=r"\('Bit, if set, must be a valid value position for %d bytes\.', 3\)",
    ):
        BodyParser[int]("name", byte=3, length_in_bytes=3, bit=24)


class TestBodyParser:
    """Body parser test."""

    @pytest.fixture(autouse=True)
    def _setup_body(self) -> None:
        """Create body for test."""
        self.body = bytearray(
            [
                0x00,
                0x01,
                0x02,
                0x03,
                0x04,
                0x05,
            ],
        )

    def test_get_raw_value_1_byte(self) -> None:
        """Test get raw value with 1 byte."""
        parser = BodyParser[int]("name", 2)
        value = parser._get_raw_value(self.body)
        assert value == 0x02

    def test_get_raw_value_2_bytes(self) -> None:
        """Test get raw value with 2 bytes."""
        parser = BodyParser[int]("name", 2, length_in_bytes=2)
        value = parser._get_raw_value(self.body)
        assert value == 0x0203

    def test_get_raw_value_2_bytes_first_lower(self) -> None:
        """Test get raw value with 2 bytes first lower."""
        parser = BodyParser[int]("name", 2, length_in_bytes=2, first_upper=False)
        value = parser._get_raw_value(self.body)
        assert value == 0x0302

    def test_get_raw_out_of_bounds(self) -> None:
        """Test get raw value out of bounds."""
        parser = BodyParser[int]("name", 6)
        value = parser._get_raw_value(self.body)
        assert value == 0

    def test_get_raw_data_size_out_of_bounds(self) -> None:
        """Test get raw value out of bounds."""
        parser = BodyParser[int]("name", 5, length_in_bytes=2)
        value = parser._get_raw_value(self.body)
        assert value == 0

    def test_get_raw_data_bit(self) -> None:
        """Test get raw value out of bounds."""
        for i in range(16):
            parser = BodyParser[int]("name", 4, length_in_bytes=2, bit=i)
            value = parser._get_raw_value(self.body)
            assert value == (1 if i in [0, 2, 10] else 0)

    def test_parse_unimplemented(self) -> None:
        """Test parse unimplemented."""
        parser = BodyParser[int]("name", 4, length_in_bytes=2, bit=2)
        with pytest.raises(NotImplementedError):
            parser.get_value(self.body)


class TestBoolParser:
    """Test BoolParser."""

    def test_bool_default(self) -> None:
        """Test default behaviour."""
        parser = BoolParser("name", 0)
        assert parser._parse(0) is False
        assert parser._parse(1) is True
        assert parser._parse(2) is True

    def test_bool_default_false(self) -> None:
        """Test default behaviour with default value false."""
        parser = BoolParser("name", 0, default_value=False)
        assert parser._parse(0) is False
        assert parser._parse(1) is True
        assert parser._parse(2) is False

    def test_bool_inverted(self) -> None:
        """Test True=0 and False=1."""
        parser = BoolParser("name", 0, true_value=0, false_value=1)
        assert parser._parse(0) is True
        assert parser._parse(1) is False
        assert parser._parse(2) is True


class TestIntEnumParser:
    """Test IntEnumParser."""

    def test_intenum_default(self) -> None:
        """Test default behaviour."""
        parser = IntEnumParser[ListTypes]("name", 0, ListTypes)
        assert parser._parse(0x01) == ListTypes.X01
        assert parser._parse(0x00) == ListTypes.X00
        assert parser._parse(0x10) == ListTypes.X10

        parser = IntEnumParser[ListTypes](
            "name",
            0,
            ListTypes,
            default_value=ListTypes.A0,
        )
        assert parser._parse(0x01) == ListTypes.X01
        assert parser._parse(0x00) == ListTypes.X00
        assert parser._parse(0xA0) == ListTypes.A0

    def test_intenum_invalid_value(self) -> None:
        """Test an invalid raw value falls back to default or zero."""
        parser = IntEnumParser[ListTypes]("name", 0, ListTypes)
        assert parser._parse(0x1234) == ListTypes.X00
        parser = IntEnumParser[ListTypes](
            "name",
            0,
            ListTypes,
            default_value=ListTypes.A0,
        )
        assert parser._parse(0x1234) == ListTypes.A0


class TestIntParser:
    """Test IntParser."""

    def test_int_default(self) -> None:
        """Test default behaviour."""
        parser = IntParser("name", 0)
        for i in range(-10, 260):
            if i < 0:
                assert parser._parse(i) == 0
            elif i > 255:
                assert parser._parse(i) == 255
            else:
                assert parser._parse(i) == i


class TestMessageBody:
    """Test message body."""

    @pytest.mark.parametrize(
        ("byte", "expected"),
        [(0, 0x0A), (1, 0x0B), (2, 0x09), (5, 0x09)],
    )
    def test_read_byte(self, byte: int, expected: int) -> None:
        """Test read_byte returns the byte or the default when out of range."""
        body = bytearray([0x0A, 0x0B])
        assert MessageBody.read_byte(body, byte, default_value=0x09) == expected

    def test_parse_all(self) -> None:
        """Test parse all."""
        data = bytearray(
            [
                0x00,
                0x01,
                0x02,
                0x03,
                0x04,
                0x05,
            ],
        )

        body = MessageBody(data)
        body.parser_list.extend(
            [
                IntEnumParser("bt", 0, ListTypes),
                BoolParser("power", 1),
                BoolParser("feature_1", 2, 0),
                BoolParser("feature_2", 2, 1),
                IntParser("speed", 3),
            ],
        )
        body.parse_all()
        assert hasattr(body, "bt") is True
        assert getattr(body, "bt", None) == ListTypes.X00
        assert hasattr(body, "power") is True
        assert getattr(body, "power", False) is True
        assert hasattr(body, "feature_1") is True
        assert getattr(body, "feature_1", True) is False
        assert hasattr(body, "feature_2") is True
        assert getattr(body, "feature_2", False) is True
        assert hasattr(body, "speed") is True
        assert getattr(body, "speed", 0) == 3


class TestDeprecatedBodyTypes:
    """Test deprecated BodyType and SubBodyType."""

    # BodyType(0xA1) cannot be tested directly: empty enums reject value
    # lookup since Python 3.12, so only the _missing_ hook is exercised.

    def test_body_type_missing(self) -> None:
        """Test BodyType._missing_ warns and maps to ListTypes."""
        with pytest.warns(DeprecationWarning, match="BodyType is deprecated"):
            assert BodyType._missing_(0xA1) == ListTypes.A1

    def test_sub_body_type_missing(self) -> None:
        """Test SubBodyType._missing_ warns and maps to ListTypes."""
        with pytest.warns(DeprecationWarning, match="SubBodyType is deprecated"):
            assert SubBodyType._missing_(0xB1) == ListTypes.B1


class TestMessageType:
    """Test MessageType."""

    def test_get_key_from_value(self) -> None:
        """Test get_key_from_value."""
        assert MessageType.get_key_from_value(0x02) == "set"
        assert MessageType.get_key_from_value(0x03) == "query"
        assert MessageType.get_key_from_value(0xEE) == "Unknown"


class TestMessageBase:
    """Test MessageBase."""

    def test_unimplemented_properties(self) -> None:
        """Test header and body are not implemented in the base class."""
        base = MessageBase()
        with pytest.raises(NotImplementedError):
            _ = base.header
        with pytest.raises(NotImplementedError):
            _ = base.body


class _FilledBodyRequest(MessageRequest):
    """Message request with an implemented _body for testing."""

    @property
    def _body(self) -> bytearray:
        return bytearray([0x11, 0x22])


class TestMessageRequest:
    """Test MessageRequest."""

    def test_body_unimplemented(self) -> None:
        """Test _body is not implemented in the base request."""
        message = MessageRequest(
            device_type=DeviceType.AC,
            protocol_version=3,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )
        with pytest.raises(NotImplementedError):
            _ = message.body

    def test_body_with_body_type_and_content(self) -> None:
        """Test the body prepends the body type to the _body content."""
        message = _FilledBodyRequest(
            device_type=DeviceType.AC,
            protocol_version=3,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )
        assert message.body == bytearray([0x01, 0x11, 0x22])
        serialized = message.serialize()
        assert serialized[10:-1] == bytearray([0x01, 0x11, 0x22])


class TestMessageQuestCustom:
    """Test MessageQuestCustom."""

    def test_body(self) -> None:
        """Test the custom command body is used as-is."""
        cmd_body = bytearray([0x01, 0x02, 0x03])
        message = MessageQuestCustom(
            device_type=DeviceType.AC,
            protocol_version=3,
            cmd_type=MessageType.set,
            cmd_body=cmd_body,
        )
        assert message.body == cmd_body
        assert message._body == bytearray([])
        serialized = message.serialize()
        assert serialized[10:-1] == cmd_body


class TestMessageQueryAppliance:
    """Test MessageQueryAppliance."""

    def test_body(self) -> None:
        """Test the query appliance body."""
        message = MessageQueryAppliance(DeviceType.AC)
        assert message.body == bytearray([0x00] * 19)
        assert message._body == bytearray([])
        assert message.message_type == MessageType.query_appliance

    def test_str(self) -> None:
        """Test string representation of a message."""
        message = MessageQueryAppliance(DeviceType.AC)
        result = str(message)
        assert "'message_type': 'query_appliance'" in result
        assert f"'body': '{bytearray([0x00] * 19).hex()}'" in result
        assert "'body_type': '00'" in result


class TestMessageBit:
    """Test MessageBit."""

    def test_get_set_bit(self) -> None:
        """Test get_bit and set_bit."""
        body = bytearray([0x00, 0xFF])
        MessageBit.set_bit(body, 0, 3, 1)
        assert body[0] == 0x08
        assert MessageBit.get_bit(body, 0, 3) == 1
        MessageBit.set_bit(body, 1, 0, 0)
        assert body[1] == 0xFE
        assert MessageBit.get_bit(body, 1, 0) == 0

    def test_get_set_bits(self) -> None:
        """Test get_bits and set_bits."""
        assert MessageBit.get_bits(bytearray([0b10110100]), 0, 2, 5) == 0b1101
        body = bytearray([0xFF])
        MessageBit.set_bits(body, 0, 2, 5, 0b0110)
        assert body[0] == 0b11011011


class TestNewProtocolMessageBody:
    """Test NewProtocolMessageBody."""

    def test_pack(self) -> None:
        """Test pack with 4 and 5 bytes pack length."""
        assert NewProtocolMessageBody.pack(
            0x1234,
            bytearray([0xAA]),
            pack_len=4,
        ) == bytearray([0x34, 0x12, 0x01, 0xAA])
        assert NewProtocolMessageBody.pack(
            0x1234,
            bytearray([0xAA]),
            pack_len=5,
        ) == bytearray([0x34, 0x12, 0x00, 0x01, 0xAA])

    def test_parse(self) -> None:
        """Test parse with 4 and 5 bytes pack length."""
        body = NewProtocolMessageBody(
            bytearray([0xB1, 0x01, 0x34, 0x12, 0x01, 0xAA]),
            ListTypes.B5,
        )
        assert body.parse() == {0x1234: bytearray([0xAA])}
        body = NewProtocolMessageBody(
            bytearray([0xB1, 0x01, 0x34, 0x12, 0x00, 0x01, 0xAA]),
            ListTypes.B1,
        )
        assert body.parse() == {0x1234: bytearray([0xAA])}

    def test_parse_truncated_param(self) -> None:
        """Test parse stops when a declared param is missing."""
        body = NewProtocolMessageBody(
            bytearray([0xB1, 0x02, 0x01, 0x00, 0x01, 0xAA]),
            ListTypes.B5,
        )
        assert body.parse() == {0x0001: bytearray([0xAA])}

    def test_parse_truncated_after_param_id(self) -> None:
        """Test parse stops when the body ends after the param id."""
        body = NewProtocolMessageBody(bytearray([0xB1, 0x01, 0x01, 0x00]), ListTypes.B5)
        assert body.parse() == {}
        body = NewProtocolMessageBody(bytearray([0xB1, 0x01, 0x01, 0x00]), ListTypes.B1)
        assert body.parse() == {}
        body = NewProtocolMessageBody(
            bytearray([0xB1, 0x01, 0x01, 0x00, 0x00]),
            ListTypes.B1,
        )
        assert body.parse() == {}

    def test_parse_truncated_value(self) -> None:
        """Test parse stops when the value is shorter than its length."""
        body = NewProtocolMessageBody(
            bytearray([0xB1, 0x01, 0x01, 0x00, 0x05, 0xAA]),
            ListTypes.B5,
        )
        assert body.parse() == {}

    def test_parse_zero_length_value(self) -> None:
        """Test parse skips params with a zero length value."""
        body = NewProtocolMessageBody(
            bytearray([0xB1, 0x01, 0x01, 0x00, 0x00]),
            ListTypes.B5,
        )
        assert body.parse() == {}

    def test_parse_non_standard_short_body(self) -> None:
        """Test parse with a body too short to hold the param count.

        Source quirk (midealocal/message.py:886-898): the IndexError handler
        leaves `param_count` unbound, so the debug log after the handler
        raises UnboundLocalError instead of returning an empty result.
        """
        body = NewProtocolMessageBody(bytearray([0xB1]), ListTypes.B5)
        with pytest.raises(UnboundLocalError):
            body.parse()


class TestMessageResponse:
    """Test MessageResponse and MessageApplianceResponse."""

    def test_too_short_message(self) -> None:
        """Test a too short message raises MessageLenError."""
        with pytest.raises(MessageLenError):
            MessageApplianceResponse(bytearray(5))

    def test_appliance_response(self) -> None:
        """Test a valid appliance response."""
        message = bytearray(
            [0xAA, 0x0C, 0xAC, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xA0, 0xC0, 0x00],
        )
        response = MessageApplianceResponse(message)
        assert response.header == message[:10]
        assert response.body == bytearray([0xC0])
        assert response.body_type == ListTypes.C0
        assert response.message_type == MessageType.query_appliance
        assert response.device_type == DeviceType.AC
        assert response.protocol_version == 3

    def test_set_body_and_set_attr(self) -> None:
        """Test set_body replaces the body and set_attr copies its attrs."""
        message = bytearray(
            [0xAA, 0x0C, 0xAC, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xA0, 0xC0, 0x00],
        )
        response = MessageApplianceResponse(message)
        body = MessageBody(bytearray([0xC0, 0x01]))
        body.parser_list.append(BoolParser("power", 1))
        body.parse_all()
        response.set_body(body)
        response.set_attr()
        assert response.body == bytearray([0xC0, 0x01])
        assert getattr(response, "power", False) is True
