"""Test da Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.da import DeviceAttributes, MideaDADevice
from midealocal.devices.da.message import MessageQuery
from midealocal.exceptions import ValueWrongType


class TestMideaDADevice:
    """Test Midea DA Device."""

    device: MideaDADevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea DA Device setup."""
        self.device = MideaDADevice(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.100",
            port=6444,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="test_model",
            subtype=1,
            customize="test_customize",
        )

    def test_initial_attributes(self) -> None:
        """Test initial attributes."""
        assert not self.device.attributes[DeviceAttributes.power]
        assert not self.device.attributes[DeviceAttributes.start]
        assert self.device.attributes[DeviceAttributes.error_code] is None
        assert self.device.attributes[DeviceAttributes.program] is None
        assert self.device.attributes[DeviceAttributes.progress] == "unknown"
        assert self.device.attributes[DeviceAttributes.time_remaining] is None
        assert self.device.attributes[DeviceAttributes.wash_time] is None
        assert self.device.attributes[DeviceAttributes.soak_time] is None
        assert self.device.attributes[DeviceAttributes.dehydration_time] is None
        assert self.device.attributes[DeviceAttributes.dehydration_speed] is None
        assert self.device.attributes[DeviceAttributes.rinse_count] is None
        assert self.device.attributes[DeviceAttributes.rinse_level] is None
        assert self.device.attributes[DeviceAttributes.wash_level] is None
        assert self.device.attributes[DeviceAttributes.wash_strength] is None
        assert self.device.attributes[DeviceAttributes.softener] is None
        assert self.device.attributes[DeviceAttributes.detergent] is None

    def test_process_message(self) -> None:
        """Test process message."""
        with patch("midealocal.devices.da.MessageDAResponse") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.protocol_version = ProtocolVersion.V3
            mock_message.power = True
            mock_message.start = True
            mock_message.error_code = 10
            mock_message.program = 5
            mock_message.wash_time = 30
            mock_message.soak_time = 10
            mock_message.dehydration_time = 2
            mock_message.dehydration_speed = 3
            mock_message.rinse_count = 3
            mock_message.rinse_level = 4
            mock_message.wash_level = 1
            mock_message.wash_strength = 2
            mock_message.softener = 5
            mock_message.detergent = 4
            mock_message.progress = 2
            mock_message.time_remaining = 15 + 60
            new_status = self.device.process_message(b"")
            assert new_status[DeviceAttributes.power.value]
            assert new_status[DeviceAttributes.start.value]
            assert new_status[DeviceAttributes.error_code.value] == 10
            assert new_status[DeviceAttributes.program.value] == "memory"
            assert new_status[DeviceAttributes.progress.value] == "rinse"
            assert new_status[DeviceAttributes.time_remaining.value] == 75
            assert new_status[DeviceAttributes.wash_time.value] == 30
            assert new_status[DeviceAttributes.soak_time.value] == 10
            assert new_status[DeviceAttributes.dehydration_time.value] == 2
            assert new_status[DeviceAttributes.dehydration_speed.value] == "high"
            assert new_status[DeviceAttributes.rinse_count.value] == 3
            assert new_status[DeviceAttributes.rinse_level.value] == 4
            assert new_status[DeviceAttributes.wash_level.value] == 1
            assert new_status[DeviceAttributes.wash_strength.value] == "medium"
            assert new_status[DeviceAttributes.softener.value] == "5"
            assert new_status[DeviceAttributes.detergent.value] == "4"

            mock_message.progress = 15
            mock_message.program = 15
            mock_message.rinse_level = 15
            mock_message.dehydration_speed = 15
            mock_message.detergent = 15
            mock_message.softener = 15
            mock_message.wash_strength = 15
            new_status = self.device.process_message(b"")
            assert new_status[DeviceAttributes.program.value] is None
            assert new_status[DeviceAttributes.progress.value] is None
            assert new_status[DeviceAttributes.rinse_level.value] == "none"
            assert new_status[DeviceAttributes.dehydration_speed.value] is None
            assert new_status[DeviceAttributes.softener.value] is None
            assert new_status[DeviceAttributes.detergent.value] is None
            assert new_status[DeviceAttributes.wash_strength.value] is None

            mock_message.dehydration_speed = 0
            mock_message.wash_strength = 0
            mock_message.detergent = 1
            mock_message.softener = 1
            new_status = self.device.process_message(b"")
            assert new_status[DeviceAttributes.dehydration_speed.value] == "none"
            assert new_status[DeviceAttributes.wash_strength.value] == "none"
            assert new_status[DeviceAttributes.detergent.value] == "less"
            assert new_status[DeviceAttributes.softener.value] == "intelligent"

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    @pytest.mark.parametrize(
        ("attributes", "expected_washing_data"),
        [
            ({}, bytearray([0xFF] * 12)),
            (
                {
                    DeviceAttributes.program: "standard",
                    DeviceAttributes.rinse_level: 1,
                    DeviceAttributes.wash_level: 2,
                    DeviceAttributes.dehydration_speed: "medium",
                    DeviceAttributes.wash_strength: "weak",
                    DeviceAttributes.softener: "intelligent",
                    DeviceAttributes.detergent: "medium",
                    DeviceAttributes.wash_time: 30,
                    DeviceAttributes.dehydration_time: 10,
                    DeviceAttributes.rinse_count: 3,
                    DeviceAttributes.soak_time: 5,
                },
                bytearray(
                    [
                        0xFF,
                        0x00,
                        0x12,
                        0x21,
                        0xFF,
                        0x12,
                        30,
                        0xA3,
                        0xFF,
                        0x05,
                        0xFF,
                        0xFF,
                    ],
                ),
            ),
            (
                {
                    DeviceAttributes.program: "child",
                    DeviceAttributes.rinse_level: None,
                    DeviceAttributes.wash_level: 5,
                    DeviceAttributes.dehydration_speed: "none",
                    DeviceAttributes.wash_strength: None,
                    DeviceAttributes.softener: None,
                    DeviceAttributes.detergent: "less",
                    DeviceAttributes.wash_time: 50,
                    DeviceAttributes.dehydration_time: None,
                    DeviceAttributes.rinse_count: 5,
                    DeviceAttributes.soak_time: 10,
                },
                bytearray(
                    [
                        0xFF,
                        0x06,
                        0xF5,
                        0x0F,
                        0xFF,
                        0xF1,
                        50,
                        0xF5,
                        0xFF,
                        10,
                        0xFF,
                        0xFF,
                    ],
                ),
            ),
            (
                {
                    DeviceAttributes.program: "child",
                    DeviceAttributes.rinse_level: "none",
                    DeviceAttributes.wash_level: None,
                    DeviceAttributes.dehydration_speed: None,
                    DeviceAttributes.wash_strength: "unknown",
                    DeviceAttributes.softener: None,
                    DeviceAttributes.detergent: "unknown",
                    DeviceAttributes.wash_time: 25,
                    DeviceAttributes.dehydration_time: 7,
                    DeviceAttributes.rinse_count: None,
                    DeviceAttributes.soak_time: 40,
                },
                bytearray(
                    [
                        0xFF,
                        0x06,
                        0xFF,
                        0xFF,
                        0xFF,
                        0xFF,
                        25,
                        0x7F,
                        0xFF,
                        40,
                        0xFF,
                        0xFF,
                    ],
                ),
            ),
        ],
    )
    def test_build_washing_data_mode(
        self,
        attributes: dict[str, str | int | None],
        expected_washing_data: bytearray,
    ) -> None:
        """Build washing data from the mode name, defaulting unmapped modes."""
        for attr, value in attributes.items():
            self.device._attributes[attr] = value

        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.start, True)
            sent_message = mock_build_send.call_args.args[0]
            assert (
                sent_message.body[1:] == bytearray([0xFF, 0x01]) + expected_washing_data
            )

            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.start, False)
            sent_message = mock_build_send.call_args.args[0]
            assert sent_message.body[1:] == bytearray([0xFF, 0x00])

    def test_set_attribute(self) -> None:
        """Test set attribute."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.power, True)
            mock_build_send.assert_called_once()

            self.device.set_attribute(DeviceAttributes.start, True)
            mock_build_send.assert_called()

            with pytest.raises(ValueWrongType):
                self.device.set_attribute(DeviceAttributes.start, "On")
