"""Test CD Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.cd import DeviceAttributes, LuaProtocol, MideaCDDevice
from midealocal.devices.cd.message import (
    MessageQuery,
    MessageQueryDaily,
    MessageQueryWeekly,
)
from midealocal.message import MessageType


def _make_device(model: str = "test_model", customize: str = "") -> MideaCDDevice:
    """Build a Midea CD device with a specific model/customize."""
    return MideaCDDevice(
        name="Test Device",
        device_id=1,
        ip_address="192.168.1.1",
        port=6444,
        token="AA",
        key="BB",
        device_protocol=ProtocolVersion.V1,
        model=model,
        subtype=1,
        customize=customize,
    )


def _build_message(message_type: MessageType, body: bytearray) -> bytes:
    """Build a full CD response message."""
    header = bytearray([0xAA, 0x00, 0xCD, 0x00, 0x00, 0x00, 0x00, 0x00])
    header += bytearray([ProtocolVersion.V1, message_type])
    return bytes(header + body + bytearray([0x00]))


def _general_body() -> bytearray:
    """Build a general status body (old-protocol raw temperature values)."""
    body = bytearray(63)
    body[0] = 0x01  # body_type
    body[2] = 0x05  # power on + standard mode
    body[3] = 110  # target temperature -> (110 - 30) / 2 = 40
    body[4] = 100  # current temperature -> 35
    body[5] = 45  # top temperature (raw)
    body[7] = 90  # condenser temperature -> 30
    body[8] = 70  # outdoor temperature -> 20
    body[9] = 110  # compressor temperature -> 40
    body[10] = 160  # max temperature -> 65
    body[11] = 100  # min temperature -> 35
    body[20] = 3  # error code
    body[27] = 0x10  # wind middle
    body[34] = 50  # water level
    body[61] = 65  # disinfection temperature 65.0
    return body


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

    def test_ts_max_falls_back_when_max_unconvertible(self) -> None:
        """A stored max_temperature that fails int() conversion sends tsMax=0."""

        class UnconvertibleFloat(float):
            """A float that raises when int() is attempted on it."""

            def __int__(self) -> int:
                raise ValueError("cannot convert")

        self.device._attributes[DeviceAttributes.max_temperature] = UnconvertibleFloat(
            70.0,
        )

        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.ts_max == 0

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

    # ------------------------------------------------------------------ #
    # properties and query                                                #
    # ------------------------------------------------------------------ #

    def test_temperature_step_property(self) -> None:
        """Default temperature step is 1.0."""
        assert self.device.temperature_step == 1.0

    def test_build_query(self) -> None:
        """Build query returns status, weekly and daily queries."""
        queries = self.device.build_query()
        assert len(queries) == 3
        assert isinstance(queries[0], MessageQuery)
        assert isinstance(queries[1], MessageQueryWeekly)
        assert isinstance(queries[2], MessageQueryDaily)

    # ------------------------------------------------------------------ #
    # temperature conversion helpers                                       #
    # ------------------------------------------------------------------ #

    def test_value_to_temperature_old_protocol(self) -> None:
        """Old protocol decodes (value - 30) / 2."""
        assert self.device._lua_protocol == LuaProtocol.old
        assert self.device._value_to_temperature(110, False, False) == 40

    def test_value_to_temperature_fahrenheit(self) -> None:
        """Fahrenheit device state converts to celsius."""
        self.device._fahrenheit = True
        assert self.device._value_to_temperature(104, False, False) == 40.0

    def test_value_to_temperature_force_fahrenheit(self) -> None:
        """force_fahrenheit converts even when the device reports celsius."""
        assert self.device._fahrenheit is False
        assert self.device._value_to_temperature(104, True, False) == 40.0

    def test_value_to_temperature_new_protocol(self) -> None:
        """New protocol passes the value through, force_old still decodes."""
        self.device.set_customize('{"lua_protocol": "new"}')
        assert self.device._value_to_temperature(40.0, False, False) == 40.0
        assert self.device._value_to_temperature(110, False, True) == 40

    def test_temperature_to_value_old_protocol(self) -> None:
        """Old protocol encodes value * 2 + 30."""
        assert self.device._temperature_to_value(40) == 110

    def test_temperature_to_value_fahrenheit(self) -> None:
        """Fahrenheit device state converts celsius to fahrenheit."""
        self.device._fahrenheit = True
        assert self.device._temperature_to_value(40) == 104.0

    def test_temperature_to_value_new_protocol(self) -> None:
        """New protocol passes the value through."""
        self.device.set_customize('{"lua_protocol": "new"}')
        assert self.device._temperature_to_value(40.0) == 40.0

    # ------------------------------------------------------------------ #
    # process_message with real frames                                     #
    # ------------------------------------------------------------------ #

    def test_process_general_status_message(self) -> None:
        """A general status frame decodes power, mode and temperatures."""
        new_status = self.device.process_message(
            _build_message(MessageType.query, _general_body()),
        )
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.mode] == "Standard"
        assert self.device.attributes[DeviceAttributes.target_temperature] == 40
        assert self.device.attributes[DeviceAttributes.current_temperature] == 35
        assert self.device.attributes[DeviceAttributes.outdoor_temperature] == 20
        assert self.device.attributes[DeviceAttributes.condenser_temperature] == 30
        assert self.device.attributes[DeviceAttributes.compressor_temperature] == 40
        assert self.device.attributes[DeviceAttributes.max_temperature] == 65
        assert self.device.attributes[DeviceAttributes.min_temperature] == 35
        assert self.device.attributes[DeviceAttributes.top_temperature] == 45.0
        assert self.device.attributes[DeviceAttributes.wind] == "middle"
        assert self.device.attributes[DeviceAttributes.water_level] == 50
        assert self.device.attributes[DeviceAttributes.error_code] == 3
        assert self.device.attributes[DeviceAttributes.disinfection_temperature] == 65.0
        assert self.device.attributes[DeviceAttributes.fahrenheit] is False
        assert new_status[DeviceAttributes.mode.value] == "Standard"

    def test_process_vacation_status_message(self) -> None:
        """Vacation bit in body[35] maps to Vacation mode and days."""
        body = _general_body()
        body[35] = 0x01
        body[36] = 0x00
        body[37] = 30
        self.device.process_message(_build_message(MessageType.query, body))
        assert self.device.attributes[DeviceAttributes.mode] == "Vacation"
        assert self.device.attributes[DeviceAttributes.vacation_mode] is True
        assert self.device.attributes[DeviceAttributes.vacation_days] == 30

    def test_process_fahrenheit_status_message(self) -> None:
        """Fahrenheit flag switches temperature decoding to F -> C."""
        body = _general_body()
        body[35] = 0x80  # fahrenheit
        body[3] = 104  # -> 40.0 C
        body[4] = 95  # -> 35.0 C
        body[10] = 149  # -> 65.0 C
        body[11] = 95  # -> 35.0 C
        self.device.process_message(_build_message(MessageType.query, body))
        assert self.device._fahrenheit is True
        assert self.device.attributes[DeviceAttributes.fahrenheit] is True
        assert self.device.attributes[DeviceAttributes.target_temperature] == 40.0
        assert self.device.attributes[DeviceAttributes.current_temperature] == 35.0
        assert self.device.attributes[DeviceAttributes.max_temperature] == 65.0

    def test_process_set_echo_updates_fields(self) -> None:
        """A controlType=0x01 SET echo stores fields for later writes."""
        body = bytearray([0x01, 0x01, 0x01, 0x02, 110, 1, 2, 3, 0x10, 0x00, 30])
        new_status = self.device.process_message(
            _build_message(MessageType.set, body),
        )
        assert self.device._fields == {
            "trValue": 1,
            "openPTC": 2,
            "ptcTemp": 3,
            "byte8": 0x10,
        }
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.mode] == "Standard"
        assert self.device.attributes[DeviceAttributes.target_temperature] == 40
        assert self.device.attributes[DeviceAttributes.vacation_mode] is True
        assert self.device.attributes[DeviceAttributes.vacation_days] == 30
        assert new_status[DeviceAttributes.vacation_days.value] == 30

    def test_sanitize_set_fields_drops_unconvertible_tr_value(self) -> None:
        """A non-numeric trValue echo is dropped instead of raising."""
        clean = MideaCDDevice._sanitize_set_fields(
            {"trValue": "abc", "openPTC": 1, "ptcTemp": 2, "byte8": 0x10},
        )
        assert clean == {}

    def test_process_weekly_schedule_message(self) -> None:
        """A weekly schedule frame stores the parsed schedule."""
        body = bytearray(177)
        body[0] = 0x02
        body[2] = 0x01  # day 0 timer 1 effect
        body[9] = 10  # opentime
        body[10] = 20  # closetime
        body[11] = 45  # temperature
        body[12] = 2  # mode
        self.device.process_message(_build_message(MessageType.query, body))
        schedule = self.device.attributes[DeviceAttributes.weekly_schedule]
        assert schedule is not None
        assert schedule[0][0] == {
            "effect": True,
            "opentime": 10,
            "closetime": 20,
            "temperature": 45,
            "mode": 2,
        }
        assert schedule[6][5]["effect"] is False

    def test_process_daily_timer_message(self) -> None:
        """A daily timer frame stores the parsed timer programme."""
        body = bytearray(40)
        body[0] = 0x03
        body[2] = 2  # amount
        body[3] = 0x41  # timer 1 effect + single_timer_on
        body[4] = 6
        body[5] = 30
        body[6] = 8
        body[7] = 15
        body[8] = 45
        body[9] = 2
        self.device.process_message(_build_message(MessageType.query, body))
        schedule = self.device.attributes[DeviceAttributes.daily_timer_schedule]
        assert schedule is not None
        assert schedule["amount"] == 2
        assert schedule["single_timer_on"] is True
        assert schedule["single_timer_off"] is False
        assert schedule["timers"][0] == {
            "effect": True,
            "openhour": 6,
            "openmin": 30,
            "closehour": 8,
            "closemin": 15,
            "temperature": 45,
            "mode": 2,
        }

    # ------------------------------------------------------------------ #
    # process_message corner cases                                         #
    # ------------------------------------------------------------------ #

    def test_process_message_unknown_mode_is_skipped(self) -> None:
        """Unrecognised mode values do not corrupt the stored mode."""

        class FakeMessage:
            mode = 8

        with patch(
            "midealocal.devices.cd.MessageCDResponse",
            return_value=FakeMessage(),
        ):
            status = self.device.process_message(b"")
        assert DeviceAttributes.mode.value not in status
        assert self.device.attributes[DeviceAttributes.mode] is None

    def test_process_message_bad_temperature_keeps_existing(self) -> None:
        """Unparsable temperature values preserve the existing reading."""
        self.device.set_customize('{"lua_protocol": "new"}')

        class FakeMessage:
            max_temperature = "bad"

        with patch(
            "midealocal.devices.cd.MessageCDResponse",
            return_value=FakeMessage(),
        ):
            status = self.device.process_message(b"")
        assert status[DeviceAttributes.max_temperature.value] == 65.0
        assert self.device.attributes[DeviceAttributes.max_temperature] == 65.0

    def test_process_message_zero_temperature_without_existing(self) -> None:
        """Zero temperatures are stored when no previous reading exists."""
        self.device.set_customize('{"lua_protocol": "new"}')
        assert self.device.attributes[DeviceAttributes.current_temperature] is None

        class FakeMessage:
            current_temperature = 0.0

        with patch(
            "midealocal.devices.cd.MessageCDResponse",
            return_value=FakeMessage(),
        ):
            status = self.device.process_message(b"")
        assert status[DeviceAttributes.current_temperature.value] == 0.0
        assert self.device.attributes[DeviceAttributes.current_temperature] == 0.0

    def test_process_message_disinfection_temperature_none_skipped(self) -> None:
        """None disinfection temperature preserves the previous reading."""
        self.device._attributes[DeviceAttributes.disinfection_temperature] = 67.0

        class FakeMessage:
            disinfection_temperature = None

        with patch(
            "midealocal.devices.cd.MessageCDResponse",
            return_value=FakeMessage(),
        ):
            status = self.device.process_message(b"")
        assert DeviceAttributes.disinfection_temperature.value not in status
        assert self.device.attributes[DeviceAttributes.disinfection_temperature] == 67.0

    def test_process_message_forced_conversions_rsjrac06(self) -> None:
        """RSJRAC06 forces fahrenheit outdoor and old-protocol current temps."""
        device = _make_device(model="RSJRAC06")
        assert device._lua_protocol == LuaProtocol.new

        class FakeMessage:
            outdoor_temperature = 68.0
            current_temperature = 110.0

        with patch(
            "midealocal.devices.cd.MessageCDResponse",
            return_value=FakeMessage(),
        ):
            status = device.process_message(b"")
        assert status[DeviceAttributes.outdoor_temperature.value] == 20.0
        assert status[DeviceAttributes.current_temperature.value] == 40

    # ------------------------------------------------------------------ #
    # set_attribute branches                                               #
    # ------------------------------------------------------------------ #

    def test_set_power_target_temperature_fallback_to_min(self) -> None:
        """Invalid stored target temperature falls back to min_temperature."""
        self.device._attributes[DeviceAttributes.target_temperature] = None
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.target_temperature == 35.0

    def test_set_power_target_temperature_fallback_default(self) -> None:
        """Invalid target and min temperatures fall back to 40.0."""
        self.device._attributes[DeviceAttributes.target_temperature] = None
        self.device._attributes[DeviceAttributes.min_temperature] = None
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.target_temperature == 40.0

    def test_set_power_with_vacation_mode_state(self) -> None:
        """Stored Vacation mode is never sent as a modeValue."""
        self.device._attributes[DeviceAttributes.mode] = "Vacation"
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.mode == 0x00

    def test_set_power_with_known_mode_state(self) -> None:
        """Stored Standard mode maps back to its key."""
        self.device._attributes[DeviceAttributes.mode] = "Standard"
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.mode == 0x02

    def test_set_power_with_none_string_mode_state(self) -> None:
        """Stored "None" mode maps to 0x00."""
        self.device._attributes[DeviceAttributes.mode] = "None"
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.mode == 0x00

    def test_set_mode_invalid_value_not_sent(self) -> None:
        """Invalid mode values do not send a command."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.mode.value, "Bogus")
            mock_send.assert_not_called()

    def test_set_mode_standard(self) -> None:
        """A valid mode value is mapped to its key and sent."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.mode.value, "Standard")
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.mode == 0x02

    def test_set_target_temperature_attribute(self) -> None:
        """Setting the target temperature places the value in the message."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(
                DeviceAttributes.target_temperature.value,
                42.0,
            )
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.target_temperature == 42.0

    def test_enable_vacation_uses_current_days(self) -> None:
        """Enabling vacation reuses the stored vacation days."""
        self.device._attributes[DeviceAttributes.vacation_days] = 30
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.vacation_mode.value, True)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.vacation_flag is True
            assert msg.vacation_days == 30

    def test_enable_vacation_default_days(self) -> None:
        """Enabling vacation without stored days uses the default."""
        self.device._attributes[DeviceAttributes.vacation_days] = 0
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.vacation_mode.value, True)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.vacation_flag is True
            assert msg.vacation_days == 100

    # ------------------------------------------------------------------ #
    # set_customize                                                        #
    # ------------------------------------------------------------------ #

    def test_set_customize_temperature_step(self) -> None:
        """Customize can override the temperature step."""
        self.device.set_customize('{"temperature_step": 0.5}')
        assert self.device.temperature_step == 0.5

    def test_set_customize_lua_protocol_new(self) -> None:
        """Customize can force the new lua protocol."""
        self.device.set_customize('{"lua_protocol": "new"}')
        assert self.device._lua_protocol == LuaProtocol.new

    def test_set_customize_lua_protocol_bool_true(self) -> None:
        """Boolean lua_protocol true maps to new."""
        self.device.set_customize('{"lua_protocol": true}')
        assert self.device._lua_protocol == LuaProtocol.new

    def test_set_customize_lua_protocol_bool_false(self) -> None:
        """Boolean lua_protocol false maps to old."""
        self.device.set_customize('{"lua_protocol": false}')
        assert self.device._lua_protocol == LuaProtocol.old

    def test_set_customize_invalid_json(self) -> None:
        """Invalid customize JSON keeps the defaults."""
        self.device.set_customize("{bad json")
        assert self.device.temperature_step == 1.0
        assert self.device._lua_protocol == LuaProtocol.old

    def test_auto_lua_protocol_resolves_new_for_rsjrac01(self) -> None:
        """RSJRAC01 resolves the auto lua protocol to new."""
        device = _make_device(model="RSJRAC01")
        assert device._lua_protocol == LuaProtocol.new
