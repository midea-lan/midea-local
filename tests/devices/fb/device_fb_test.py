"""Test FB Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.fb import DeviceAttributes, MideaFBDevice
from midealocal.devices.fb.message import MessageQuery, MessageSet
from midealocal.message import MessageType


class TestMideaFBDevice:
    """Test Midea FB Device."""

    device: MideaFBDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea FB Device setup."""
        self.device = MideaFBDevice(
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
        assert self.device.attributes[DeviceAttributes.heating_level] == 0
        assert self.device.attributes[DeviceAttributes.target_temperature] is None
        assert self.device.attributes[DeviceAttributes.current_temperature] is None
        assert self.device.attributes[DeviceAttributes.child_lock] is False
        assert self.device.modes == [
            "auto",
            "eco",
            "sleep",
            "anti_freezing",
            "comfort",
            "constant_temperature",
            "normal",
            "fast_heating",
            "standby",
        ]

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
        """Test process message with a full body."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
        )
        body = bytearray(22)
        body[0] = 0x01  # power on
        body[4] = 0x02  # mode eco
        body[5] = 3  # heating_level
        body[6] = 66  # target_temperature = 25
        body[7] = 50  # target_humidity
        body[12] = 45  # current_humidity
        body[13] = 45  # current_temperature = 25
        body[18] = 0x01  # child_lock
        body[20] = 0x10
        body[21] = 0x01  # energy_consumption = 272
        crc = bytearray([0x00])
        new_status = self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.mode] == "eco"
        assert self.device.attributes[DeviceAttributes.heating_level] == 3
        assert self.device.attributes[DeviceAttributes.target_temperature] == 25
        assert self.device.attributes[DeviceAttributes.current_temperature] == 25
        assert self.device.attributes[DeviceAttributes.child_lock] is True
        assert new_status[DeviceAttributes.mode.value] == "eco"

    def test_process_message_unknown_mode_and_short_body(self) -> None:
        """Test process message with an unknown mode and a short body."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.query],
        )
        body = bytearray(18)
        body[0] = 0x00  # power off
        body[4] = 0x09  # unknown mode
        body[13] = 40  # current_temperature = 20
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.power] is False
        assert self.device.attributes[DeviceAttributes.mode] is None
        assert self.device.attributes[DeviceAttributes.current_temperature] == 20
        # short body has no child_lock byte, attribute keeps its default
        assert self.device.attributes[DeviceAttributes.child_lock] is False

    def test_process_message_unhandled_type(self) -> None:
        """Test process message with an unhandled message type updates nothing."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.notify2],
        )
        body = bytearray(22)
        body[0] = 0x01
        crc = bytearray([0x00])
        new_status = self.device.process_message(bytes(header + body + crc))
        assert new_status == {}

    def test_set_attribute_mode(self) -> None:
        """Test set attribute mode with a valid mode name."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.mode.value, "eco")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.mode == 0x02

    def test_set_attribute_mode_invalid(self) -> None:
        """Test set attribute mode with an invalid mode name leaves mode unset."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.mode.value, "invalid")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.mode is None

    @pytest.mark.parametrize(
        ("attr", "value"),
        [
            (DeviceAttributes.power, True),
            (DeviceAttributes.heating_level, 5),
            (DeviceAttributes.target_temperature, 25),
            (DeviceAttributes.child_lock, True),
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

    def test_set_target_temperature(self) -> None:
        """Test set target temperature."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_target_temperature(25, None)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.target_temperature == 25
