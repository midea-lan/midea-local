"""Test x13 Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.x13 import DeviceAttributes, Midea13Device
from midealocal.devices.x13.message import MessageQuery, MessageSet
from midealocal.message import MessageType


class TestMidea13Device:
    """Test Midea x13 Device."""

    device: Midea13Device

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea x13 Device setup."""
        self.device = Midea13Device(
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
        assert self.device.attributes[DeviceAttributes.brightness] is None
        assert self.device.attributes[DeviceAttributes.color_temperature] is None
        assert self.device.attributes[DeviceAttributes.rgb_color] is None
        assert self.device.attributes[DeviceAttributes.effect] is None
        assert self.device.attributes[DeviceAttributes.power] is False

    def test_effects(self) -> None:
        """Test effects property."""
        assert self.device.effects == [
            "none",
            "living",
            "reading",
            "mildly",
            "cinema",
            "night",
        ]

    def test_color_temp_range(self) -> None:
        """Test default color temperature range."""
        assert self.device.color_temp_range == [2700, 6500]

    @pytest.mark.parametrize(
        ("kelvin", "midea"),
        [(2700, 0), (6500, 255)],
    )
    def test_kelvin_conversions(self, kelvin: int, midea: int) -> None:
        """Test kelvin/midea conversions."""
        assert self.device.kelvin_to_midea(kelvin) == midea
        assert self.device.midea_to_kelvin(midea) == kelvin

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    @pytest.mark.parametrize(
        ("effect_raw", "expected_effect"),
        [
            (3, "reading"),
            (7, "living"),  # out of range raw value falls back to index 1
            (0, "night"),  # raw 0 becomes index -1, the last effect
        ],
    )
    def test_process_message_main_light(
        self,
        effect_raw: int,
        expected_effect: str,
    ) -> None:
        """Test process message with a main light body updates attributes."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.query],
        )
        body = bytearray(9)
        body[0] = 0xA4  # main light body type
        body[1] = 100  # brightness
        body[2] = 255  # color temperature
        body[3] = effect_raw
        body[8] = 1  # power on
        crc = bytearray([0x00])
        new_status = self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.brightness] == 100
        assert self.device.attributes[DeviceAttributes.color_temperature] == 6500
        assert self.device.attributes[DeviceAttributes.effect] == expected_effect
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.rgb_color] is None
        assert new_status[DeviceAttributes.power.value] is True
        assert DeviceAttributes.rgb_color.value not in new_status

    def test_process_message_control_success(self) -> None:
        """Test process message with a successful set response refreshes."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.set],
        )
        body = bytearray(4)
        body[0] = 0x81  # set response body type
        body[1] = 1  # success
        crc = bytearray([0x00])
        with patch.object(self.device, "refresh_status") as mock_refresh:
            new_status = self.device.process_message(bytes(header + body + crc))
            mock_refresh.assert_called_once()
        assert new_status == {"control_success": True}

    def test_process_message_control_failure(self) -> None:
        """Test process message with a failed set response does not refresh."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.set],
        )
        body = bytearray(4)
        body[0] = 0x81  # set response body type
        body[1] = 0  # failure
        crc = bytearray([0x00])
        with patch.object(self.device, "refresh_status") as mock_refresh:
            new_status = self.device.process_message(bytes(header + body + crc))
            mock_refresh.assert_not_called()
        assert new_status == {"control_success": False}

    def test_process_message_unhandled(self) -> None:
        """Test process message with an unhandled message updates nothing."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.query],
        )
        body = bytearray(9)
        body[0] = 0x24  # unhandled body type
        crc = bytearray([0x00])
        new_status = self.device.process_message(bytes(header + body + crc))
        assert new_status == {}

    def test_set_attribute_brightness(self) -> None:
        """Test set attribute brightness sends the value."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.brightness.value, 100)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.brightness == 100

    def test_set_attribute_color_temperature(self) -> None:
        """Test set attribute color temperature converts kelvin to midea."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.color_temperature.value, 6500)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.color_temperature == 255

    def test_set_attribute_effect(self) -> None:
        """Test set attribute effect converts the name to its index."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.effect.value, "reading")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.effect == 2

    def test_set_attribute_effect_invalid(self) -> None:
        """Test set attribute with an unknown effect sends the raw value."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.effect.value, -1)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.effect == -1

    def test_set_attribute_power(self) -> None:
        """Test set attribute power sends the value."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.power is True

    def test_set_attribute_not_settable(self) -> None:
        """Test set attribute with a read-only attribute does not send."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.rgb_color.value, 1)
            mock_build_send.assert_not_called()

    def test_set_customize(self) -> None:
        """Test set customize overrides the color temperature range."""
        with patch.object(self.device, "update_all") as mock_update_all:
            self.device.set_customize('{"color_temp_range_kelvin": [3000, 6000]}')
            mock_update_all.assert_called_once_with(
                {"color_temp_range": [3000, 6000]},
            )
        assert self.device.color_temp_range == [3000, 6000]

    def test_set_customize_without_key(self) -> None:
        """Test set customize without the key keeps the default range."""
        with patch.object(self.device, "update_all") as mock_update_all:
            self.device.set_customize('{"other": 1}')
            mock_update_all.assert_called_once_with(
                {"color_temp_range": [2700, 6500]},
            )
        assert self.device.color_temp_range == [2700, 6500]

    def test_set_customize_invalid(self) -> None:
        """Test set customize with invalid JSON keeps the default range."""
        with patch.object(self.device, "update_all") as mock_update_all:
            self.device.set_customize("{")
            mock_update_all.assert_called_once_with(
                {"color_temp_range": [2700, 6500]},
            )
        assert self.device.color_temp_range == [2700, 6500]
