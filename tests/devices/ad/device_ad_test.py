"""Test AD Device."""

import pytest

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.devices.ad import DeviceAttributes, MideaADDevice
from midealocal.devices.ad.message import Message21Query, Message31Query
from midealocal.message import MessageType


class TestMideaADDevice:
    """Test Midea AD Device."""

    device: MideaADDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea AD Device setup."""
        self.device = MideaADDevice(
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
        assert self.device.attributes[DeviceAttributes.temperature] is None
        assert self.device.attributes[DeviceAttributes.humidity] is None
        assert self.device.attributes[DeviceAttributes.tvoc] is None
        assert self.device.attributes[DeviceAttributes.co2] is None
        assert self.device.attributes[DeviceAttributes.pm25] is None
        assert self.device.attributes[DeviceAttributes.hcho] is None
        assert self.device.attributes[DeviceAttributes.presets_function] is False
        assert self.device.attributes[DeviceAttributes.fall_asleep_status] is False
        assert self.device.attributes[DeviceAttributes.portable_sense] is False
        assert self.device.attributes[DeviceAttributes.night_mode] is False
        assert (
            self.device.attributes[DeviceAttributes.screen_extinction_timeout] is None
        )
        assert self.device.attributes[DeviceAttributes.screen_status] is False
        assert self.device.attributes[DeviceAttributes.led_status] is False
        assert self.device.attributes[DeviceAttributes.arofene_link] is False
        assert self.device.attributes[DeviceAttributes.header_exist] is False
        assert self.device.attributes[DeviceAttributes.radar_exist] is False
        assert self.device.attributes[DeviceAttributes.header_led_status] is False
        assert self.device.attributes[DeviceAttributes.temperature_raw] is None
        assert self.device.attributes[DeviceAttributes.humidity_raw] is None
        assert self.device.attributes[DeviceAttributes.temperature_compensate] is None
        assert self.device.attributes[DeviceAttributes.humidity_compensate] is None

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 2
        assert isinstance(queries[0], Message21Query)
        assert isinstance(queries[1], Message31Query)

    def test_set_attribute_and_customize(self) -> None:
        """Test set attribute and set customize are no-op."""
        self.device.set_attribute(DeviceAttributes.night_mode.value, True)
        self.device.set_customize("customize")

    def test_notify_response_sensors(self) -> None:
        """Test notify1 response with sensor values."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.AD] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.notify1])
        body = bytearray(18)
        body[0] = 0x11  # body type
        body[1] = 0x01  # sensor report
        body[3] = 0x08  # temperature high byte
        body[4] = 0x34  # temperature low byte -> 21.0
        body[5] = 0x11  # humidity high byte
        body[6] = 0x94  # humidity low byte -> 45.0
        body[7] = 0x00  # tvoc high byte
        body[8] = 0x64  # tvoc low byte -> 100
        body[9] = 0x00  # pm25 high byte
        body[10] = 0x0A  # pm25 low byte -> 10
        body[11] = 0x01  # co2 high byte
        body[12] = 0x90  # co2 low byte -> 400
        body[13] = 0x00  # hcho high byte
        body[14] = 0x0A  # hcho low byte -> 100.0
        body[16] = 0x03  # arofene_link + radar_exist
        result = self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.temperature] == 21.0
        assert self.device.attributes[DeviceAttributes.humidity] == 45.0
        assert self.device.attributes[DeviceAttributes.tvoc] == 100
        assert self.device.attributes[DeviceAttributes.pm25] == 10
        assert self.device.attributes[DeviceAttributes.co2] == 400
        assert self.device.attributes[DeviceAttributes.hcho] == 100.0
        assert self.device.attributes[DeviceAttributes.arofene_link] is True
        assert self.device.attributes[DeviceAttributes.radar_exist] is True
        assert result[DeviceAttributes.temperature.value] == 21.0

    def test_notify_response_sensors_negative_and_none(self) -> None:
        """Test notify1 response with negative temperature and missing sensors."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.AD] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.notify1])
        body = bytearray(18)
        body[0] = 0x11  # body type
        body[1] = 0x01  # sensor report
        body[3] = 0xFF  # temperature high byte (negative)
        body[4] = 0x9C  # temperature low byte -> -1.0
        body[5] = 0xFF  # humidity invalid
        body[7] = 0xFF  # tvoc invalid
        body[9] = 0xFF  # pm25 invalid
        body[11] = 0xFF  # co2 invalid
        body[13] = 0xFF  # hcho invalid
        body[16] = 0xFF  # arofene_link/radar_exist invalid
        self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.temperature] == -1.0
        assert self.device.attributes[DeviceAttributes.humidity] is None
        assert self.device.attributes[DeviceAttributes.tvoc] is None
        assert self.device.attributes[DeviceAttributes.pm25] is None
        assert self.device.attributes[DeviceAttributes.co2] is None
        assert self.device.attributes[DeviceAttributes.hcho] is None
        assert self.device.attributes[DeviceAttributes.arofene_link] is None
        assert self.device.attributes[DeviceAttributes.radar_exist] is None

    @pytest.mark.parametrize(
        ("function_byte", "value_byte", "attribute", "expected"),
        [
            (0x01, 0x01, DeviceAttributes.presets_function, True),
            (0x01, 0x00, DeviceAttributes.presets_function, False),
            (0x02, 0x01, DeviceAttributes.fall_asleep_status, True),
            (0x02, 0x00, DeviceAttributes.fall_asleep_status, False),
        ],
    )
    def test_notify_response_functions(
        self,
        function_byte: int,
        value_byte: int,
        attribute: DeviceAttributes,
        expected: bool,
    ) -> None:
        """Test notify1 response with function status."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.AD] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.notify1])
        body = bytearray(18)
        body[0] = 0x11  # body type
        body[1] = 0x04  # function report
        body[3] = function_byte
        body[4] = value_byte
        result = self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[attribute] is expected
        assert result == {attribute.value: expected}

    @pytest.mark.parametrize(
        ("timeout_byte", "expected_timeout"),
        [(30, 30), (0xFF, None)],
    )
    def test_x21_query_response(
        self,
        timeout_byte: int,
        expected_timeout: int | None,
    ) -> None:
        """Test X21 query response."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.AD] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.query])
        body = bytearray(6)
        body[0] = 0x21  # body type
        body[2] = 0x01  # portable_sense
        body[3] = 0x00  # night_mode
        body[4] = timeout_byte
        self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.portable_sense] is True
        assert self.device.attributes[DeviceAttributes.night_mode] is False
        assert (
            self.device.attributes[DeviceAttributes.screen_extinction_timeout]
            == expected_timeout
        )

    def test_x31_query_response(self) -> None:
        """Test X31 query response with values."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.AD] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.query])
        body = bytearray(16)
        body[0] = 0x31  # body type
        body[1] = 0x0E  # payload length > 0x0D, compensate available
        body[2] = 0x01  # screen_status
        body[3] = 0x00  # led_status
        body[4] = 0x01  # arofene_link
        body[5] = 0x01  # header_exist
        body[6] = 0x00  # radar_exist
        body[7] = 0x01  # header_led_status
        body[8] = 0x08  # temperature_raw high byte
        body[9] = 0x34  # temperature_raw low byte -> 2100
        body[10] = 0x11  # humidity_raw high byte
        body[11] = 0x94  # humidity_raw low byte -> 4500
        body[12] = 0x00  # temperature_compensate high byte
        body[13] = 0x05  # temperature_compensate low byte -> 5
        body[14] = 0x00  # humidity_compensate high byte
        body[15] = 0x06  # humidity_compensate low byte -> 6
        self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.screen_status] is True
        assert self.device.attributes[DeviceAttributes.led_status] is False
        assert self.device.attributes[DeviceAttributes.arofene_link] is True
        assert self.device.attributes[DeviceAttributes.header_exist] is True
        assert self.device.attributes[DeviceAttributes.radar_exist] is False
        assert self.device.attributes[DeviceAttributes.header_led_status] is True
        assert self.device.attributes[DeviceAttributes.temperature_raw] == 2100
        assert self.device.attributes[DeviceAttributes.humidity_raw] == 4500
        assert self.device.attributes[DeviceAttributes.temperature_compensate] == 5
        assert self.device.attributes[DeviceAttributes.humidity_compensate] == 6

    def test_x31_query_response_invalid_values(self) -> None:
        """Test X31 query response with invalid values."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.AD] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.query])
        body = bytearray(16)
        body[0] = 0x31  # body type
        body[1] = 0x01  # payload length <= 0x0D, no compensate
        body[2] = 0xFF  # screen_status invalid
        body[3] = 0xFF  # led_status invalid
        body[4] = 0xFF  # arofene_link invalid
        body[5] = 0xFF  # header_exist invalid
        body[6] = 0xFF  # radar_exist invalid
        body[7] = 0xFF  # header_led_status invalid
        body[8] = 0xFF  # temperature_raw invalid
        body[10] = 0xFF  # humidity_raw invalid
        self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.screen_status] is None
        assert self.device.attributes[DeviceAttributes.led_status] is None
        assert self.device.attributes[DeviceAttributes.arofene_link] is None
        assert self.device.attributes[DeviceAttributes.header_exist] is None
        assert self.device.attributes[DeviceAttributes.radar_exist] is None
        assert self.device.attributes[DeviceAttributes.header_led_status] is None
        assert self.device.attributes[DeviceAttributes.temperature_raw] is None
        assert self.device.attributes[DeviceAttributes.humidity_raw] is None
        assert self.device.attributes[DeviceAttributes.temperature_compensate] is None
        assert self.device.attributes[DeviceAttributes.humidity_compensate] is None

    def test_unexpected_response(self) -> None:
        """Test unexpected response body type updates nothing."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.AD] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.query])
        body = bytearray(16)
        body[0] = 0x99  # unknown body type
        result = self.device.process_message(bytes(header + body + bytearray(1)))
        assert result == {}
