"""Test B6 Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.const.fan_exceptions import B6_EXCEPTIONS, FanExceptions
from midealocal.devices.b6 import DeviceAttributes, MideaB6Device
from midealocal.devices.b6.message import MessageQuery
from midealocal.message import MessageType


def _build_message(
    protocol_version: int,
    message_type: MessageType,
    body: bytearray,
) -> bytes:
    """Build a full B6 response message."""
    header = bytearray(
        [0xAA] + ([0x0] * 7) + [protocol_version] + [message_type],
    )
    return bytes(header + body + bytearray([0x00]))


class TestMideaB6Device:
    """Test Midea B6 Device."""

    device: MideaB6Device

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea B6 Device setup."""
        self.device = self._make_device()

    def _make_device(self) -> MideaB6Device:
        """Create a device for the test model."""
        return MideaB6Device(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.1",
            port=12345,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model="test_model",
            subtype=1,
        )

    def test_initial_attributes(self) -> None:
        """Test initial attributes."""
        assert self.device.attributes[DeviceAttributes.power] is False
        assert self.device.attributes[DeviceAttributes.light] is None
        assert self.device.attributes[DeviceAttributes.mode] is None
        assert self.device.attributes[DeviceAttributes.fan_level] == 0
        assert self.device.attributes[DeviceAttributes.fan_speed] == 0
        assert self.device.attributes[DeviceAttributes.oilcup_full] is False
        assert self.device.attributes[DeviceAttributes.cleaning_reminder] is False
        assert self.device.speed_count == 2
        assert self.device.preset_modes == ["off", "low", "high"]

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    def test_process_message_general(self) -> None:
        """Test process message with a general body and a known fan level."""
        body = bytearray([0x11, 0x01, 0x02, 0x02, 0x00, 0x03])
        new_status = self.device.process_message(
            _build_message(0x01, MessageType.query, body),
        )
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.light] is True
        assert self.device.attributes[DeviceAttributes.mode] == "high"
        assert self.device.attributes[DeviceAttributes.fan_level] == 2
        assert self.device.attributes[DeviceAttributes.fan_speed] == 2
        assert self.device.attributes[DeviceAttributes.oilcup_full] is True
        assert self.device.attributes[DeviceAttributes.cleaning_reminder] is True
        assert new_status[DeviceAttributes.mode.value] == "high"
        assert new_status[DeviceAttributes.fan_speed.value] == 2

    def test_process_message_unknown_fan_level(self) -> None:
        """Test process message with a fan level not in the speeds map."""
        body = bytearray([0x11, 0x01, 0x14, 0x05, 0x00, 0x00])
        new_status = self.device.process_message(
            _build_message(0x01, MessageType.query, body),
        )
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.mode] is None
        assert self.device.attributes[DeviceAttributes.fan_level] == 0x16
        assert self.device.attributes[DeviceAttributes.fan_speed] == 0
        assert new_status[DeviceAttributes.mode.value] is None

    def test_process_message_new_protocol(self) -> None:
        """Test process message with a new protocol body."""
        pack = bytearray(19)
        pack[1] = 0x02
        pack[2] = 0x01
        pack[6] = 0x01
        pack[18] = 0x02
        body = bytearray([0x11, 0x01, 0x13]) + pack
        self.device.process_message(_build_message(0x02, MessageType.notify1, body))
        assert self.device._message_protocol_version == 0x02
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.light] is True
        assert self.device.attributes[DeviceAttributes.mode] == "low"
        assert self.device.attributes[DeviceAttributes.fan_speed] == 1
        assert self.device.attributes[DeviceAttributes.oilcup_full] is True
        assert self.device.attributes[DeviceAttributes.cleaning_reminder] is False

    def test_unexpected_response(self) -> None:
        """Test unexpected response."""
        body = bytearray([0x11, 0x01, 0x00])
        new_status = self.device.process_message(
            _build_message(0x01, MessageType.notify2, body),
        )
        assert new_status == {}

    def test_set_attribute(self) -> None:
        """Test set attribute."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.fan_speed.value, 1)
            mock_build_send.assert_called_once()
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.fan_speed.value, 5)
            mock_build_send.assert_not_called()

            self.device.set_attribute(DeviceAttributes.mode.value, "low")
            mock_build_send.assert_called_once()
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.mode.value, "")
            mock_build_send.assert_called_once()
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.mode.value, "invalid")
            mock_build_send.assert_not_called()

            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_build_send.assert_called_once()
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.light.value, 1)
            mock_build_send.assert_called_once()
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.oilcup_full.value, True)
            mock_build_send.assert_not_called()

    def test_turn_on(self) -> None:
        """Test turn on."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.turn_on()
            mock_build_send.assert_called_once()
            mock_build_send.reset_mock()

            self.device.turn_on(fan_speed=1)
            mock_build_send.assert_called_once()
            mock_build_send.reset_mock()

            self.device.turn_on(fan_speed=10)
            mock_build_send.assert_called_once()

    def test_turn_on_with_mode(self) -> None:
        """Test turn on with a mode name applies the matching fan level."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.turn_on(mode="low")
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].fan_level == 1
            mock_build_send.reset_mock()

            self.device.turn_on(mode="invalid")
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].fan_level == self.device._power_speed

    @pytest.mark.parametrize(
        ("exceptions", "expected_modes", "expected_power_speed"),
        [
            pytest.param({}, ["off", "low", "high"], 2, id="default"),
            pytest.param(
                {
                    "test_model": {
                        "default_speed": 1,
                        "speeds": {0: "off", 1: "low", 2: "mid", 3: "high"},
                    },
                },
                ["off", "low", "mid", "high"],
                1,
                id="model_exception",
            ),
        ],
    )
    def test_speeds_exception(
        self,
        exceptions: dict[str, FanExceptions],
        expected_modes: list[str],
        expected_power_speed: int,
    ) -> None:
        """Test per-model speeds and default speed exceptions."""
        with patch.dict(B6_EXCEPTIONS, exceptions):
            device = self._make_device()

        assert device.speed_count == len(expected_modes) - 1
        assert device.preset_modes == expected_modes
        assert device._power_speed == expected_power_speed
