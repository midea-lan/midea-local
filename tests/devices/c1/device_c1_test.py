"""Test C1 device."""

from unittest.mock import patch

import pytest

from midealan.const import ProtocolVersion
from midealan.devices.c1 import DeviceAttributes, MideaC1Device
from midealan.exceptions import ValueWrongType
from midealan.message import MessageBase, MessageType


class TestMideaC1Device:
    """Test Midea C1 device."""

    @pytest.fixture
    def device_v3(self) -> MideaC1Device:
        """C1 device on V3 transport."""
        return MideaC1Device(
            name="c1",
            device_id=1,
            ip_address="192.168.1.1",
            port=6444,
            token="00" * 32,
            key="00" * 32,
            device_protocol=ProtocolVersion.V3,
            model="2760001Z",
            subtype=0,
            customize="",
        )

    def test_heating_modes(self, device_v3: MideaC1Device) -> None:
        """Heating mode names match Lua codes (for HA / midea_ac_lan)."""
        assert device_v3.heating_modes == ["user", "activity", "sleep"]

    def test_set_customize_temperature_step_and_refresh(
        self,
        device_v3: MideaC1Device,
    ) -> None:
        """JSON customize rejects unsupported precision and applies refresh interval."""
        device_v3.set_customize(
            '{"temperature_step": 0.5, "refresh_interval": 45}',
        )
        assert device_v3.temperature_step == 1.0
        assert device_v3._refresh_interval == 45

    def test_set_customize_invalid_json(self, device_v3: MideaC1Device) -> None:
        """Invalid customize JSON is logged; device keeps defaults."""
        device_v3.set_customize("{")
        assert device_v3.temperature_step == 1.0

    def test_process_message_syncs_protocol_version(
        self,
        device_v3: MideaC1Device,
    ) -> None:
        """Incoming frames update _message_protocol_version like other devices."""
        device_v3._message_protocol_version = 0
        body = bytearray(30)
        body[0] = 0x01
        body[2] = 0x01
        header = bytearray(
            [
                0xAA,
                0x00,
                0xC1,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                int(ProtocolVersion.V3),
                int(MessageType.query),
            ],
        )
        frame = header + body
        full = frame + bytes([MessageBase.checksum(frame)])
        device_v3.process_message(bytes(full))
        assert device_v3._message_protocol_version == int(ProtocolVersion.V3)

    def test_process_message_derives_status_running(
        self,
        device_v3: MideaC1Device,
    ) -> None:
        """Status is running when power and heating are on."""
        body = bytearray(30)
        body[0] = 0x01
        body[2] = 0x05  # power + heating
        header = bytearray(
            [
                0xAA,
                0x00,
                0xC1,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                int(ProtocolVersion.V3),
                int(MessageType.query),
            ],
        )
        frame = header + body
        full = frame + bytes([MessageBase.checksum(frame)])
        device_v3.process_message(bytes(full))
        assert device_v3._attributes[DeviceAttributes.status] == "running"

    def test_set_attribute_heating_mode(
        self,
        device_v3: MideaC1Device,
    ) -> None:
        """set_attribute(heating_mode) sends heating segment with current target."""
        device_v3._message_protocol_version = ProtocolVersion.V3
        device_v3._attributes[DeviceAttributes.heating_target_temperature] = 50.0
        with patch.object(device_v3, "build_send") as mock_send:
            device_v3.set_attribute(DeviceAttributes.heating_mode, "sleep")
            mock_send.assert_called_once()
            sent = mock_send.call_args[0][0]
            assert sent.heating_mode == 3
            assert sent.target_temperature == 50.0

    def test_set_attribute_power(
        self,
        device_v3: MideaC1Device,
    ) -> None:
        """set_attribute(power) sends MessagePower."""
        device_v3._message_protocol_version = ProtocolVersion.V3
        with patch.object(device_v3, "build_send") as mock_send:
            device_v3.set_attribute(DeviceAttributes.power, True)
            mock_send.assert_called_once()
            sent = mock_send.call_args[0][0]
            assert sent.power is True

    def test_set_attribute_power_rejects_non_bool(
        self,
        device_v3: MideaC1Device,
    ) -> None:
        """Non-bool power must not send; bool('off') would otherwise turn on."""
        device_v3._message_protocol_version = ProtocolVersion.V3
        with (
            patch.object(device_v3, "build_send") as mock_send,
            pytest.raises(ValueWrongType),
        ):
            device_v3.set_attribute(DeviceAttributes.power, "off")
        mock_send.assert_not_called()
