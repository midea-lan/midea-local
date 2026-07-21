"""Test x34 Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.x34 import DeviceAttributes, Midea34Device
from midealocal.devices.x34.message import (
    MessageLock,
    MessagePower,
    MessageQuery,
    MessageStorage,
)
from midealocal.exceptions import ValueWrongType
from midealocal.message import MessageType


class TestMidea34Device:
    """Test Midea x34 Device."""

    device: Midea34Device

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea x34 Device setup."""
        self.device = Midea34Device(
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
        assert self.device.attributes[DeviceAttributes.status] is None
        assert self.device.attributes[DeviceAttributes.mode] == 0
        assert self.device.attributes[DeviceAttributes.additional] == 0
        assert self.device.attributes[DeviceAttributes.uv] is False
        assert self.device.attributes[DeviceAttributes.dry] is False
        assert self.device.attributes[DeviceAttributes.dry_status] is False
        assert self.device.attributes[DeviceAttributes.door] is False
        assert self.device.attributes[DeviceAttributes.rinse_aid] is False
        assert self.device.attributes[DeviceAttributes.salt] is False
        assert self.device.attributes[DeviceAttributes.child_lock] is False
        assert self.device.attributes[DeviceAttributes.storage] is False
        assert self.device.attributes[DeviceAttributes.storage_status] is False
        assert self.device.attributes[DeviceAttributes.time_remaining] is None
        assert self.device.attributes[DeviceAttributes.progress] is None
        assert self.device.attributes[DeviceAttributes.storage_remaining] is None
        assert self.device.attributes[DeviceAttributes.temperature] is None
        assert self.device.attributes[DeviceAttributes.humidity] is None
        assert self.device.attributes[DeviceAttributes.waterswitch] is False
        assert self.device.attributes[DeviceAttributes.water_lack] is False
        assert self.device.attributes[DeviceAttributes.error_code] is None
        assert self.device.attributes[DeviceAttributes.softwater] == 0
        assert self.device.attributes[DeviceAttributes.wrong_operation] is None
        assert self.device.attributes[DeviceAttributes.bright] == 0

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    def test_process_message_query(self) -> None:
        """Test process message with a full query response."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.query],
        )
        body = bytearray(34)
        body[0] = 0x00  # body type
        body[1] = 3  # status Running, power on
        body[2] = 0x02  # mode Heavy
        body[3] = 0x01  # additional
        body[4] = 0x36  # uv, waterswitch, dry, dry_status
        body[5] = 0xF6  # door open, rinse_aid, salt, child_lock, storage bits
        body[6] = 45  # time remaining
        body[9] = 2  # progress Wash
        body[10] = 0  # error code
        body[11] = 55  # temperature
        body[13] = 7  # softwater
        body[16] = 1  # wrong operation
        body[18] = 12  # storage remaining
        body[24] = 100  # bright
        body[33] = 60  # humidity
        crc = bytearray([0x00])
        new_status = self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.status] == "Running"
        assert self.device.attributes[DeviceAttributes.mode] == "Heavy"
        assert self.device.attributes[DeviceAttributes.additional] == 1
        assert self.device.attributes[DeviceAttributes.uv] is True
        assert self.device.attributes[DeviceAttributes.dry] is True
        assert self.device.attributes[DeviceAttributes.dry_status] is True
        assert self.device.attributes[DeviceAttributes.door] is True
        assert self.device.attributes[DeviceAttributes.rinse_aid] is True
        assert self.device.attributes[DeviceAttributes.salt] is True
        assert self.device.attributes[DeviceAttributes.child_lock] is True
        assert self.device.attributes[DeviceAttributes.storage] is True
        assert self.device.attributes[DeviceAttributes.storage_status] is True
        assert self.device.attributes[DeviceAttributes.time_remaining] == 45
        assert self.device.attributes[DeviceAttributes.progress] == "Wash"
        assert self.device.attributes[DeviceAttributes.storage_remaining] == 12
        assert self.device.attributes[DeviceAttributes.temperature] == 55
        assert self.device.attributes[DeviceAttributes.humidity] == 60
        assert self.device.attributes[DeviceAttributes.waterswitch] is True
        assert self.device.attributes[DeviceAttributes.water_lack] is True
        assert self.device.attributes[DeviceAttributes.error_code] == 0
        assert self.device.attributes[DeviceAttributes.softwater] == 7
        assert self.device.attributes[DeviceAttributes.wrong_operation] == 1
        assert self.device.attributes[DeviceAttributes.bright] == 100
        assert new_status[DeviceAttributes.status.value] == "Running"

    def test_process_message_notify(self) -> None:
        """Test process message with a short notify1 response."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.notify1],
        )
        body = bytearray(25)
        body[0] = 0x00  # body type
        body[1] = 1  # status Idle, power on
        body[2] = 0x19  # mode Cloud Wash
        body[5] = 0x09  # door closed, start_pause
        body[9] = 6  # progress out of range
        body[24] = 5  # bright
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.status] == "Idle"
        assert self.device.attributes[DeviceAttributes.mode] == "Cloud Wash"
        assert self.device.attributes[DeviceAttributes.door] is False
        assert self.device.attributes[DeviceAttributes.progress] is None
        assert self.device.attributes[DeviceAttributes.humidity] is None
        assert self.device.attributes[DeviceAttributes.storage_remaining] == 0
        assert self.device.attributes[DeviceAttributes.bright] == 5

    def test_process_message_set(self) -> None:
        """Test process message with a set response and out-of-range status."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.set],
        )
        body = bytearray(25)
        body[0] = 0x01  # body type within set range
        body[1] = 5  # status out of range
        body[2] = 0x00  # mode Neutral Gear
        body[9] = 0  # progress Idle
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.status] is None
        assert self.device.attributes[DeviceAttributes.mode] == "Neutral Gear"
        assert self.device.attributes[DeviceAttributes.progress] == "Idle"

    @pytest.mark.parametrize(
        ("message_type", "body_type"),
        [
            (MessageType.query, 0x10),  # query with non-zero body type
            (MessageType.set, 0x08),  # set with body type above range
            (MessageType.notify2, 0x00),  # unhandled message type
        ],
    )
    def test_process_message_unhandled(
        self,
        message_type: MessageType,
        body_type: int,
    ) -> None:
        """Test process message with unhandled responses updates nothing."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
        )
        body = bytearray(25)
        body[0] = body_type
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

    def test_set_attribute_child_lock(self) -> None:
        """Test set attribute child lock sends a lock message."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.child_lock.value, True)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageLock)
            assert message.lock is True

    def test_set_attribute_storage(self) -> None:
        """Test set attribute storage sends a storage message."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.storage.value, True)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageStorage)
            assert message.storage is True

    def test_set_attribute_not_settable(self) -> None:
        """Test set attribute with a read-only attribute does not send."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.uv.value, True)
            mock_build_send.assert_not_called()

    def test_set_attribute_wrong_type(self) -> None:
        """Test set attribute with a non-bool value raises."""
        with (
            patch.object(self.device, "build_send") as mock_build_send,
            pytest.raises(ValueWrongType),
        ):
            self.device.set_attribute(DeviceAttributes.power.value, 1)
        mock_build_send.assert_not_called()
