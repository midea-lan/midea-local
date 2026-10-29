"""Test 40 Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.const.fan_exceptions import X40_EXCEPTIONS, FanExceptions
from midealocal.devices.x40 import DeviceAttributes, MideaX40Device
from midealocal.devices.x40.message import MessageQuery, MessageSet


class TestMideaX40Device:
    """Test Midea 40 Device."""

    device: MideaX40Device

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea DA Device setup."""
        self.device = self._make_device()

    def _make_device(self) -> MideaX40Device:
        """Create a device for the test model."""
        return MideaX40Device(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.100",
            port=6444,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="test_model",
            subtype=1,
            customize="",
        )

    @pytest.mark.parametrize(
        ("exceptions", "expected_precision_halves", "expected_temperature"),
        [
            pytest.param({}, False, 53, id="default"),
            pytest.param(
                {"test_model": {"precision_halves": True}},
                True,
                26.5,
                id="model_exception",
            ),
        ],
    )
    def test_precision_halves_exception(
        self,
        exceptions: dict[str, FanExceptions],
        expected_precision_halves: bool,
        expected_temperature: float,
    ) -> None:
        """Test per-model precision halves exceptions."""
        with patch.dict(X40_EXCEPTIONS, exceptions):
            device = self._make_device()

        assert device.precision_halves is expected_precision_halves
        with patch(
            "midealocal.devices.x40.MessageX40Response",
        ) as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.light = True
            mock_message.ventilation = True
            mock_message.fan_speed = 1
            mock_message.direction = 5
            mock_message.smelly_sensor = True
            mock_message.current_temperature = 53
            new_status = device.process_message(b"")
        assert new_status[DeviceAttributes.current_temperature] == expected_temperature

    def test_directions(self) -> None:
        """Test the available directions."""
        assert self.device.directions == ["60", "70", "80", "90", "100", "oscillate"]

    def test_speed_count(self) -> None:
        """Test the speed count."""
        assert self.device.speed_count == 2

    def test_preset_modes(self) -> None:
        """Test the available preset modes."""
        assert self.device.preset_modes == []

    @pytest.mark.parametrize(
        ("direction", "expected"),
        [
            ("oscillate", 0xFD),
            ("invalid", 0xFD),
            ("60", 60),
            ("90", 90),
        ],
    )
    def test_convert_to_midea_direction(
        self,
        direction: str,
        expected: int,
    ) -> None:
        """Test converting a direction name to the midea value."""
        assert self.device._convert_to_midea_direction(direction) == expected

    @pytest.mark.parametrize(
        ("direction", "expected"),
        [
            (50, 5),
            (110, 5),
            (60, 0),
            (74, 1),
            (100, 4),
        ],
    )
    def test_convert_from_midea_direction(
        self,
        direction: int,
        expected: int,
    ) -> None:
        """Test converting a midea value back to a direction index."""
        assert MideaX40Device._convert_from_midea_direction(direction) == expected

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    def test_set_attribute_unknown(self) -> None:
        """Test an unknown attribute does not send a message."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(
                DeviceAttributes.current_temperature.value,
                26,
            )
            mock_build_send.assert_not_called()

    def test_set_attribute_light(self) -> None:
        """Test setting the light sends a set message."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.light.value, True)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
        assert isinstance(message, MessageSet)
        assert message.light is True
        assert message.direction == 0xFD  # default attribute is not a direction

    def test_set_attribute_direction(self) -> None:
        """Test setting the direction converts it to the midea value."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.direction.value, "80")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
        assert isinstance(message, MessageSet)
        assert message.direction == 80

    def test_set_attribute_ventilation_high_fan_speed(self) -> None:
        """Test enabling ventilation lowers a high fan speed."""
        self.device._attributes[DeviceAttributes.fan_speed] = 2
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.ventilation.value, True)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
        assert isinstance(message, MessageSet)
        assert message.fan_speed == 1
        assert message.ventilation is True

    def test_set_attribute_ventilation_low_fan_speed(self) -> None:
        """Test enabling ventilation keeps a low fan speed."""
        self.device._attributes[DeviceAttributes.fan_speed] = 1
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.ventilation.value, True)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
        assert isinstance(message, MessageSet)
        assert message.fan_speed == 1
        assert message.ventilation is True
