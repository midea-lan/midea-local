"""Test CA Device."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.ca import DeviceAttributes, MideaCADevice
from midealocal.devices.ca.message import MessageQuery
from midealocal.message import MessageType


def _build_message(message_type: MessageType, body: bytearray) -> bytes:
    """Build a full CA response message."""
    header = bytearray(
        [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
    )
    return bytes(header + body + bytearray([0x00]))


def _general_body(length: int) -> bytearray:
    """Build a CA general body with representative values."""
    body = bytearray(length)
    body[0] = 0x00
    body[2] = 0x35  # refrigerator 5, freezer -15
    body[3] = 5  # flex zone -14
    body[4] = 50  # right flex zone -20
    body[5] = 0x01  # variable mode soft_freezing
    body[12] = 0x10
    body[13] = 0x01  # energy consumption 272
    body[17] = 110  # refrigerator actual 5.0
    body[18] = 90  # freezer actual -5.0
    body[19] = 100  # flex actual 0.0
    body[20] = 120  # right flex actual 10.0
    return body


class TestMideaCADevice:
    """Test Midea CA Device."""

    device: MideaCADevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea CA Device setup."""
        self.device = MideaCADevice(
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
        assert self.device.attributes[DeviceAttributes.energy_consumption] is None
        assert self.device.attributes[DeviceAttributes.refrigerator_actual_temp] is None
        assert self.device.attributes[DeviceAttributes.freezer_actual_temp] is None
        assert self.device.attributes[DeviceAttributes.flex_zone_actual_temp] is None
        assert (
            self.device.attributes[DeviceAttributes.right_flex_zone_actual_temp] is None
        )
        assert (
            self.device.attributes[DeviceAttributes.refrigerator_setting_temp] is None
        )
        assert self.device.attributes[DeviceAttributes.freezer_setting_temp] is None
        assert self.device.attributes[DeviceAttributes.flex_zone_setting_temp] is None
        assert (
            self.device.attributes[DeviceAttributes.right_flex_zone_setting_temp]
            is None
        )
        assert (
            self.device.attributes[DeviceAttributes.refrigerator_door_overtime] is False
        )
        assert self.device.attributes[DeviceAttributes.freezer_door_overtime] is False
        assert self.device.attributes[DeviceAttributes.bar_door_overtime] is False
        assert self.device.attributes[DeviceAttributes.flex_zone_door_overtime] is False
        assert self.device.attributes[DeviceAttributes.refrigerator_door] is False
        assert self.device.attributes[DeviceAttributes.freezer_door] is False
        assert self.device.attributes[DeviceAttributes.bar_door] is False
        assert self.device.attributes[DeviceAttributes.flex_zone_door] is False
        assert self.device.attributes[DeviceAttributes.microcrystal_fresh] is False
        assert self.device.attributes[DeviceAttributes.electronic_smell] is False
        assert self.device.attributes[DeviceAttributes.humidity] is None
        assert self.device.attributes[DeviceAttributes.variable_mode] is None

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    def test_mode_options(self) -> None:
        """variable_mode_options de-duplicates the repeated mapping value."""
        options = MideaCADevice.mode_options()
        assert options == [
            "none",
            "soft_freezing",
            "zero_fresh",
            "cold_drink",
            "fresh_product",
            "partial_freezing",
            "dry_zone",
            "freeze_warm",
        ]
        assert len(options) == len(set(options))

    def test_process_message_general(self) -> None:
        """Test process message with a full general body."""
        body = _general_body(32)
        body[27] = 0x15  # microcrystal, electronic smell, humidity high
        new_status = self.device.process_message(
            _build_message(MessageType.query, body),
        )
        assert self.device.attributes[DeviceAttributes.energy_consumption] == 272
        assert self.device.attributes[DeviceAttributes.refrigerator_actual_temp] == 5.0
        assert self.device.attributes[DeviceAttributes.freezer_actual_temp] == -5.0
        assert self.device.attributes[DeviceAttributes.flex_zone_actual_temp] == 0.0
        assert (
            self.device.attributes[DeviceAttributes.right_flex_zone_actual_temp] == 10.0
        )
        assert self.device.attributes[DeviceAttributes.refrigerator_setting_temp] == 5
        assert self.device.attributes[DeviceAttributes.freezer_setting_temp] == -15
        assert self.device.attributes[DeviceAttributes.flex_zone_setting_temp] == -14
        assert (
            self.device.attributes[DeviceAttributes.right_flex_zone_setting_temp] == -20
        )
        assert self.device.attributes[DeviceAttributes.microcrystal_fresh] is True
        assert self.device.attributes[DeviceAttributes.electronic_smell] is True
        assert self.device.attributes[DeviceAttributes.humidity] == "high"
        assert self.device.attributes[DeviceAttributes.variable_mode] == "soft_freezing"
        assert new_status[DeviceAttributes.humidity.value] == "high"
        assert new_status[DeviceAttributes.variable_mode.value] == "soft_freezing"
        assert new_status[DeviceAttributes.energy_consumption.value] == 272

    def test_process_message_general_unknown_mappings(self) -> None:
        """Test process message with unmapped variable mode and humidity."""
        body = _general_body(32)
        body[5] = 0x20  # unmapped variable mode
        body[27] = 0x40  # unmapped humidity
        self.device.process_message(_build_message(MessageType.query, body))
        assert self.device.attributes[DeviceAttributes.humidity] is None
        assert self.device.attributes[DeviceAttributes.variable_mode] is None

    def test_process_message_notify00(self) -> None:
        """Test process message with a notify00 body."""
        body = bytearray([0x00, 0x17])
        new_status = self.device.process_message(
            _build_message(MessageType.notify1, body),
        )
        assert self.device.attributes[DeviceAttributes.refrigerator_door] is True
        assert self.device.attributes[DeviceAttributes.freezer_door] is True
        assert self.device.attributes[DeviceAttributes.bar_door] is True
        assert self.device.attributes[DeviceAttributes.flex_zone_door] is True
        assert new_status[DeviceAttributes.refrigerator_door.value] is True

    def test_process_message_exception(self) -> None:
        """Test process message with an exception body."""
        body = bytearray([0x01, 0x0F, 0x00, 0x00])
        self.device.process_message(_build_message(MessageType.exception, body))
        assert (
            self.device.attributes[DeviceAttributes.refrigerator_door_overtime] is True
        )
        assert self.device.attributes[DeviceAttributes.freezer_door_overtime] is True
        assert self.device.attributes[DeviceAttributes.bar_door_overtime] is True
        assert self.device.attributes[DeviceAttributes.flex_zone_door_overtime] is True

    def test_process_message_unhandled(self) -> None:
        """Test process message with an unhandled message type."""
        body = bytearray(25)
        new_status = self.device.process_message(
            _build_message(MessageType.notify2, body),
        )
        assert new_status == {}

    def test_set_attribute(self) -> None:
        """Test set attribute is a no-op."""
        self.device.set_attribute(DeviceAttributes.microcrystal_fresh.value, True)
        assert self.device.attributes[DeviceAttributes.microcrystal_fresh] is False
