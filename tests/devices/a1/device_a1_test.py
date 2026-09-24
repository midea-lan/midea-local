"""Test a1 Device."""

from unittest.mock import patch

import pytest

from midealan.const import ProtocolVersion
from midealan.devices.a1 import DeviceAttributes, MideaA1Device
from midealan.devices.a1.message import MessageQuery, MessageSet


class TestMideaA1Device:
    """Test Midea A1 Device."""

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea A1 Device setup."""
        self.device = MideaA1Device(
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
        assert self.device.attributes[DeviceAttributes.prompt_tone]
        assert self.device.attributes[DeviceAttributes.fan_speed] == "medium"
        assert self.device.attributes[DeviceAttributes.target_humidity] == 35
        assert not self.device.attributes[DeviceAttributes.pump]

    def test_modes(self) -> None:
        """Test modes."""
        assert self.device.modes == [
            "manual",
            "continuous",
            "auto",
            "clothes-dry",
            "shoes-dry",
        ]

    def test_fan_speeds(self) -> None:
        """Test fan speeds."""
        assert self.device.fan_speeds == [
            "lowest",
            "low",
            "medium",
            "high",
            "auto",
            "off",
        ]

    def test_water_level_sets(self) -> None:
        """Test water level sets."""
        assert self.device.water_level_sets == ["25", "50", "75", "100"]

    def test_process_message(self) -> None:
        """Test process message."""
        with patch("midealan.devices.a1.MessageA1Response") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.protocol_version = ProtocolVersion.V3
            mock_message.power = True
            mock_message.prompt_tone = False
            mock_message.fan_speed = 40
            mock_message.target_humidity = 40
            mock_message.mode = 1
            mock_message.pump = True
            mock_message.tank = 60
            mock_message.water_level_set = "50"
            mock_message.pump_enable = True
            new_status = self.device.process_message(b"")
            assert new_status[DeviceAttributes.power.value]
            assert not new_status[DeviceAttributes.prompt_tone.value]
            assert new_status[DeviceAttributes.fan_speed.value] == "low"
            assert new_status[DeviceAttributes.target_humidity.value] == 40
            assert new_status[DeviceAttributes.pump.value]
            assert new_status[DeviceAttributes.tank_full.value]
            assert new_status[DeviceAttributes.mode.value] == "manual"

            mock_message.mode = 10
            mock_message.fan_speed = 99
            mock_message.tank = 30
            new_status = self.device.process_message(b"")
            assert new_status[DeviceAttributes.mode.value] is None
            assert new_status[DeviceAttributes.fan_speed.value] is None
            assert not new_status[DeviceAttributes.tank_full.value]

        with patch("midealan.devices.a1.MessageA1Response") as mock_message_response2:
            mock_message = mock_message_response2.return_value
            mock_message.protocol_version = ProtocolVersion.V3
            mock_message.power = True
            mock_message.prompt_tone = False
            mock_message.fan_speed = 80
            mock_message.target_humidity = 50
            mock_message.mode = 3
            mock_message.pump = True
            mock_message.tank = 60
            mock_message.water_level_set = "50"
            mock_message.pump_enable = False
            new_status = self.device.process_message(b"")
            assert new_status[DeviceAttributes.power.value]
            assert not new_status[DeviceAttributes.prompt_tone.value]
            assert new_status[DeviceAttributes.fan_speed.value] == "high"
            assert new_status[DeviceAttributes.target_humidity.value] == 50
            assert new_status[DeviceAttributes.pump.value]
            assert new_status[DeviceAttributes.tank_full.value]
            assert new_status[DeviceAttributes.mode.value] == "auto"

            mock_message.mode = 1
            mock_message.fan_speed = 102
            mock_message.tank = 100
            new_status = self.device.process_message(b"")
            assert new_status[DeviceAttributes.mode.value] == "manual"
            assert new_status[DeviceAttributes.fan_speed.value] == "auto"
            assert new_status[DeviceAttributes.tank_full.value]
            assert not self.device.make_message_set().pump_enable

    def test_process_message_without_pump_enable(self) -> None:
        """Test process message without a pump_enable attribute."""
        with patch("midealan.devices.a1.MessageA1Response") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.protocol_version = ProtocolVersion.V3
            mock_message.power = True
            mock_message.prompt_tone = True
            mock_message.fan_speed = 40
            mock_message.target_humidity = 40
            mock_message.mode = 1
            mock_message.pump = True
            mock_message.tank = 60
            mock_message.water_level_set = "50"
            mock_message.pump_enable = True
            self.device.process_message(b"")

        response = bytearray(15)
        response[0] = 0xB0
        response[1] = 0x01
        response[2] = 0x34
        response[3] = 0x12
        response[5] = 0x01
        response[6] = 0x01
        header = bytearray(
            [
                0xAA,
                0x00,
                0xA1,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x01,
                0x03,
            ],
        )
        new_status = self.device.process_message(bytes(header + response))
        assert new_status == {}
        assert self.device.make_message_set().pump_enable

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    def test_make_message_set(self) -> None:
        """Test make message set."""
        with patch("midealan.devices.a1.MessageA1Response") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.protocol_version = ProtocolVersion.V3
            mock_message.power = True
            mock_message.prompt_tone = False
            mock_message.fan_speed = 40
            mock_message.target_humidity = 40
            mock_message.mode = 1
            mock_message.pump = True
            mock_message.pump_enable = True
            mock_message.tank = 60
            mock_message.water_level_set = "50"
            self.device.process_message(b"")

        message_set = self.device.make_message_set()
        assert isinstance(message_set, MessageSet)
        assert message_set.power
        assert not message_set.prompt_tone
        assert message_set.fan_speed == 40
        assert message_set.mode == 1
        assert message_set.pump
        assert message_set.pump_enable

        self.device._attributes[DeviceAttributes.fan_speed] = "unknown"
        self.device._attributes[DeviceAttributes.mode] = "unknown"
        message_set = self.device.make_message_set()
        assert message_set.fan_speed == 40
        assert message_set.mode == 1

    def test_set_attribute(self) -> None:
        """Test set attribute."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.mode, "continuous")
            assert mock_build_send.call_args.args[0].mode == 2

            self.device.set_attribute(DeviceAttributes.mode, "auto")
            assert mock_build_send.call_args.args[0].mode == 3

            self.device.set_attribute(DeviceAttributes.fan_speed, "medium")
            assert mock_build_send.call_args.args[0].fan_speed == 60

            self.device.set_attribute(DeviceAttributes.fan_speed, "auto")
            assert mock_build_send.call_args.args[0].fan_speed == 102

            self.device.set_attribute(DeviceAttributes.water_level_set, "75")
            assert mock_build_send.call_args.args[0].water_level_set == 75

            self.device.set_attribute(DeviceAttributes.water_level_set, "25")
            assert mock_build_send.call_args.args[0].water_level_set == 25

            self.device.set_attribute(DeviceAttributes.prompt_tone, True)
            assert mock_build_send.call_count == 6
            assert self.device.attributes[DeviceAttributes.prompt_tone] is True

            self.device.set_attribute(DeviceAttributes.swing, True)
            assert mock_build_send.call_args.args[0].swing is True

            self.device.set_attribute(DeviceAttributes.pump, True)
            assert mock_build_send.call_args.args[0].pump is True

    def test_set_attribute_ignores_invalid_values(self) -> None:
        """Test set attribute keeps defaults for invalid values."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.mode, "Invalid Mode")
            self.device.set_attribute(DeviceAttributes.fan_speed, "Turbo")
            self.device.set_attribute(DeviceAttributes.water_level_set, "10")

            assert mock_build_send.call_count == 3
            assert mock_build_send.call_args_list[0].args[0].mode == 1
            assert mock_build_send.call_args_list[1].args[0].fan_speed == 60
            assert mock_build_send.call_args_list[2].args[0].water_level_set == 50

    def test_set_customize(self) -> None:
        """Test set customize with valid speeds and modes."""
        with patch.object(self.device, "update_all") as mock_update_all:
            self.device.set_customize(
                '{"speeds": {"2": "New Low", "1": "New Lowest"},'
                ' "modes": {"2": "New Mode", "1": "New Manual"}}',
            )
            assert self.device._speeds == {1: "New Lowest", 2: "New Low"}
            assert self.device._modes == {1: "New Manual", 2: "New Mode"}
            mock_update_all.assert_called_once_with(
                {
                    "speeds": {1: "New Lowest", 2: "New Low"},
                    "modes": {1: "New Manual", 2: "New Mode"},
                },
            )

    def test_set_customize_prompt_tone(self) -> None:
        """Test set customize can override the prompt_tone default.

        prompt_tone is a write-only flag attached to every outgoing set command and
        is never reported back by the device, so the integration has no way to learn
        the real hardware state - it only holds this default in memory. Some users
        want the confirmation beep off by default instead of on, so it must be
        overridable per-device rather than changing the shared default for everyone.
        """
        with patch.object(self.device, "update_all") as mock_update_all:
            customize = '{"prompt_tone": false}'
            self.device.set_customize(customize)
            assert self.device.attributes[DeviceAttributes.prompt_tone] is False
            assert self.device.make_message_set().prompt_tone is False
            mock_update_all.assert_called_once_with({"prompt_tone": False})

        with patch.object(self.device, "update_all") as mock_update_all:
            customize = '{"prompt_tone": true}'
            self.device.set_customize(customize)
            assert self.device.attributes[DeviceAttributes.prompt_tone] is True
            assert self.device.make_message_set().prompt_tone is True
            mock_update_all.assert_called_once_with({"prompt_tone": True})

    def test_set_customize_prompt_tone_ignores_non_boolean(self) -> None:
        """Test set customize ignores a non-boolean prompt_tone instead of coercing it.

        JSON has no ambiguity about what a boolean is, so a malformed value (a
        string, a number, null) should be rejected rather than passed through
        Python's truthiness - bool("false") is True, which would silently invert
        a user's intent.
        """
        with patch.object(self.device, "update_all") as mock_update_all:
            customize = '{"prompt_tone": "false"}'
            self.device.set_customize(customize)
            assert self.device.attributes[DeviceAttributes.prompt_tone] is True
            mock_update_all.assert_not_called()

    def test_set_customize_ignores_empty_and_empty_object(self) -> None:
        """Test set customize ignores empty input and an empty JSON object."""
        with patch.object(self.device, "update_all") as mock_update_all:
            self.device.set_customize("")
            mock_update_all.assert_not_called()

        with patch.object(self.device, "update_all") as mock_update_all:
            self.device.set_customize("{}")
            mock_update_all.assert_not_called()
