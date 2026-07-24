"""Test E3 Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.e3 import DeviceAttributes, MideaE3Device
from midealocal.devices.e3.message import (
    MessageNewProtocolSet,
    MessagePower,
    MessageQuery,
    MessageSet,
)
from midealocal.message import MessageType


class TestMideaE3Device:
    """Test Midea E3 Device."""

    device: MideaE3Device

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea E3 Device setup."""
        self.device = MideaE3Device(
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

    def _old_subtype_device(self) -> MideaE3Device:
        """Midea E3 Device with an old protocol subtype."""
        return MideaE3Device(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.1",
            port=12345,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model="test_model",
            subtype=32,
            customize="",
        )

    def test_initial_attributes(self) -> None:
        """Test initial attributes."""
        assert self.device.attributes[DeviceAttributes.power] is False
        assert self.device.attributes[DeviceAttributes.burning_state] is False
        assert self.device.attributes[DeviceAttributes.zero_cold_water] is False
        assert self.device.attributes[DeviceAttributes.protection] is False
        assert self.device.attributes[DeviceAttributes.zero_cold_pulse] is False
        assert self.device.attributes[DeviceAttributes.smart_volume] is False
        assert self.device.attributes[DeviceAttributes.current_temperature] is None
        assert self.device.attributes[DeviceAttributes.target_temperature] == 40.0
        assert self.device.precision_halves is False
        assert self.device.temperature_step == 1.0

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    @pytest.mark.parametrize(
        ("message_type", "body_type"),
        [
            (MessageType.query, 0x01),
            (MessageType.set, 0x01),
            (MessageType.set, 0x02),
            (MessageType.set, 0x04),
            (MessageType.set, 0x14),
            (MessageType.notify1, 0x00),
            (MessageType.notify1, 0x01),
        ],
    )
    def test_process_message(
        self,
        message_type: MessageType,
        body_type: int,
    ) -> None:
        """Test process message updates all attributes."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
        )
        body = bytearray(21)
        body[0] = body_type
        body[2] = 0x07  # power, burning_state, zero_cold_water
        body[5] = 45  # current_temperature
        body[6] = 50  # target_temperature
        body[8] = 0x08  # protection
        body[20] = 0x03  # zero_cold_pulse, smart_volume
        crc = bytearray([0x00])
        new_status = self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.burning_state] is True
        assert self.device.attributes[DeviceAttributes.zero_cold_water] is True
        assert self.device.attributes[DeviceAttributes.protection] is True
        assert self.device.attributes[DeviceAttributes.zero_cold_pulse] is True
        assert self.device.attributes[DeviceAttributes.smart_volume] is True
        assert self.device.attributes[DeviceAttributes.current_temperature] == 45.0
        assert self.device.attributes[DeviceAttributes.target_temperature] == 50.0
        assert new_status[DeviceAttributes.power.value] is True

    def test_process_message_short_body(self) -> None:
        """Test process message with a short body skips optional fields."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.query],
        )
        body = bytearray(9)
        body[0] = 0x01
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.zero_cold_pulse] is False
        assert self.device.attributes[DeviceAttributes.smart_volume] is False

    def test_process_message_precision_halves(self) -> None:
        """Test process message halves temperatures when configured."""
        self.device.set_customize('{"precision_halves": true}')
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.query],
        )
        body = bytearray(21)
        body[0] = 0x01
        body[5] = 45  # current_temperature
        body[6] = 50  # target_temperature
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.current_temperature] == 22.5
        assert self.device.attributes[DeviceAttributes.target_temperature] == 25.0

    @pytest.mark.parametrize(
        ("message_type", "body_type"),
        [
            (MessageType.query, 0x02),
            (MessageType.notify1, 0x02),
            (MessageType.notify2, 0x01),
        ],
    )
    def test_process_message_unhandled(
        self,
        message_type: MessageType,
        body_type: int,
    ) -> None:
        """Test process message with an unhandled message updates nothing."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
        )
        body = bytearray(21)
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

    @pytest.mark.parametrize(
        ("attr", "value"),
        [
            (DeviceAttributes.zero_cold_water, True),
            (DeviceAttributes.zero_cold_pulse, True),
            (DeviceAttributes.smart_volume, True),
            (DeviceAttributes.target_temperature, 40.0),
        ],
    )
    def test_set_attribute_new_protocol(
        self,
        attr: DeviceAttributes,
        value: bool | float,
    ) -> None:
        """Test set attribute with a new protocol subtype."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(attr.value, value)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageNewProtocolSet)
            assert message.key == attr.value
            assert message.value == value

    def test_set_attribute_precision_halves(self) -> None:
        """Test set attribute doubles the target temperature when configured."""
        self.device.set_customize('{"precision_halves": true}')
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(
                DeviceAttributes.target_temperature.value,
                40.0,
            )
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageNewProtocolSet)
            assert message.value == 80.0

    @pytest.mark.parametrize(
        ("attr", "value"),
        [
            (DeviceAttributes.zero_cold_water, True),
            (DeviceAttributes.target_temperature, 45.0),
        ],
    )
    def test_set_attribute_old_subtype(
        self,
        attr: DeviceAttributes,
        value: bool | float,
    ) -> None:
        """Test set attribute with an old protocol subtype."""
        device = self._old_subtype_device()
        with patch.object(device, "build_send") as mock_build_send:
            device.set_attribute(attr.value, value)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert getattr(message, attr.value) == value

    @pytest.mark.parametrize(
        "attr",
        [
            DeviceAttributes.burning_state,
            DeviceAttributes.current_temperature,
            DeviceAttributes.protection,
        ],
    )
    def test_set_attribute_not_settable(self, attr: DeviceAttributes) -> None:
        """Test set attribute with a read-only attribute does not send."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(attr.value, True)
            mock_build_send.assert_not_called()

    def test_make_message_set(self) -> None:
        """Test make message set copies the current attributes."""
        self.device._attributes[DeviceAttributes.zero_cold_water] = True
        self.device._attributes[DeviceAttributes.protection] = True
        message = self.device.make_message_set()
        assert isinstance(message, MessageSet)
        assert message.zero_cold_water is True
        assert message.protection is True
        assert message.zero_cold_pulse is False
        assert message.smart_volume is False
        assert message.target_temperature == 40.0

    def test_set_customize(self) -> None:
        """Test set customize."""
        self.device.set_customize(
            '{"temperature_step": 0.5, "precision_halves": true}',
        )
        assert self.device.temperature_step == 0.5
        assert self.device.precision_halves is True

    def test_set_customize_invalid_json(self) -> None:
        """Test set customize with invalid JSON keeps defaults."""
        self.device.set_customize("{")
        assert self.device.temperature_step == 1.0
        assert self.device.precision_halves is False
