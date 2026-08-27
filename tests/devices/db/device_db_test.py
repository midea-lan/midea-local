"""Test DB Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.db import DeviceAttributes, MideaDBDevice
from midealocal.devices.db.message import MessagePower, MessageQuery, MessageStart
from midealocal.exceptions import ValueWrongType
from midealocal.message import MessageType


class TestMideaDBDevice:
    """Test Midea DB Device."""

    device: MideaDBDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea DB Device setup."""
        self.device = MideaDBDevice(
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
        assert self.device.attributes[DeviceAttributes.start] is False
        assert self.device.attributes[DeviceAttributes.status] is None
        assert self.device.attributes[DeviceAttributes.mode] is None
        assert self.device.attributes[DeviceAttributes.program] is None
        assert self.device.attributes[DeviceAttributes.water_level] is None
        assert self.device.attributes[DeviceAttributes.temperature] is None
        assert self.device.attributes[DeviceAttributes.dehydration_speed] is None
        assert self.device.attributes[DeviceAttributes.wash_time] is None
        assert self.device.attributes[DeviceAttributes.dehydration_time] is None
        assert self.device.attributes[DeviceAttributes.detergent] is None
        assert self.device.attributes[DeviceAttributes.softener] is None
        assert self.device.attributes[DeviceAttributes.washing_data] == bytearray([])
        assert self.device.attributes[DeviceAttributes.progress] is None
        assert self.device.attributes[DeviceAttributes.stains] is None
        assert self.device.attributes[DeviceAttributes.time_remaining] is None
        assert self.device.attributes[DeviceAttributes.wash_time_value] is None
        assert self.device.attributes[DeviceAttributes.dehydration_time_value] is None
        assert self.device.attributes[DeviceAttributes.dirty_degree] is None

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    @pytest.mark.parametrize(
        "message_type",
        [MessageType.query, MessageType.set],
    )
    def test_query_set_response(self, message_type: MessageType) -> None:
        """Test query/set response with mapped values."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
        )
        body = bytearray(31)
        body[0] = 0x03  # Body type
        body[1] = 0x01  # power
        body[2] = 0x02  # status start
        body[3] = 0x00  # mode normal
        body[4] = 0x02  # program fast_wash
        body[5] = 0x03  # water level High
        body[7] = 0x04  # temperature 40
        body[8] = 0x05  # dehydration speed 1200
        body[9] = 0x28  # wash time
        body[10] = 0x0A  # dehydration time
        body[11] = 0x01  # detergent
        body[12] = 0x02  # softener
        body[16] = 0x01  # progress Spin
        body[17] = 30  # time remaining low byte
        body[18] = 1  # time remaining high byte
        body[26] = 0x03  # stains
        body[27] = 0x28  # wash time value
        body[28] = 0x0A  # dehydration time value
        body[30] = 0x04  # dirty degree
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.start] is True
        assert self.device.attributes[DeviceAttributes.status] == "start"
        assert self.device.attributes[DeviceAttributes.mode] == "normal"
        assert self.device.attributes[DeviceAttributes.program] == "fast_wash"
        assert self.device.attributes[DeviceAttributes.water_level] == "high"
        assert self.device.attributes[DeviceAttributes.temperature] == "40"
        assert self.device.attributes[DeviceAttributes.dehydration_speed] == "1200"
        assert self.device.attributes[DeviceAttributes.wash_time] == 0x28
        assert self.device.attributes[DeviceAttributes.dehydration_time] == 0x0A
        assert self.device.attributes[DeviceAttributes.detergent] == 1
        assert self.device.attributes[DeviceAttributes.softener] == 2
        assert self.device.attributes[DeviceAttributes.washing_data] == body[3:16]
        assert self.device.attributes[DeviceAttributes.progress] == "spin"
        assert self.device.attributes[DeviceAttributes.stains] == 3
        assert self.device.attributes[DeviceAttributes.time_remaining] == 286
        assert self.device.attributes[DeviceAttributes.wash_time_value] == 0x28
        assert self.device.attributes[DeviceAttributes.dehydration_time_value] == 0x0A
        assert self.device.attributes[DeviceAttributes.dirty_degree] == 4

    def test_notify1_response_unmapped_values(self) -> None:
        """Test notify1 response with unmapped values."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.notify1],
        )
        body = bytearray(31)
        body[0] = 0x04  # Body type
        body[2] = 9  # unmapped status
        body[3] = 5  # unmapped mode
        body[4] = 0x41  # unmapped program
        body[5] = 0x06  # unmapped water level
        body[7] = 0x10  # unmapped temperature
        body[8] = 0x09  # unmapped dehydration speed
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.power] is False
        assert self.device.attributes[DeviceAttributes.start] is False
        assert self.device.attributes[DeviceAttributes.status] == 9
        assert self.device.attributes[DeviceAttributes.mode] == 5
        assert self.device.attributes[DeviceAttributes.program] == 0x41
        assert self.device.attributes[DeviceAttributes.water_level] == 6
        assert self.device.attributes[DeviceAttributes.temperature] == 0x10
        assert self.device.attributes[DeviceAttributes.dehydration_speed] == 9
        assert self.device.attributes[DeviceAttributes.progress] == "idle"
        assert self.device.attributes[DeviceAttributes.time_remaining] is None

    def test_unexpected_response(self) -> None:
        """Test notify1 response with unexpected body type updates no attribute."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.notify1],
        )
        body = bytearray(31)
        body[0] = 0x03  # unexpected body type for notify1
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

    def test_set_attribute_start(self) -> None:
        """Test set attribute start sends a start message."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.start.value, True)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageStart)
            assert message.start is True
            assert message.washing_data == bytearray([])

    def test_set_attribute_not_supported(self) -> None:
        """Test set attribute with an unsupported attribute does not send."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.detergent.value, True)
            mock_build_send.assert_not_called()

    def test_set_attribute_wrong_type(self) -> None:
        """Test set attribute with a non-bool value raises and does not send."""
        with (
            patch.object(self.device, "build_send") as mock_build_send,
            pytest.raises(ValueWrongType),
        ):
            self.device.set_attribute(DeviceAttributes.power.value, 5)
        mock_build_send.assert_not_called()
