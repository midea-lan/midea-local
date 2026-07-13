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
    # MessageSet 25-byte body / tsMax (issue #468)                        #
    # ------------------------------------------------------------------ #

    def test_preset_modes_excludes_vacation_from_selectable_modes(self) -> None:
        """Vacation is readable state, not directly selectable operation mode."""
        assert "Vacation" not in self.device.preset_modes
        assert self.device._modes[0x05] == "Vacation"

    def test_set_mode_vacation_is_rejected(self) -> None:
        """Direct Vacation operation mode writes are blocked."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.mode.value, "Vacation")
            mock_send.assert_not_called()

    def test_set_power_uses_ts_max_at_body_23(self) -> None:
        """Plain SET uses device max_temperature as full[23] tsMax (#468)."""
        self.device._attributes[DeviceAttributes.max_temperature] = 70.0
        self.device._attributes[DeviceAttributes.vacation_temperature] = 65.0

        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.ts_max == 70
            assert len(msg.body) == 25
            assert msg.body[23] == 70  # tsMax
            assert msg.body[21] == 0  # vacationTs left 0 on plain set
            assert msg.body[4] != 0  # target present

    def test_set_target_temperature_body_length_and_ts_max(self) -> None:
        """set_temperature builds 25-byte body with non-zero tsMax."""
        # RSJRAC07 uses the new (raw °C) Lua protocol — matches issue #468.
        self.device.set_customize('{"lua_protocol": "new"}')
        self.device._attributes[DeviceAttributes.max_temperature] = 65.0
        self.device._attributes[DeviceAttributes.target_temperature] = 60.0
        self.device._attributes[DeviceAttributes.power] = True
        self.device._attributes[DeviceAttributes.mode] = "Standard"

        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.target_temperature.value, 63.0)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.target_temperature == 63.0
            assert msg.use_old_protocol is False
            assert len(msg.body) == 25
            assert msg.body[4] == 63
            assert msg.body[23] == 65

    def test_disable_vacation_sets_flag_and_mode(self) -> None:
        """Disabling vacation clears flag and forces Energy-save mode."""
        self.device._attributes[DeviceAttributes.max_temperature] = 65.0
        self.device._attributes[DeviceAttributes.vacation_mode] = True

        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.vacation_mode.value, False)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.vacation_flag is False
            assert msg.vacation_days == 0
            assert msg.mode == 0x01
            assert msg.body[23] == 65

    def test_set_vacation_days_encodes_days(self) -> None:
        """vacation_days SET keeps tsMax and marks vacation flag."""
        self.device._attributes[DeviceAttributes.max_temperature] = 65.0

        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.vacation_days.value, 30)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.vacation_flag is True
            assert msg.vacation_days == 30
            assert msg.body[10] == 30  # vacation days low
            assert msg.body[23] == 65

    def test_ts_max_falls_back_when_max_missing(self) -> None:
        """Missing max_temperature still yields non-zero tsMax via MessageSet."""
        self.device._attributes[DeviceAttributes.max_temperature] = None

        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.body[23] != 0

    # ------------------------------------------------------------------ #
    # disinfect set_attribute                                              #
    # ------------------------------------------------------------------ #

    def test_set_disinfect_true_is_read_only(self) -> None:
        """Immediate disinfection writes are disabled."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.disinfect.value, True)
            mock_send.assert_not_called()

    def test_set_disinfect_true_does_not_echo_temperature(self) -> None:
        """Known disinfection_temperature must not be written."""
        self.device._attributes[DeviceAttributes.disinfection_temperature] = 67.0
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.disinfect.value, True)
            mock_send.assert_not_called()

    def test_set_disinfect_true_does_not_write_valid_schedule(self) -> None:
        """Toggling disinfect is intentionally read-only even with valid schedule."""
        self.device._attributes[DeviceAttributes.auto_sterilize_week] = 4
        self.device._attributes[DeviceAttributes.auto_sterilize_hour] = 18
        self.device._attributes[DeviceAttributes.auto_sterilize_minute] = 30
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.disinfect.value, True)
            mock_send.assert_not_called()

    def test_set_disinfect_false_is_read_only(self) -> None:
        """Disabling immediate disinfect from HA must not send the unsafe command."""
        self.device._attributes[DeviceAttributes.auto_sterilize_week] = 4
        self.device._attributes[DeviceAttributes.auto_sterilize_hour] = 18
        self.device._attributes[DeviceAttributes.auto_sterilize_minute] = 30
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.disinfect.value, False)
            mock_send.assert_not_called()

    def test_set_disinfect_true_does_not_write_invalid_schedule(self) -> None:
        """Invalid current schedule values are not written through disinfect."""
        self.device._attributes[DeviceAttributes.auto_sterilize_week] = 133
        self.device._attributes[DeviceAttributes.auto_sterilize_hour] = 168
        self.device._attributes[DeviceAttributes.auto_sterilize_minute] = 86
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.disinfect.value, True)
            mock_send.assert_not_called()

    def test_process_message_drops_invalid_auto_sterilize_values(self) -> None:
        """Impossible status schedule values are not published as HA state."""

        class FakeMessage:
            auto_sterilize_week = 21
            auto_sterilize_hour = 133
            auto_sterilize_minute = 168

        with patch(
            "midealocal.devices.cd.MessageCDResponse",
            return_value=FakeMessage(),
        ):
            status = self.device.process_message(b"")

        assert status[DeviceAttributes.auto_sterilize_week.value] is None
        assert status[DeviceAttributes.auto_sterilize_hour.value] is None
        assert status[DeviceAttributes.auto_sterilize_minute.value] is None
        assert self.device._attributes[DeviceAttributes.auto_sterilize_week] is None
        assert self.device._attributes[DeviceAttributes.auto_sterilize_hour] is None
        assert self.device._attributes[DeviceAttributes.auto_sterilize_minute] is None

    def test_process_message_publishes_valid_auto_sterilize_values(self) -> None:
        """Valid status schedule values still update HA state."""

        class FakeMessage:
            auto_sterilize_week = 4
            auto_sterilize_hour = 14
            auto_sterilize_minute = 5

        with patch(
            "midealocal.devices.cd.MessageCDResponse",
            return_value=FakeMessage(),
        ):
            status = self.device.process_message(b"")

        assert status[DeviceAttributes.auto_sterilize_week.value] == 4
        assert status[DeviceAttributes.auto_sterilize_hour.value] == 14
        assert status[DeviceAttributes.auto_sterilize_minute.value] == 5

    # ------------------------------------------------------------------ #
    # disinfection_temperature is read-only for CD                         #
    # ------------------------------------------------------------------ #

    def test_set_disinfection_temperature_is_not_settable(self) -> None:
        """Disinfection temperature does not send controlType=0x06."""
        self.device._attributes[DeviceAttributes.disinfect] = True
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(
                DeviceAttributes.disinfection_temperature.value,
                65.0,
            )
            mock_send.assert_not_called()

    # ------------------------------------------------------------------ #
    # max_temperature                                                       #
    # ------------------------------------------------------------------ #

    def test_set_max_temperature_sends_clamped_message(self) -> None:
        """max_temperature is read-only until the write payload is safe."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.max_temperature.value, 70.0)
            mock_send.assert_not_called()

    def test_set_vacation_temperature_is_not_settable(self) -> None:
        """vacation_temperature is not settable."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute("vacation_temperature", 65.0)
            mock_send.assert_not_called()

    # ------------------------------------------------------------------ #
    # maintenance_reminder (official app naming)                         #
    # ------------------------------------------------------------------ #

    def test_set_maintenance_reminder_requires_weekly_schedule(self) -> None:
        """Setting maintenance_reminder must not send a command."""
        self.device._attributes[DeviceAttributes.weekly_schedule] = None
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.maintenance_reminder.value, True)
            mock_send.assert_not_called()

    def test_set_maintenance_reminder_is_read_only(self) -> None:
        """maintenance_reminder writes are disabled until the payload is safe."""
        empty_slot = {
            "effect": False,
            "opentime": 0,
            "closetime": 0,
            "temperature": 0,
            "mode": 0,
        }
        weekly_schedule = {
            day: [dict(empty_slot) for _ in range(6)] for day in range(7)
        }
        self.device._attributes[DeviceAttributes.weekly_schedule] = weekly_schedule
        self.device._attributes[DeviceAttributes.maintain_warn] = False

        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.maintenance_reminder.value, True)
            mock_send.assert_not_called()
