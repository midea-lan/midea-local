"""Test CE Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.ce import DeviceAttributes, MideaCEDevice
from midealocal.devices.ce.message import MessageQuery, MessageSet
from midealocal.message import MessageType


class TestMideaCEDevice:
    """Test Midea CE Device."""

    device: MideaCEDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea CE Device setup."""
        self.device = MideaCEDevice(
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
        assert self.device.attributes[DeviceAttributes.power] is False
        assert self.device.attributes[DeviceAttributes.mode] is None
        assert self.device.attributes[DeviceAttributes.child_lock] is False
        assert self.device.attributes[DeviceAttributes.scheduled] is False
        assert self.device.attributes[DeviceAttributes.fan_speed] == 0
        assert self.device.attributes[DeviceAttributes.pm25] is None
        assert self.device.attributes[DeviceAttributes.co2] is None
        assert self.device.attributes[DeviceAttributes.current_humidity] is None
        assert self.device.attributes[DeviceAttributes.current_temperature] is None
        assert self.device.attributes[DeviceAttributes.hcho] is None
        assert self.device.attributes[DeviceAttributes.link_to_ac] is False
        assert self.device.attributes[DeviceAttributes.sleep_mode] is False
        assert self.device.attributes[DeviceAttributes.eco_mode] is False
        assert self.device.attributes[DeviceAttributes.aux_heating] is None
        assert self.device.attributes[DeviceAttributes.powerful_purify] is False
        assert (
            self.device.attributes[DeviceAttributes.filter_cleaning_reminder] is False
        )
        assert self.device.attributes[DeviceAttributes.filter_change_reminder] is False
        assert self.device.attributes[DeviceAttributes.error_code] == 0
        assert self.device.speed_count == 7
        assert self.device.preset_modes == ["normal", "sleep_mode", "eco_mode"]

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    @pytest.mark.parametrize(
        ("message_type", "body_type"),
        [
            (MessageType.query, 0x01),
            (MessageType.set, 0x01),
            (MessageType.notify1, 0x02),
        ],
    )
    def test_general_response(
        self,
        message_type: MessageType,
        body_type: int,
    ) -> None:
        """Test general response with sleep mode and valid sensor values."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
        )
        body = bytearray(25)
        body[0] = body_type
        body[1] = 0x80 | 0x20 | 0x40  # power, child_lock, scheduled
        body[2] = 5  # fan_speed
        body[3] = 0x00
        body[4] = 53  # pm25
        body[5] = 0x01
        body[6] = 0x00  # co2 = 256
        body[7] = 0x00
        body[8] = 50  # current_humidity = 5.0
        body[9] = 0x00
        body[10] = 100  # current_temperature = 20.0
        body[11] = 0x00
        body[12] = 200  # hcho = 0.2
        body[17] = 0x01 | 0x02 | 0x08 | 0x10  # link_to_ac, sleep, aux, purify
        body[18] = 0x03  # both filter reminders
        body[19] = 0x02  # aux_heating supported
        body[24] = 7  # error_code
        crc = bytearray([0x00])
        new_status = self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.child_lock] is True
        assert self.device.attributes[DeviceAttributes.scheduled] is True
        assert self.device.attributes[DeviceAttributes.fan_speed] == 5
        assert self.device.attributes[DeviceAttributes.pm25] == 53
        assert self.device.attributes[DeviceAttributes.co2] == 256
        assert self.device.attributes[DeviceAttributes.current_humidity] == 5.0
        assert self.device.attributes[DeviceAttributes.current_temperature] == 20.0
        assert self.device.attributes[DeviceAttributes.hcho] == 0.2
        assert self.device.attributes[DeviceAttributes.link_to_ac] is True
        assert self.device.attributes[DeviceAttributes.sleep_mode] is True
        assert self.device.attributes[DeviceAttributes.eco_mode] is False
        assert self.device.attributes[DeviceAttributes.powerful_purify] is True
        assert self.device.attributes[DeviceAttributes.filter_cleaning_reminder] is True
        assert self.device.attributes[DeviceAttributes.filter_change_reminder] is True
        assert self.device.attributes[DeviceAttributes.error_code] == 7
        assert self.device.attributes[DeviceAttributes.mode] == "sleep_mode"
        assert self.device.attributes[DeviceAttributes.aux_heating] is True
        assert new_status[DeviceAttributes.mode.value] == "sleep_mode"

    def test_general_response_eco_mode_and_sensor_sentinels(self) -> None:
        """Test general response with ECO mode and 0xFF sensor sentinels."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.query],
        )
        body = bytearray(25)
        body[0] = 0x01
        body[7] = 0xFF  # no humidity
        body[9] = 0xFF  # no temperature
        body[11] = 0xFF  # no hcho
        body[17] = 0x04  # eco_mode
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.power] is False
        assert self.device.attributes[DeviceAttributes.current_humidity] is None
        assert self.device.attributes[DeviceAttributes.current_temperature] is None
        assert self.device.attributes[DeviceAttributes.hcho] is None
        assert self.device.attributes[DeviceAttributes.eco_mode] is True
        assert self.device.attributes[DeviceAttributes.mode] == "eco_mode"

    def test_notify_response(self) -> None:
        """Test notify1 response with body type 0x01."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.notify1],
        )
        body = bytearray(13)
        body[0] = 0x01
        body[1] = 0x00
        body[2] = 42  # pm25
        body[3] = 0x00
        body[4] = 120  # co2
        body[5] = 0x00
        body[6] = 80  # current_humidity = 8.0
        body[7] = 0x00
        body[8] = 70  # current_temperature = 5.0
        body[9] = 0x00
        body[10] = 100  # hcho = 0.1
        body[12] = 3  # error_code
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.pm25] == 42
        assert self.device.attributes[DeviceAttributes.co2] == 120
        assert self.device.attributes[DeviceAttributes.current_humidity] == 8.0
        assert self.device.attributes[DeviceAttributes.current_temperature] == 5.0
        assert self.device.attributes[DeviceAttributes.hcho] == 0.1
        assert self.device.attributes[DeviceAttributes.error_code] == 3
        assert self.device.attributes[DeviceAttributes.mode] == "normal"

    def test_notify_response_sensor_sentinels(self) -> None:
        """Test notify1 response with 0xFF sensor sentinels."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.notify1],
        )
        body = bytearray(13)
        body[0] = 0x01
        body[5] = 0xFF
        body[7] = 0xFF
        body[9] = 0xFF
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.current_humidity] is None
        assert self.device.attributes[DeviceAttributes.current_temperature] is None
        assert self.device.attributes[DeviceAttributes.hcho] is None

    def test_process_message_unhandled_type(self) -> None:
        """Test process message with unhandled type only reports mode."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.notify2],
        )
        body = bytearray(25)
        body[0] = 0x01
        crc = bytearray([0x00])
        new_status = self.device.process_message(bytes(header + body + crc))
        assert new_status == {DeviceAttributes.mode.value: "normal"}

    @pytest.mark.parametrize(
        ("value", "sleep_mode", "eco_mode"),
        [
            ("sleep_mode", True, False),
            ("eco_mode", False, True),
            ("normal", False, False),
        ],
    )
    def test_set_attribute_mode(
        self,
        value: str,
        sleep_mode: bool,
        eco_mode: bool,
    ) -> None:
        """Test set attribute mode."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.mode.value, value)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.sleep_mode is sleep_mode
            assert message.eco_mode is eco_mode

    def test_set_attribute(self) -> None:
        """Test set attribute sends a set message."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.fan_speed.value, 3)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.fan_speed == 3

    def test_set_customize(self) -> None:
        """Test set customize."""
        self.device.set_customize('{"speed_count": 5}')
        assert self.device.speed_count == 5

    def test_set_customize_invalid_json(self) -> None:
        """Test set customize with invalid JSON keeps the default."""
        self.device.set_customize("{")
        assert self.device.speed_count == 7
