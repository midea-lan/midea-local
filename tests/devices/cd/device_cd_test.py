"""Test CD Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.cd import DeviceAttributes, MideaCDDevice


class TestMideaCDDevice:
    """Test Midea CD Device."""

    device: MideaCDDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea CD Device setup."""
        self.device = MideaCDDevice(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.1",
            port=6444,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model="test_model",
            subtype=1,
            customize="",
        )

    # ------------------------------------------------------------------ #
    # vacation_temperature fallback (Bug: max_temperature reset to 0)     #
    # ------------------------------------------------------------------ #

    def test_set_power_uses_max_temperature_when_vacation_temperature_is_none(
        self,
    ) -> None:
        """vacation_temperature=None → SET message uses max_temperature as vacationTsValue."""
        # Simulate state: max_temperature set, vacation_temperature never received
        self.device._attributes[DeviceAttributes.max_temperature] = 65.0
        self.device._attributes[DeviceAttributes.vacation_temperature] = None

        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.vacation_temperature == 65.0

    def test_set_power_uses_max_temperature_when_vacation_temperature_is_zero(
        self,
    ) -> None:
        """vacation_temperature=0 → SET message uses max_temperature as vacationTsValue."""
        self.device._attributes[DeviceAttributes.max_temperature] = 65.0
        self.device._attributes[DeviceAttributes.vacation_temperature] = 0

        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.vacation_temperature == 65.0

    def test_set_power_uses_vacation_temperature_when_set(self) -> None:
        """When max_temperature is valid, it is preferred over vacation_temperature for echo safety."""
        self.device._attributes[DeviceAttributes.max_temperature] = 65.0
        self.device._attributes[DeviceAttributes.vacation_temperature] = 60.0

        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.vacation_temperature == 65.0

    def test_disable_vacation_uses_max_temperature_fallback(self) -> None:
        """Disabling vacation with vacation_temperature=None sends max_temperature as vacationTsValue."""
        self.device._attributes[DeviceAttributes.max_temperature] = 65.0
        self.device._attributes[DeviceAttributes.vacation_temperature] = None
        self.device._attributes[DeviceAttributes.vacation_mode] = True

        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.vacation_mode.value, False)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.vacation_temperature == 65.0
            assert msg.vacation_flag is False
            assert msg.vacation_days == 0

    def test_disable_vacation_uses_max_temperature_when_vacation_temp_zero(
        self,
    ) -> None:
        """Disabling vacation with vacation_temperature=0 → fallback to max_temperature."""
        self.device._attributes[DeviceAttributes.max_temperature] = 65.0
        self.device._attributes[DeviceAttributes.vacation_temperature] = 0.0
        self.device._attributes[DeviceAttributes.vacation_mode] = True

        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.vacation_mode.value, False)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.vacation_temperature == 65.0

    def test_set_vacation_days_uses_max_temperature_fallback(self) -> None:
        """Setting vacation_days with vacation_temperature=None → vacationTsValue=max_temperature."""
        self.device._attributes[DeviceAttributes.max_temperature] = 65.0
        self.device._attributes[DeviceAttributes.vacation_temperature] = None

        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.vacation_days.value, 30)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.vacation_temperature == 65.0
            assert msg.vacation_flag is True
            assert msg.vacation_days == 30

    def test_vacation_temperature_fallback_zero_when_both_absent(self) -> None:
        """vacation_temperature=None and max_temperature=None → vacationTsValue=0.0 (safe default)."""
        self.device._attributes[DeviceAttributes.max_temperature] = None
        self.device._attributes[DeviceAttributes.vacation_temperature] = None

        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.vacation_temperature == 0.0

    # ------------------------------------------------------------------ #
    # disinfect set_attribute                                              #
    # ------------------------------------------------------------------ #

    def test_set_disinfect_true_sends_sterilize_message(self) -> None:
        """set_attribute('disinfect', True) sends MessageSetSterilize with sterilize_on=True."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.disinfect.value, True)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.sterilize_on is True

    def test_set_disinfect_false_sends_sterilize_message(self) -> None:
        """set_attribute('disinfect', False) sends MessageSetSterilize with sterilize_on=False."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.disinfect.value, False)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.sterilize_on is False

    def test_set_disinfect_true_echoes_known_disinfection_temperature(self) -> None:
        """set_attribute('disinfect', True) preserves known disinfection_temperature in body[3]."""
        self.device._attributes[DeviceAttributes.disinfection_temperature] = 67.0
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.disinfect.value, True)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.sterilize_on is True
            assert msg.disinfection_temperature == 67.0

    def test_set_disinfect_true_uses_week_fallback_when_no_temperature(self) -> None:
        """set_attribute('disinfect', True) falls back to week bitmap when no temperature stored."""
        self.device._attributes[DeviceAttributes.disinfection_temperature] = None
        self.device._attributes[DeviceAttributes.auto_sterilize_week] = 5
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.disinfect.value, True)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.sterilize_on is True
            assert msg.disinfection_temperature is None
            assert msg.week == 5

    # ------------------------------------------------------------------ #
    # disinfection_temperature as settable attribute                       #
    # ------------------------------------------------------------------ #

    def test_set_disinfection_temperature_sends_sterilize_message(self) -> None:
        """set_attribute('disinfection_temperature', 65) sends MessageSetSterilize."""
        self.device._attributes[DeviceAttributes.disinfect] = True
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.disinfection_temperature.value, 65.0)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.disinfection_temperature == 65.0
            assert msg.sterilize_on is True

    def test_set_disinfection_temperature_preserves_sterilize_off(self) -> None:
        """set_attribute('disinfection_temperature') keeps sterilize off if it was off."""
        self.device._attributes[DeviceAttributes.disinfect] = False
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.disinfection_temperature.value, 67.0)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.disinfection_temperature == 67.0
            assert msg.sterilize_on is False

    def test_set_disinfection_temperature_clamps_below_min(self) -> None:
        """set_attribute('disinfection_temperature', 50) is clamped to 60.0."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.disinfection_temperature.value, 50.0)
            msg = mock_send.call_args[0][0]
            assert msg.disinfection_temperature == 60.0

    def test_set_disinfection_temperature_clamps_above_max(self) -> None:
        """set_attribute('disinfection_temperature', 80) is clamped to 70.0."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.disinfection_temperature.value, 80.0)
            msg = mock_send.call_args[0][0]
            assert msg.disinfection_temperature == 70.0

    # ------------------------------------------------------------------ #
    # max_temperature as settable attribute (replaces vacation_temperature) #
    # ------------------------------------------------------------------ #

    def test_set_max_temperature_sends_message_set(self) -> None:
        """set_attribute('max_temperature', 65) sends MessageSet with vacation_temperature=65."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.max_temperature.value, 65.0)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.vacation_temperature == 65.0

    def test_set_max_temperature_70(self) -> None:
        """set_attribute('max_temperature', 70) sends MessageSet with vacation_temperature=70."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.max_temperature.value, 70.0)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.vacation_temperature == 70.0

    def test_set_max_temperature_clamped_to_70(self) -> None:
        """set_attribute('max_temperature', 80) is clamped to 70.0."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.max_temperature.value, 80.0)
            msg = mock_send.call_args[0][0]
            assert msg.vacation_temperature == 70.0

    def test_set_max_temperature_clamped_to_65(self) -> None:
        """set_attribute('max_temperature', 40) is clamped to 65.0."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.max_temperature.value, 40.0)
            msg = mock_send.call_args[0][0]
            assert msg.vacation_temperature == 65.0

    def test_set_max_temperature_does_not_change_vacation_flag(self) -> None:
        """Setting max_temperature does not inadvertently toggle vacation_mode flag."""
        self.device._attributes[DeviceAttributes.vacation_mode] = False
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.max_temperature.value, 65.0)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            # vacation_flag should be False (not enabling vacation mode)
            assert msg.vacation_flag is False

    def test_set_vacation_temperature_is_not_settable(self) -> None:
        """vacation_temperature is no longer a settable attribute; build_send must not be called."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.vacation_temperature.value, 65.0)
            mock_send.assert_not_called()

    # ------------------------------------------------------------------ #
    # maintenance_reminder (official app naming)                         #
    # ------------------------------------------------------------------ #

    def test_set_maintenance_reminder_requires_weekly_schedule(self) -> None:
        """Without weekly_schedule, setting maintenance_reminder must not send a command."""
        self.device._attributes[DeviceAttributes.weekly_schedule] = None
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.maintenance_reminder.value, True)
            mock_send.assert_not_called()

    def test_set_maintenance_reminder_sends_weekly_message(self) -> None:
        """maintenance_reminder ON sends controlType=0x07 with day0 bit 0x40 set."""
        empty_slot = {
            "effect": False,
            "opentime": 0,
            "closetime": 0,
            "temperature": 0,
            "mode": 0,
        }
        weekly_schedule = {day: [dict(empty_slot) for _ in range(6)] for day in range(7)}
        self.device._attributes[DeviceAttributes.weekly_schedule] = weekly_schedule
        self.device._attributes[DeviceAttributes.maintain_warn] = False

        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.maintenance_reminder.value, True)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            body = msg.body
            assert body[0] == 0x07  # noqa: PLR2004
            assert (body[2] & 0x40) == 0x40  # noqa: PLR2004
            assert (body[2] & 0x80) == 0x00  # noqa: PLR2004
