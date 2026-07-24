"""Test B3 Device."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.b3 import DeviceAttributes, MideaB3Device
from midealocal.devices.b3.message import MessageQuery
from midealocal.message import MessageType


class TestMideaB3Device:
    """Test Midea B3 Device."""

    device: MideaB3Device

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea B3 Device setup."""
        self.device = MideaB3Device(
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
        assert self.device.attributes[DeviceAttributes.top_compartment_status] is None
        assert self.device.attributes[DeviceAttributes.top_compartment_mode] is None
        assert (
            self.device.attributes[DeviceAttributes.top_compartment_temperature] is None
        )
        assert (
            self.device.attributes[DeviceAttributes.top_compartment_remaining] is None
        )
        assert self.device.attributes[DeviceAttributes.top_compartment_door] is False
        assert (
            self.device.attributes[DeviceAttributes.top_compartment_preheating] is False
        )
        assert self.device.attributes[DeviceAttributes.top_compartment_cooling] is False
        assert (
            self.device.attributes[DeviceAttributes.middle_compartment_status] is None
        )
        assert self.device.attributes[DeviceAttributes.middle_compartment_mode] is None
        assert (
            self.device.attributes[DeviceAttributes.middle_compartment_temperature]
            is None
        )
        assert (
            self.device.attributes[DeviceAttributes.middle_compartment_remaining]
            is None
        )
        assert self.device.attributes[DeviceAttributes.middle_compartment_door] is False
        assert (
            self.device.attributes[DeviceAttributes.middle_compartment_preheating]
            is False
        )
        assert (
            self.device.attributes[DeviceAttributes.middle_compartment_cooling] is False
        )
        assert (
            self.device.attributes[DeviceAttributes.bottom_compartment_status] is None
        )
        assert self.device.attributes[DeviceAttributes.bottom_compartment_mode] is None
        assert (
            self.device.attributes[DeviceAttributes.bottom_compartment_temperature]
            is None
        )
        assert (
            self.device.attributes[DeviceAttributes.bottom_compartment_remaining]
            is None
        )
        assert self.device.attributes[DeviceAttributes.bottom_compartment_door] is False
        assert (
            self.device.attributes[DeviceAttributes.bottom_compartment_preheating]
            is False
        )
        assert (
            self.device.attributes[DeviceAttributes.bottom_compartment_cooling] is False
        )
        assert self.device.attributes[DeviceAttributes.lock] is False

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    def test_set_attribute(self) -> None:
        """Test set attribute is a no-op."""
        self.device.set_attribute(DeviceAttributes.lock.value, True)
        assert self.device.attributes[DeviceAttributes.lock] is False

    def test_query_x31_response(self) -> None:
        """Test query response with body type 0x31 and hour remaining bytes."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.query],
        )
        body = bytearray(26)
        body[0] = 0x31  # Body type
        body[1] = 0x02  # top status Working
        body[2] = 0x01  # top mode
        body[3] = 50  # top temperature
        body[4] = 0xFF
        body[5] = 0xFF
        body[6] = 0x01  # bottom status Standby
        body[7] = 0x02  # bottom mode
        body[8] = 60  # bottom temperature
        body[9] = 0xFF
        body[10] = 0xFF
        body[11] = 0x17  # lock + bottom door + top door + middle door
        body[16] = 0x3F  # all preheating + cooling
        body[17] = 0x03  # middle status Delay
        body[18] = 0x03  # middle mode
        body[19] = 70  # middle temperature
        body[20] = 0xFF
        body[21] = 0xFF
        body[23] = 1  # top remaining hours
        body[24] = 2  # bottom remaining hours
        body[25] = 3  # middle remaining hours
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert (
            self.device.attributes[DeviceAttributes.top_compartment_status] == "Working"
        )
        assert self.device.attributes[DeviceAttributes.top_compartment_mode] == 1
        assert (
            self.device.attributes[DeviceAttributes.top_compartment_temperature] == 50
        )
        assert (
            self.device.attributes[DeviceAttributes.top_compartment_remaining] == 3600
        )
        assert self.device.attributes[DeviceAttributes.top_compartment_door] is True
        assert (
            self.device.attributes[DeviceAttributes.top_compartment_preheating] is True
        )
        assert self.device.attributes[DeviceAttributes.top_compartment_cooling] is True
        assert (
            self.device.attributes[DeviceAttributes.bottom_compartment_status]
            == "Standby"
        )
        assert self.device.attributes[DeviceAttributes.bottom_compartment_mode] == 2
        assert (
            self.device.attributes[DeviceAttributes.bottom_compartment_temperature]
            == 60
        )
        assert (
            self.device.attributes[DeviceAttributes.bottom_compartment_remaining]
            == 7200
        )
        assert self.device.attributes[DeviceAttributes.bottom_compartment_door] is True
        assert (
            self.device.attributes[DeviceAttributes.bottom_compartment_preheating]
            is True
        )
        assert (
            self.device.attributes[DeviceAttributes.bottom_compartment_cooling] is True
        )
        assert (
            self.device.attributes[DeviceAttributes.middle_compartment_status]
            == "Delay"
        )
        assert self.device.attributes[DeviceAttributes.middle_compartment_mode] == 3
        assert (
            self.device.attributes[DeviceAttributes.middle_compartment_temperature]
            == 70
        )
        assert (
            self.device.attributes[DeviceAttributes.middle_compartment_remaining]
            == 10800
        )
        assert self.device.attributes[DeviceAttributes.middle_compartment_door] is True
        assert (
            self.device.attributes[DeviceAttributes.middle_compartment_preheating]
            is True
        )
        assert (
            self.device.attributes[DeviceAttributes.middle_compartment_cooling] is True
        )
        assert self.device.attributes[DeviceAttributes.lock] is True

    def test_notify1_x41_response(self) -> None:
        """Test notify1 response with body type 0x41 and short body fallbacks."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.notify1],
        )
        body = bytearray(22)
        body[0] = 0x41  # Body type
        body[1] = 0x00  # top status Off
        body[2] = 0x00  # top mode
        body[3] = 0  # top temperature
        body[4] = 2  # top remaining minutes -> 120
        body[5] = 0xFF
        body[6] = 0x04  # bottom status Finished
        body[7] = 1  # bottom mode
        body[8] = 30  # bottom temperature
        body[9] = 0xFF
        body[10] = 5  # bottom remaining -> 5
        body[17] = 0x77  # middle status invalid -> None
        body[18] = 2  # middle mode
        body[19] = 40  # middle temperature
        body[20] = 0xFF
        body[21] = 0xFF  # middle remaining -> 0
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.top_compartment_status] == "Off"
        assert self.device.attributes[DeviceAttributes.top_compartment_remaining] == 120
        assert (
            self.device.attributes[DeviceAttributes.bottom_compartment_status]
            == "Finished"
        )
        assert (
            self.device.attributes[DeviceAttributes.bottom_compartment_remaining] == 5
        )
        assert (
            self.device.attributes[DeviceAttributes.middle_compartment_status] is None
        )
        assert (
            self.device.attributes[DeviceAttributes.middle_compartment_remaining] == 0
        )
        assert self.device.attributes[DeviceAttributes.top_compartment_door] is False
        assert self.device.attributes[DeviceAttributes.bottom_compartment_door] is False
        assert self.device.attributes[DeviceAttributes.middle_compartment_door] is False
        assert (
            self.device.attributes[DeviceAttributes.top_compartment_preheating] is False
        )
        assert self.device.attributes[DeviceAttributes.top_compartment_cooling] is False
        assert self.device.attributes[DeviceAttributes.lock] is False

    def test_query_x00_response(self) -> None:
        """Test query response with body type 0x00."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.query],
        )
        body = bytearray(32)
        body[0] = 0x00  # Body type
        body[1] = 0x02  # top status Working
        body[2] = 1  # top mode
        body[3] = 50  # top temperature
        body[4] = 1  # top hours -> 60
        body[5] = 2  # top minutes -> 2
        body[6] = 60  # top seconds -> 1.0
        body[10] = 0x01  # bottom status Standby
        body[11] = 2  # bottom mode
        body[12] = 65  # bottom temperature
        body[13] = 0  # bottom hours -> 0
        body[14] = 10  # bottom minutes -> 10
        body[15] = 120  # bottom seconds -> 2.0
        body[19] = 0x03  # middle status Delay
        body[20] = 1  # middle mode
        body[21] = 70  # middle temperature
        body[30] = 0x0F  # lock + all doors
        body[31] = 0x3F  # all preheating + cooling
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert (
            self.device.attributes[DeviceAttributes.top_compartment_status] == "Working"
        )
        assert (
            self.device.attributes[DeviceAttributes.top_compartment_remaining] == 63.0
        )
        assert (
            self.device.attributes[DeviceAttributes.bottom_compartment_status]
            == "Standby"
        )
        assert (
            self.device.attributes[DeviceAttributes.bottom_compartment_remaining]
            == 12.0
        )
        assert (
            self.device.attributes[DeviceAttributes.middle_compartment_status]
            == "Delay"
        )
        assert (
            self.device.attributes[DeviceAttributes.middle_compartment_remaining] == 0.0
        )
        assert self.device.attributes[DeviceAttributes.lock] is True
        assert self.device.attributes[DeviceAttributes.top_compartment_door] is True
        assert self.device.attributes[DeviceAttributes.bottom_compartment_door] is True
        assert self.device.attributes[DeviceAttributes.middle_compartment_door] is True
        assert (
            self.device.attributes[DeviceAttributes.top_compartment_preheating] is True
        )
        assert self.device.attributes[DeviceAttributes.top_compartment_cooling] is True
        assert (
            self.device.attributes[DeviceAttributes.bottom_compartment_preheating]
            is True
        )
        assert (
            self.device.attributes[DeviceAttributes.bottom_compartment_cooling] is True
        )
        assert (
            self.device.attributes[DeviceAttributes.middle_compartment_preheating]
            is True
        )
        assert (
            self.device.attributes[DeviceAttributes.middle_compartment_cooling] is True
        )

    def test_notify1_x00_response(self) -> None:
        """Test notify1 response with body type 0x00 and all 0xFF timers."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.notify1],
        )
        body = bytearray(32)
        body[0] = 0x00  # Body type
        body[1] = 0x04  # top status Finished
        body[4] = 0xFF
        body[5] = 0xFF
        body[6] = 0xFF
        body[10] = 0x00  # bottom status Off
        body[13] = 0xFF
        body[14] = 0xFF
        body[15] = 0xFF
        body[19] = 0x77  # middle status invalid -> None
        body[22] = 0xFF
        body[23] = 0xFF
        body[24] = 0xFF
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert (
            self.device.attributes[DeviceAttributes.top_compartment_status]
            == "Finished"
        )
        assert self.device.attributes[DeviceAttributes.top_compartment_remaining] == 0
        assert (
            self.device.attributes[DeviceAttributes.bottom_compartment_status] == "Off"
        )
        assert (
            self.device.attributes[DeviceAttributes.bottom_compartment_remaining] == 0
        )
        assert (
            self.device.attributes[DeviceAttributes.middle_compartment_status] is None
        )
        assert (
            self.device.attributes[DeviceAttributes.middle_compartment_remaining] == 0
        )
        assert self.device.attributes[DeviceAttributes.lock] is False
        assert self.device.attributes[DeviceAttributes.top_compartment_door] is False
        assert (
            self.device.attributes[DeviceAttributes.top_compartment_preheating] is False
        )

    def test_set_x21_response(self) -> None:
        """Test set response with body type 0x21 and hour remaining bytes."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.set],
        )
        body = bytearray(20)
        body[0] = 0x21  # Body type
        body[1] = 0x01  # top status Standby
        body[2] = 1  # top mode
        body[3] = 40  # top temperature
        body[4] = 0xFF
        body[5] = 0xFF
        body[6] = 0x02  # bottom status Working
        body[7] = 2  # bottom mode
        body[8] = 50  # bottom temperature
        body[9] = 0xFF
        body[10] = 0xFF
        body[11] = 0x01  # lock
        body[12] = 0x00  # middle status Off
        body[17] = 1  # top remaining hours
        body[18] = 2  # bottom remaining hours
        body[19] = 3  # middle remaining hours
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert (
            self.device.attributes[DeviceAttributes.top_compartment_status] == "Standby"
        )
        assert (
            self.device.attributes[DeviceAttributes.top_compartment_remaining] == 3600
        )
        assert (
            self.device.attributes[DeviceAttributes.bottom_compartment_status]
            == "Working"
        )
        assert (
            self.device.attributes[DeviceAttributes.bottom_compartment_remaining]
            == 7200
        )
        assert (
            self.device.attributes[DeviceAttributes.middle_compartment_status] == "Off"
        )
        assert (
            self.device.attributes[DeviceAttributes.middle_compartment_remaining]
            == 10800
        )
        assert self.device.attributes[DeviceAttributes.lock] is True

    def test_set_x24_response(self) -> None:
        """Test set response with body type 0x24 and short body fallbacks."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.set],
        )
        body = bytearray(17)
        body[0] = 0x24  # Body type
        body[1] = 0x00  # top status Off
        body[4] = 0xFF
        body[5] = 3  # top remaining -> 3
        body[6] = 0x04  # bottom status Finished
        body[9] = 1  # bottom remaining minutes -> 60
        body[11] = 0x00  # lock off
        body[12] = 0x03  # middle status Delay
        body[15] = 0xFF
        body[16] = 0xFF  # middle remaining -> 0
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.top_compartment_status] == "Off"
        assert self.device.attributes[DeviceAttributes.top_compartment_remaining] == 3
        assert (
            self.device.attributes[DeviceAttributes.bottom_compartment_status]
            == "Finished"
        )
        assert (
            self.device.attributes[DeviceAttributes.bottom_compartment_remaining] == 60
        )
        assert (
            self.device.attributes[DeviceAttributes.middle_compartment_status]
            == "Delay"
        )
        assert (
            self.device.attributes[DeviceAttributes.middle_compartment_remaining] == 0
        )
        assert self.device.attributes[DeviceAttributes.lock] is False

    @pytest.mark.parametrize(
        ("message_type", "body_type"),
        [
            (MessageType.query, 0x21),
            (MessageType.set, 0x31),
            (MessageType.notify1, 0x31),
            (MessageType.notify2, 0x00),
        ],
    )
    def test_unexpected_response(
        self,
        message_type: MessageType,
        body_type: int,
    ) -> None:
        """Test unexpected response updates no attribute."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
        )
        body = bytearray([body_type] + [0x00] * 32)
        new_status = self.device.process_message(bytes(header + body))
        assert new_status == {}
