"""Test AC Toshiba IoLife messages."""

import pytest

from midealocal.const import DeviceType
from midealocal.devices.ac.message import (
    TOSHIBA_PROTOCOL_VERSION,
    MessageACResponse,
    MessageQuery,
    MessageToshibaSet,
    ToshibaPropertyTags,
    XToshibaA1MessageBody,
    XToshibaBXMessageBody,
    XToshibaC0MessageBody,
)
from midealocal.message import (
    ListTypes,
    MessageBase,
    MessageChecksum,
    MessageHeader55,
    MessageType,
)

# Status frames captured from an IoLife unit (model 0000000F) in dry mode, one
# per breezeless direction: full (mid), left and right.
CAPTURED_C0_MID = bytearray.fromhex(
    "55aacc33300001ac0000000000000380c0013366b57fff7fff0030006468648800000101190800"
    "001a02000100000000004d007d",
)
CAPTURED_C0_LEFT = bytearray.fromhex(
    "55aacc33300001ac0000000000000380c0013366b57fff7fff0030006468648800000101190800"
    "002a02000100000000009a016b",
)
CAPTURED_C0_RIGHT = bytearray.fromhex(
    "55aacc33300001ac0000000000000380c0013366b57fff7fff0030006468648800000101190800"
    "003a02000100000000002006f9",
)


def toshiba_frame(
    body: bytearray | list[int],
    message_type: MessageType = MessageType.query,
) -> bytearray:
    """Wrap a body in a 0x55 frame with a valid CRC."""
    stream = MessageHeader55(
        device_type=DeviceType.AC,
        protocol_version=TOSHIBA_PROTOCOL_VERSION,
        message_type=message_type,
    ).serialize(len(body)) + bytearray(body)
    return stream + MessageBase.checksum(stream, MessageChecksum.CRC_CCITT)


class TestToshibaRequests:
    """Test the frames sent to Toshiba IoLife units."""

    def test_query(self) -> None:
        """The query is the standard AC 0x41 body inside a 0x55 frame."""
        frame = MessageQuery(
            TOSHIBA_PROTOCOL_VERSION,
            header_type=ListTypes.X55,
        ).serialize()
        assert frame[:4] == bytearray([0x55, 0xAA, 0xCC, 0x33])
        assert frame[6] == TOSHIBA_PROTOCOL_VERSION
        assert frame[7] == DeviceType.AC
        assert frame[14:16] == bytearray([MessageType.query, 0x00])
        assert frame[16:20] == bytearray([0x41, 0x81, 0x00, 0xFF])
        assert len(frame) == 16 + 22 + 2
        assert frame[-2:] == MessageBase.checksum(
            frame[:-2],
            MessageChecksum.CRC_CCITT,
        )

    def test_set(self) -> None:
        """The set body counts and packs every property written."""
        message = MessageToshibaSet(TOSHIBA_PROTOCOL_VERSION)
        message.set_param(ToshibaPropertyTags.power, bytearray([1]))
        message.set_param(ToshibaPropertyTags.wind_angle, bytearray([50, 25]))
        frame = message.serialize()
        assert frame[14:16] == bytearray([MessageType.set, 0x00])
        body = frame[16:-2]
        assert body[:2] == bytearray([0xB0, 2])
        assert body[2:6] == bytearray([0x01, 0x00, 0x01, 0x01])
        assert body[6:11] == bytearray([0x0A, 0x00, 0x02, 50, 25])
        # Then the message serial and its CRC8.
        assert len(body) == 13


class TestToshibaResponses:
    """Test MessageACResponse on frames from Toshiba IoLife units."""

    @pytest.mark.parametrize(
        ("frame", "direction"),
        [(CAPTURED_C0_MID, 1), (CAPTURED_C0_LEFT, 2), (CAPTURED_C0_RIGHT, 3)],
    )
    def test_captured_c0(self, frame: bytearray, direction: int) -> None:
        """Captured status frames decode to the unit's state."""
        response = MessageACResponse(frame)
        assert getattr(response, "power", None) is True
        assert getattr(response, "mode", None) == 3
        assert getattr(response, "fan_speed", None) == 102
        assert getattr(response, "target_temperature", None) == 26.5
        assert getattr(response, "indoor_humidity", None) == 48
        assert getattr(response, "indoor_temperature", None) == pytest.approx(27.8)
        assert getattr(response, "outdoor_temperature", None) == pytest.approx(25.8)
        assert getattr(response, "wind_ud_angle", None) == 1
        assert getattr(response, "wind_lr_angle", None) == 25
        assert getattr(response, "dehumidify", None) == 4
        assert getattr(response, "breezeless", None) is True
        assert getattr(response, "breezeless_direction", None) == direction

    def test_bad_crc_is_skipped(self) -> None:
        """A frame whose CRC does not match carries no attributes."""
        frame = bytearray(CAPTURED_C0_MID)
        frame[-1] ^= 0xFF
        assert not hasattr(MessageACResponse(frame), "power")

    @pytest.mark.parametrize(
        "body",
        [
            [0xC0, *[0] * 20],  # C0 shorter than its fixed layout
            [0xB0],  # B0 without a parameter count
            [0xB5],  # B5 without a parameter count
            [0x99, 0x01],  # unknown body type
        ],
    )
    def test_unparseable_body_is_skipped(self, body: list[int]) -> None:
        """Bodies too short or of an unknown type carry no attributes."""
        response = MessageACResponse(toshiba_frame(body))
        assert not hasattr(response, "power")
        assert not hasattr(response, "indoor_temperature")

    def test_d0_is_parsed_as_c0(self) -> None:
        """D0 bodies share the C0 layout."""
        body = [0xD0, 0x01, *[0] * 20]
        assert getattr(MessageACResponse(toshiba_frame(body)), "power", None) is True

    def test_b0_ack(self) -> None:
        """A set acknowledgement updates the properties it echoes."""
        body = [0xB0, 1, 0x01, 0x00, 0x00, 0x01, 0x00]
        response = MessageACResponse(toshiba_frame(body, MessageType.set))
        assert getattr(response, "power", None) is False


class TestXToshibaC0MessageBody:
    """Test the Toshiba IoLife C0 status body."""

    @pytest.fixture
    def body(self) -> bytearray:
        """Return a C0 body with every field populated."""
        body = bytearray(28)
        body[0] = 0xC0
        body[1] = 0x01  # power
        body[2] = 0x10  # mode 1 in the high nibble
        body[3] = 0xE4  # fan speed 100, high bit masked off
        body[4] = 0x2C  # 22.0 C
        body[10] = 40  # humidity
        body[11] = 0x10  # vertical swing on, horizontal off
        body[13] = 100  # indoor whole part
        body[14] = 60  # outdoor whole part
        body[15] = 0x23  # outdoor tenths 2, indoor tenths 3
        body[16] = 0x07  # eco, anion, dry
        body[17] = 0x20  # filter full
        body[18] = 0x01  # breezeless
        body[19] = 50  # wind_ud_angle
        body[20] = 75  # wind_lr_angle
        body[21] = 0x17  # energy_save, dehumidify 3, comfort_mode
        body[23] = 0x05  # error code
        body[24] = 0x70  # area bit 6 must not leak into the direction (3)
        return body

    def test_fields(self, body: bytearray) -> None:
        """Every field decodes from its byte."""
        parsed = XToshibaC0MessageBody(body)
        assert getattr(parsed, "power", None) is True
        assert getattr(parsed, "mode", None) == 1
        assert getattr(parsed, "fan_speed", None) == 100
        assert getattr(parsed, "target_temperature", None) == 22.0
        assert getattr(parsed, "indoor_humidity", None) == 40
        assert getattr(parsed, "swing_vertical", None) is True
        assert getattr(parsed, "swing_horizontal", None) is False
        assert getattr(parsed, "indoor_temperature", None) == pytest.approx(25.3)
        assert getattr(parsed, "outdoor_temperature", None) == pytest.approx(5.2)
        assert getattr(parsed, "eco_mode", None) is True
        assert getattr(parsed, "anion", None) is True
        assert getattr(parsed, "dry", None) is True
        assert getattr(parsed, "clean_manual", None) is False
        assert getattr(parsed, "cleaning", None) is False
        assert getattr(parsed, "full_dust", None) is True
        assert getattr(parsed, "breezeless", None) is True
        assert getattr(parsed, "wind_ud_angle", None) == 50
        assert getattr(parsed, "wind_lr_angle", None) == 75
        assert getattr(parsed, "energy_save", None) is True
        assert getattr(parsed, "dehumidify", None) == 3
        assert getattr(parsed, "comfort_mode", None) is True
        assert getattr(parsed, "error_code", None) == 5
        assert getattr(parsed, "breezeless_direction", None) == 3

    def test_clean_bits(self) -> None:
        """clean_manual is bit 4 and cleaning bit 5 of byte 16."""
        body = bytearray(28)
        body[0] = 0xC0
        body[16] = 0x22  # anion and cleaning, as captured mid-cycle
        parsed = XToshibaC0MessageBody(body)
        assert getattr(parsed, "clean_manual", None) is False
        assert getattr(parsed, "cleaning", None) is True

    def test_invalid_readings(self, body: bytearray) -> None:
        """0x00/0xFF temperatures and a 0 humidity are no reading."""
        body[10] = 0x00
        body[13] = 0x00
        body[14] = 0xFF
        parsed = XToshibaC0MessageBody(body)
        assert getattr(parsed, "indoor_humidity", None) is None
        assert getattr(parsed, "indoor_temperature", None) is None
        assert getattr(parsed, "outdoor_temperature", None) is None

    def test_short_body_defaults(self) -> None:
        """Fields past the end of a minimum-length body take defaults."""
        parsed = XToshibaC0MessageBody(bytearray([0xC0] + [0] * 21))
        assert getattr(parsed, "error_code", None) == 0
        assert getattr(parsed, "breezeless_direction", None) == 0


class TestXToshibaA1MessageBody:
    """Test the Toshiba IoLife A1 temperature notification body."""

    def test_temperatures(self) -> None:
        """Both temperatures take their tenths from byte 18."""
        body = bytearray(19)
        body[0] = 0xA1
        body[13] = 100
        body[14] = 60
        body[18] = 0x23
        parsed = XToshibaA1MessageBody(body)
        assert getattr(parsed, "indoor_temperature", None) == pytest.approx(25.3)
        assert getattr(parsed, "outdoor_temperature", None) == pytest.approx(5.2)

    def test_short_body_has_no_reading(self) -> None:
        """A body cut short reads as no temperature."""
        parsed = XToshibaA1MessageBody(bytearray([0xA1]))
        assert getattr(parsed, "indoor_temperature", None) is None
        assert getattr(parsed, "outdoor_temperature", None) is None


class TestXToshibaBXMessageBody:
    """Test the Toshiba IoLife B0/B5 property bodies."""

    def test_b0(self) -> None:
        """B0 uses the FIVE pack layout and decodes every carried property."""
        body = bytearray(
            [
                0xB0,
                6,
                *[0x01, 0x00, 0x00, 0x01, 0x01],  # power
                *[0x03, 0x00, 0x00, 0x01, 44],  # 22.0 C
                *[0x04, 0x00, 0x00, 0x02, 25, 3],  # indoor 25.3 C
                *[0x0A, 0x00, 0x00, 0x02, 50, 75],  # deflector
                *[0x17, 0x00, 0x00, 0x01, 100],  # screen display
                *[0x70, 0x00, 0x00, 0x01, 2],  # breezeless direction
            ],
        )
        parsed = XToshibaBXMessageBody(body, ListTypes.B0)
        assert getattr(parsed, "power", None) is True
        assert getattr(parsed, "target_temperature", None) == 22.0
        assert getattr(parsed, "indoor_temperature", None) == pytest.approx(25.3)
        assert getattr(parsed, "wind_ud_angle", None) == 50
        assert getattr(parsed, "wind_lr_angle", None) == 75
        assert getattr(parsed, "screen_display", None) is True
        assert getattr(parsed, "breezeless_direction", None) == 2
        assert not hasattr(parsed, "mode")
        assert not hasattr(parsed, "outdoor_temperature")

    def test_b5(self) -> None:
        """B5 uses the FOUR pack layout and ignores properties it never carries."""
        body = bytearray(
            [
                0xB5,
                3,
                *[0x02, 0x00, 0x01, 0x03],  # mode
                *[0x05, 0x00, 0x02, 5, 2],  # outdoor 5.2 C
                *[0x17, 0x00, 0x01, 100],  # screen display, not a B5 property
            ],
        )
        parsed = XToshibaBXMessageBody(body, ListTypes.B5)
        assert getattr(parsed, "mode", None) == 3
        assert getattr(parsed, "outdoor_temperature", None) == pytest.approx(5.2)
        assert not hasattr(parsed, "screen_display")

    def test_short_multi_byte_values_are_ignored(self) -> None:
        """Deflector and temperature values shorter than two bytes are dropped."""
        body = bytearray(
            [
                0xB0,
                2,
                *[0x0A, 0x00, 0x00, 0x01, 50],
                *[0x04, 0x00, 0x00, 0x01, 25],
            ],
        )
        parsed = XToshibaBXMessageBody(body, ListTypes.B0)
        assert not hasattr(parsed, "wind_ud_angle")
        assert not hasattr(parsed, "indoor_temperature")
