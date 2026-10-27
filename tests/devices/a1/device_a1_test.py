"""Test a1 Device."""

from typing import Any
from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.const.humidifier_exceptions import (
    A1_EXCEPTIONS,
    HumidifierExceptions,
)
from midealocal.devices.a1 import DeviceAttributes, MideaA1Device
from midealocal.devices.a1.message import MessageQuery, MessageSet


class TestMideaA1Device:
    """Test Midea A1 Device."""

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea A1 Device setup."""
        self.device = self._make_device()

    def _make_device(self) -> MideaA1Device:
        """Create a device for the test model."""
        return MideaA1Device(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.100",
            port=6444,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="test_model",
            subtype=1,
            customize="",
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
            "clothes_dry",
            "shoes_dry",
            "silent",
        ]

    def _process_mode(self, code: int) -> dict[str, Any]:
        """Process a status message reporting the given mode code."""
        with patch("midealocal.devices.a1.MessageA1Response") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.protocol_version = ProtocolVersion.V3
            mock_message.power = True
            mock_message.prompt_tone = False
            mock_message.fan_speed = 80
            mock_message.target_humidity = 50
            mock_message.pump = False
            mock_message.pump_enable = False
            mock_message.tank = 0
            mock_message.water_level_set = "50"
            mock_message.mode = code
            return self.device.process_message(b"")

    @pytest.mark.parametrize(
        ("code", "mode"),
        [
            (1, "manual"),
            (2, "continuous"),
            (3, "auto"),
            (4, "clothes_dry"),
            (5, "shoes_dry"),
            (10, "silent"),
            (11, "auto"),
        ],
    )
    def test_process_message_modes(self, code: int, mode: str) -> None:
        """Test every reported mode code is decoded."""
        new_status = self._process_mode(code)
        assert new_status[DeviceAttributes.mode.value] == mode

    @pytest.mark.parametrize(
        ("mode", "code"),
        [
            ("manual", 1),
            ("continuous", 2),
            ("auto", 3),
            ("clothes_dry", 4),
            ("shoes_dry", 5),
            ("silent", 10),
        ],
    )
    def test_set_attribute_modes(self, mode: str, code: int) -> None:
        """Test every mode is sent with its code, auto as 3."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.mode, mode)
            assert mock_build_send.call_args[0][0].mode == code

    def test_reported_auto_11_is_sent_as_3(self) -> None:
        """Test other commands send auto as 3 after the unit reported 11."""
        self._process_mode(11)
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.power, value=False)
            assert mock_build_send.call_args[0][0].mode == 3

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
        with patch("midealocal.devices.a1.MessageA1Response") as mock_message_response:
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
            assert self.device.capabilities == {"pump": True}

            capabilities = self.device.capabilities
            capabilities["pump"] = False
            assert self.device.capabilities == {"pump": True}

            mock_message.mode = 12
            mock_message.fan_speed = 99
            mock_message.pump_enable = False
            mock_message.tank = 30
            new_status = self.device.process_message(b"")
            assert new_status[DeviceAttributes.mode.value] is None
            assert new_status[DeviceAttributes.fan_speed.value] is None
            assert not new_status[DeviceAttributes.tank_full.value]
            assert self.device.capabilities == {"pump": False}

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    def test_make_message_set(self) -> None:
        """Test make message set."""
        with patch("midealocal.devices.a1.MessageA1Response") as mock_message_response:
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
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].mode == 2

            self.device.set_attribute(DeviceAttributes.fan_speed, "medium")
            mock_build_send.assert_called()
            assert mock_build_send.call_args[0][0].fan_speed == 60

            self.device.set_attribute(DeviceAttributes.water_level_set, "75")
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.prompt_tone, True)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.swing, True)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.pump, True)
            mock_build_send.assert_called()

    def test_reset_filter(self) -> None:
        """Test reset sends one pulse without changing cached attributes."""
        attributes = self.device.attributes.copy()
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.reset_filter()

        mock_build_send.assert_called_once()
        message = mock_build_send.call_args.args[0]
        assert message.filter_reset
        assert message._body[8] & 0x80
        assert self.device.attributes == attributes
        assert not self.device.make_message_set().filter_reset

    @pytest.mark.parametrize(
        ("exceptions", "expected_modes", "expected_speeds"),
        [
            pytest.param(
                {},
                ["manual", "continuous", "auto", "clothes_dry", "shoes_dry", "silent"],
                ["lowest", "low", "medium", "high", "auto", "off"],
                id="default",
            ),
            pytest.param(
                {
                    "test_model": {
                        "modes": {1: "New Manual", 2: "New Mode"},
                        "speeds": {1: "New Lowest", 2: "New Low"},
                    },
                },
                ["New Manual", "New Mode"],
                ["New Lowest", "New Low"],
                id="model_exception",
            ),
        ],
    )
    def test_modes_speeds_exception(
        self,
        exceptions: dict[str, HumidifierExceptions],
        expected_modes: list[str],
        expected_speeds: list[str],
    ) -> None:
        """Test per-model modes and speeds exceptions."""
        with patch.dict(A1_EXCEPTIONS, exceptions):
            device = self._make_device()

        assert device.modes == expected_modes
        assert device.fan_speeds == expected_speeds
