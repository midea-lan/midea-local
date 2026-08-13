"""Test x26 Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.x26 import DeviceAttributes, Midea26Device
from midealocal.devices.x26.message import MessageQuery, MessageSet
from midealocal.message import MessageType


def _build_body(values: dict[int, int]) -> bytearray:
    """Build a x26 response body with the given byte values."""
    body = bytearray(47)
    body[0] = 0x01
    for index, value in values.items():
        body[index] = value
    return body


def _build_message(message_type: MessageType, body: bytearray) -> bytes:
    """Build a full x26 response message."""
    header = bytearray(
        [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
    )
    return bytes(header + body + bytearray([0x00]))


class TestMidea26Device:
    """Test Midea x26 Device."""

    device: Midea26Device

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea x26 Device setup."""
        self.device = Midea26Device(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.1",
            port=12345,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model="test_model",
            subtype=1,
            customize="",
        )

    def test_initial_attributes(self) -> None:
        """Test initial attributes."""
        assert self.device.attributes[DeviceAttributes.main_light] is False
        assert self.device.attributes[DeviceAttributes.night_light] is False
        assert self.device.attributes[DeviceAttributes.mode] is None
        assert self.device.attributes[DeviceAttributes.direction] is None
        assert self.device.attributes[DeviceAttributes.current_humidity] is None
        assert self.device.attributes[DeviceAttributes.current_radar] is None
        assert self.device.attributes[DeviceAttributes.current_temperature] is None

    def test_preset_modes(self) -> None:
        """Test preset modes property."""
        assert self.device.preset_modes == [
            "off",
            "heat_high",
            "heat_low",
            "bath",
            "blow",
            "ventilation",
            "dry",
        ]

    def test_directions(self) -> None:
        """Test directions property."""
        assert self.device.directions == [
            "60",
            "70",
            "80",
            "90",
            "100",
            "110",
            "120",
            "oscillate",
        ]

    @pytest.mark.parametrize(
        ("direction", "expected"),
        [
            ("oscillate", 0xFD),
            ("60", 60),
            ("90", 90),
            ("120", 120),
            ("55", 0xFD),  # invalid direction falls back to oscillate
        ],
    )
    def test_convert_to_midea_direction(self, direction: str, expected: int) -> None:
        """Test convert to midea direction."""
        assert Midea26Device._convert_to_midea_direction(direction) == expected

    @pytest.mark.parametrize(
        ("direction", "expected"),
        [
            (59, 7),  # below minimum becomes oscillate
            (121, 7),  # above maximum becomes oscillate
            (0xFD, 7),
            (60, 0),
            (90, 3),
            (120, 6),
        ],
    )
    def test_convert_from_midea_direction(self, direction: int, expected: int) -> None:
        """Test convert from midea direction."""
        assert Midea26Device._convert_from_midea_direction(direction) == expected

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    @pytest.mark.parametrize(
        ("values", "expected_mode", "expected_direction"),
        [
            ({9: 1, 10: 55, 12: 90}, "heat_high", "90"),
            ({9: 1, 10: 30, 12: 60}, "heat_low", "60"),
            ({13: 1, 17: 0xFD}, "bath", "oscillate"),
            ({26: 1, 28: 120}, "blow", "120"),
            ({18: 1, 20: 100}, "ventilation", "100"),
            ({21: 1, 25: 55}, "dry", "oscillate"),
            ({}, "off", "oscillate"),
        ],
    )
    def test_process_message_modes(
        self,
        values: dict[int, int],
        expected_mode: str,
        expected_direction: str,
    ) -> None:
        """Test process message mode and direction parsing."""
        new_status = self.device.process_message(
            _build_message(MessageType.query, _build_body(values)),
        )
        assert self.device.attributes[DeviceAttributes.mode] == expected_mode
        assert self.device.attributes[DeviceAttributes.direction] == expected_direction
        assert new_status[DeviceAttributes.mode.value] == expected_mode
        assert new_status[DeviceAttributes.direction.value] == expected_direction

    @pytest.mark.parametrize(
        "message_type",
        [MessageType.query, MessageType.set, MessageType.notify1],
    )
    def test_process_message_lights(self, message_type: MessageType) -> None:
        """Test process message light parsing for each handled message type."""
        new_status = self.device.process_message(
            _build_message(message_type, _build_body({1: 1, 3: 1, 2: 100})),
        )
        assert self.device.attributes[DeviceAttributes.main_light] is True
        assert self.device.attributes[DeviceAttributes.night_light] is True
        assert new_status[DeviceAttributes.main_light.value] is True
        assert new_status[DeviceAttributes.night_light.value] is True

    def test_process_message_sensors(self) -> None:
        """Test process message sensor parsing."""
        self.device.process_message(
            _build_message(MessageType.query, _build_body({31: 50, 32: 1, 33: 25})),
        )
        assert self.device.attributes[DeviceAttributes.current_humidity] == 50
        assert self.device.attributes[DeviceAttributes.current_radar] == 1
        assert self.device.attributes[DeviceAttributes.current_temperature] == 25

    def test_process_message_sensors_invalid(self) -> None:
        """Test process message with 0xFF sensors keeps them unset."""
        self.device.process_message(
            _build_message(
                MessageType.query,
                _build_body({31: 0xFF, 32: 0xFF, 33: 0xFF}),
            ),
        )
        assert self.device.attributes[DeviceAttributes.current_humidity] is None
        assert self.device.attributes[DeviceAttributes.current_radar] is None
        assert self.device.attributes[DeviceAttributes.current_temperature] is None

    def test_process_message_unexpected_body_type(self) -> None:
        """Test process message with an unhandled body type is ignored safely.

        Message26Response only populates `.fields` for body type 0x01; for
        any other body type, process_message keeps the last known fields
        instead of raising AttributeError.
        """
        body = _build_body({})
        body[0] = 0x02
        new_status = self.device.process_message(
            _build_message(MessageType.query, body),
        )
        assert new_status == {}

    def test_set_attribute_main_light(self) -> None:
        """Test set attribute main light resets lights and sets the value."""
        self.device._attributes[DeviceAttributes.mode] = "off"
        self.device._attributes[DeviceAttributes.direction] = "oscillate"
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.main_light.value, True)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.main_light is True
            assert message.night_light is False
            assert message.mode == 0
            assert message.direction == 0xFD

    def test_set_attribute_night_light(self) -> None:
        """Test set attribute night light sends the value."""
        self.device._attributes[DeviceAttributes.mode] = "off"
        self.device._attributes[DeviceAttributes.direction] = "oscillate"
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.night_light.value, True)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.main_light is False
            assert message.night_light is True

    def test_set_attribute_mode(self) -> None:
        """Test set attribute mode converts the name to its index."""
        self.device._attributes[DeviceAttributes.mode] = "off"
        self.device._attributes[DeviceAttributes.direction] = "oscillate"
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.mode.value, "bath")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.mode == 3

    def test_set_attribute_direction(self) -> None:
        """Test set attribute direction converts the name to degrees."""
        self.device._attributes[DeviceAttributes.mode] = "off"
        self.device._attributes[DeviceAttributes.direction] = "oscillate"
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.direction.value, "90")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.direction == 90

    def test_set_attribute_uses_last_fields(self) -> None:
        """Test set attribute reuses fields from the last response."""
        self.device.process_message(
            _build_message(MessageType.query, _build_body({2: 100})),
        )
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.main_light.value, True)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.fields["MAIN_LIGHT_BRIGHTNESS"] == 100

    def test_set_attribute_not_settable(self) -> None:
        """Test set attribute with a read-only attribute does not send."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.current_humidity.value, 50)
            mock_build_send.assert_not_called()
