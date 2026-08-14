"""Test DC Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.dc import DeviceAttributes, MideaDCDevice
from midealocal.devices.dc.message import MessagePower, MessageQuery, MessageStart
from midealocal.exceptions import ValueWrongType
from midealocal.message import MessageType


class TestMideaDCDevice:
    """Test Midea DC Device."""

    device: MideaDCDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea DC Device setup."""
        self.device = MideaDCDevice(
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
        assert self.device.attributes[DeviceAttributes.status] == "Unknown"
        assert self.device.attributes[DeviceAttributes.program] == "None"
        assert self.device.attributes[DeviceAttributes.intensity] is None
        assert self.device.attributes[DeviceAttributes.dryness_level] is None
        assert self.device.attributes[DeviceAttributes.dry_temperature] is None
        assert self.device.attributes[DeviceAttributes.error_code] is None
        assert self.device.attributes[DeviceAttributes.door_warn] is None
        assert self.device.attributes[DeviceAttributes.ai_switch] is None
        assert self.device.attributes[DeviceAttributes.material] is None
        assert self.device.attributes[DeviceAttributes.water_box] is None
        assert self.device.attributes[DeviceAttributes.washing_data] == bytearray([])
        assert self.device.attributes[DeviceAttributes.progress] == "Unknown"
        assert self.device.attributes[DeviceAttributes.time_remaining] is None

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
        """Test query/set response with mapped status and program."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
        )
        body = bytearray(30)
        body[0] = 0x03  # Body type
        body[1] = 0x01  # power
        body[2] = 0x02  # status start
        body[4] = 0x01  # program fiber
        body[9] = 0x03  # intensity
        body[10] = 0x04  # dryness level / dry temperature
        body[16] = 0x01  # progress
        body[17] = 30  # time remaining minutes
        body[18] = 1  # time remaining hours
        body[24] = 0x05  # error code
        body[25] = 0x06  # door warn
        body[27] = 0x07  # ai switch
        body[28] = 0x08  # material
        body[29] = 0x09  # water box
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.start] is True
        assert self.device.attributes[DeviceAttributes.status] == "start"
        assert self.device.attributes[DeviceAttributes.program] == "fiber"
        assert self.device.attributes[DeviceAttributes.intensity] == 3
        assert self.device.attributes[DeviceAttributes.dryness_level] == 4
        assert self.device.attributes[DeviceAttributes.dry_temperature] == 4
        assert self.device.attributes[DeviceAttributes.error_code] == 5
        assert self.device.attributes[DeviceAttributes.door_warn] == 6
        assert self.device.attributes[DeviceAttributes.ai_switch] == 7
        assert self.device.attributes[DeviceAttributes.material] == 8
        assert self.device.attributes[DeviceAttributes.water_box] == 9
        assert self.device.attributes[DeviceAttributes.washing_data] == body[3:15]
        assert self.device.attributes[DeviceAttributes.progress] is None
        assert self.device.attributes[DeviceAttributes.time_remaining] == 90

    def test_query_set_response_mapped_progress(self) -> None:
        """Test query/set response with a valid progress bit set."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.query],
        )
        body = bytearray(30)
        body[0] = 0x03  # Body type
        body[16] = 0x02  # progress bit 1
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.progress] == "prog1"

    def test_notify1_response_unmapped_values(self) -> None:
        """Test notify1 response with unmapped status and program values."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.notify1],
        )
        body = bytearray(30)
        body[0] = 0x04  # Body type
        body[2] = 20  # unmapped status
        body[4] = 99  # unmapped program
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.power] is False
        assert self.device.attributes[DeviceAttributes.start] is False
        assert self.device.attributes[DeviceAttributes.status] == 20
        assert self.device.attributes[DeviceAttributes.program] == 99
        assert self.device.attributes[DeviceAttributes.progress] is None
        assert self.device.attributes[DeviceAttributes.time_remaining] is None

    def test_unexpected_response(self) -> None:
        """Test notify1 response with unexpected body type updates no attribute."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.notify1],
        )
        body = bytearray(30)
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
            self.device.set_attribute(DeviceAttributes.ai_switch.value, True)
            mock_build_send.assert_not_called()

    def test_set_attribute_wrong_type(self) -> None:
        """Test set attribute with a non-bool value raises and does not send."""
        with (
            patch.object(self.device, "build_send") as mock_build_send,
            pytest.raises(ValueWrongType),
        ):
            self.device.set_attribute(DeviceAttributes.power.value, 5)
        mock_build_send.assert_not_called()
