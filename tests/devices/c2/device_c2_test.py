"""Test C2 Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.c2 import DeviceAttributes, MideaC2Device
from midealocal.devices.c2.message import MessagePower, MessageQuery, MessageSet
from midealocal.message import MessageType


class TestMideaC2Device:
    """Test Midea C2 Device."""

    device: MideaC2Device

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea C2 Device setup."""
        self.device = MideaC2Device(
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
        assert self.device.attributes[DeviceAttributes.child_lock] is False
        assert self.device.attributes[DeviceAttributes.sensor_light] is False
        assert self.device.attributes[DeviceAttributes.foam_shield] is False
        assert self.device.attributes[DeviceAttributes.light_status] is None
        assert self.device.attributes[DeviceAttributes.seat_status] is None
        assert self.device.attributes[DeviceAttributes.lid_status] is None
        assert self.device.attributes[DeviceAttributes.dry_level] == 0
        assert self.device.attributes[DeviceAttributes.water_temp_level] == 0
        assert self.device.attributes[DeviceAttributes.seat_temp_level] == 0
        assert self.device.attributes[DeviceAttributes.water_temperature] is None
        assert self.device.attributes[DeviceAttributes.seat_temperature] is None
        assert self.device.attributes[DeviceAttributes.filter_life] is None
        assert self.device.max_dry_level == 3
        assert self.device.max_water_temp_level == 5
        assert self.device.max_seat_temp_level == 5

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    @pytest.mark.parametrize(
        "message_type",
        [MessageType.query, MessageType.set, MessageType.notify1],
    )
    def test_process_message(self, message_type: MessageType) -> None:
        """Test process message updates all attributes."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
        )
        body = bytearray(20)
        body[0] = 0x01  # body type
        body[2] = 0x01  # power
        body[3] = 0x01  # seat_status
        body[6] = 0x02 << 1  # dry_level 2
        body[9] = 0x03 | (0x04 << 3)  # water_temp_level 3, seat_temp_level 4
        body[11] = 38  # water/seat temperature
        body[12] = 0x40  # lid_status
        body[13] = 0x80  # foam_shield
        body[14] = 0x07  # sensor_light, light_status, child_lock
        body[19] = 10  # filter life used
        crc = bytearray([0x00])
        new_status = self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.seat_status] is True
        assert self.device.attributes[DeviceAttributes.dry_level] == 2
        assert self.device.attributes[DeviceAttributes.water_temp_level] == 3
        assert self.device.attributes[DeviceAttributes.seat_temp_level] == 4
        assert self.device.attributes[DeviceAttributes.lid_status] is True
        assert self.device.attributes[DeviceAttributes.foam_shield] is True
        assert self.device.attributes[DeviceAttributes.sensor_light] is True
        assert self.device.attributes[DeviceAttributes.light_status] is True
        assert self.device.attributes[DeviceAttributes.child_lock] is True
        assert self.device.attributes[DeviceAttributes.water_temperature] == 38
        assert self.device.attributes[DeviceAttributes.seat_temperature] == 38
        assert self.device.attributes[DeviceAttributes.filter_life] == 90
        assert new_status[DeviceAttributes.power.value] is True

    def test_process_message_unhandled_type(self) -> None:
        """Test process message with an unhandled message type updates nothing."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.notify2],
        )
        body = bytearray(20)
        body[0] = 0x01
        crc = bytearray([0x00])
        new_status = self.device.process_message(bytes(header + body + crc))
        assert new_status == {}

    def test_set_attribute_power(self) -> None:
        """Test set attribute power sends a power message."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessagePower)
            assert message.power is True

    @pytest.mark.parametrize(
        ("attr", "value"),
        [
            (DeviceAttributes.child_lock, True),
            (DeviceAttributes.sensor_light, True),
            (DeviceAttributes.foam_shield, True),
            (DeviceAttributes.water_temp_level, 3),
            (DeviceAttributes.seat_temp_level, 4),
            (DeviceAttributes.dry_level, 2),
        ],
    )
    def test_set_attribute(self, attr: DeviceAttributes, value: bool | int) -> None:
        """Test set attribute sends a set message."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(attr.value, value)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert getattr(message, attr.value) == value

    def test_set_attribute_not_settable(self) -> None:
        """Test set attribute with a read-only attribute does not send."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.light_status.value, True)
            mock_build_send.assert_not_called()

    def test_set_customize(self) -> None:
        """Test set customize."""
        self.device.set_customize(
            '{"max_dry_level": 2, "max_water_temp_level": 4, "max_seat_temp_level": 3}',
        )
        assert self.device.max_dry_level == 2
        assert self.device.max_water_temp_level == 4
        assert self.device.max_seat_temp_level == 3

    def test_set_customize_invalid_json(self) -> None:
        """Test set customize with invalid JSON keeps defaults."""
        self.device.set_customize("{")
        assert self.device.max_dry_level == 3
        assert self.device.max_water_temp_level == 5
        assert self.device.max_seat_temp_level == 5
