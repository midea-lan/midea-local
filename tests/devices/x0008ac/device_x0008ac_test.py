"""Tests for the Toshiba IoLife x0008ac device."""

from collections.abc import Callable
from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.x0008ac import DeviceAttributes, MideaX0008ACDevice
from midealocal.devices.x0008ac.message import (
    _MSG_TYPE_QUERY,
    MessageQuery,
    MessageSet,
    _assemble_frame,
)

# Property IDs mirrored from the device module for assertion
_PROP_POWER = 0x0001
_PROP_MODE = 0x0002
_PROP_TARGET_TEMP = 0x0003
_PROP_FAN_SPEED = 0x0006
_PROP_SWING_UD = 0x0008
_PROP_SWING_LR = 0x0009
_PROP_DEFLECTOR_ANGLE = 0x000A
_PROP_ECO = 0x000D
_PROP_SCREEN_DISPLAY = 0x0017
_PROP_BUZZER = 0x001A
_PROP_CLEAN = 0x0046
_PROP_DEHUMIDIFY = 0x0051
_PROP_BREEZELESS_DIRECTION = 0x0070
_PROP_ENERGY_SAVE = 0x0050
_PROP_COMFORT_AIRFLOW = 0x0055


def _make_c0_frame(overrides: dict[int, int] | None = None) -> bytes:
    """Build a minimal valid C0 status frame with optional byte overrides."""
    body = [0] * 28
    body[0] = 0xC0
    if overrides:
        for idx, val in overrides.items():
            body[idx] = val
    return bytes(_assemble_frame(body, _MSG_TYPE_QUERY))


class TestMideaX0008ACDevice:
    """Tests for MideaX0008ACDevice."""

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Set up a MideaX0008ACDevice instance for each test."""
        self.device = MideaX0008ACDevice(
            name="Test AC",
            device_id=1,
            ip_address="192.168.1.1",
            port=6444,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model="",
            subtype=0,
            customize="",
        )

    def test_initial_attributes(self) -> None:
        """Test all DeviceAttributes start at their documented default values."""
        attrs = self.device.attributes
        assert attrs[DeviceAttributes.power] is False
        assert attrs[DeviceAttributes.mode] == 0
        assert attrs[DeviceAttributes.target_temperature] == 22.0
        assert attrs[DeviceAttributes.fan_speed] == 0
        assert attrs[DeviceAttributes.swing_vertical] == 0
        assert attrs[DeviceAttributes.swing_horizontal] == 0
        assert attrs[DeviceAttributes.wind_ud_angle] is None
        assert attrs[DeviceAttributes.wind_lr_angle] is None
        assert attrs[DeviceAttributes.indoor_temperature] is None
        assert attrs[DeviceAttributes.outdoor_temperature] is None
        assert attrs[DeviceAttributes.indoor_humidity] is None
        assert attrs[DeviceAttributes.eco_mode] is False
        assert attrs[DeviceAttributes.anion] is False
        assert attrs[DeviceAttributes.dry] is False
        assert attrs[DeviceAttributes.dehumidify] == 0
        assert attrs[DeviceAttributes.energy_save] is False
        assert attrs[DeviceAttributes.comfort_mode] is False
        assert attrs[DeviceAttributes.breezeless] == 0
        assert attrs[DeviceAttributes.full_dust] is False
        assert attrs[DeviceAttributes.error_code] == 0
        assert attrs[DeviceAttributes.self_clean] is False
        assert attrs[DeviceAttributes.cleaning] is False
        assert attrs[DeviceAttributes.clean_manual] is False
        assert attrs[DeviceAttributes.prompt_tone] is True

    def test_build_query_returns_single_message_query(self) -> None:
        """Test build_query returns exactly one MessageQuery."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    def test_process_message_c0_updates_power_and_mode(self) -> None:
        """Test that a C0 frame with power=True, mode=2 updates device state."""
        frame = _make_c0_frame({1: 0x01, 2: 0x20})  # power=True, mode=2
        status = self.device.process_message(frame)
        assert status[DeviceAttributes.power] is True
        assert status[DeviceAttributes.mode] == 2
        assert self.device.attributes[DeviceAttributes.power] is True

    def test_process_message_c0_temperature_and_fan(self) -> None:
        """Test that C0 frame temperature and fan speed bytes decode correctly."""
        frame = _make_c0_frame(
            {
                1: 0x01,  # power=True
                3: 0x32,  # fan_speed = 0x32 & 0x7F = 50
                4: 0x30,  # target_temp = (0x30 & 0x7F) / 2.0 = 24.0
                13: 100,  # indoor_raw
                14: 60,  # outdoor_raw
                15: 0x23,  # decimal: indoor=3, outdoor=2
            },
        )
        status = self.device.process_message(frame)
        assert status[DeviceAttributes.fan_speed] == 50
        assert status[DeviceAttributes.target_temperature] == 24.0
        assert status[DeviceAttributes.indoor_temperature] == pytest.approx(25.3)
        assert status[DeviceAttributes.outdoor_temperature] == pytest.approx(5.2)

    def test_process_message_unrecognised_frame_returns_empty(self) -> None:
        """Test that an empty/unrecognised frame returns an empty status dict."""
        assert self.device.process_message(b"") == {}

    def test_process_message_short_c0_body_returns_empty(self) -> None:
        """Test that a C0 body shorter than _C0_BODY_MIN_LEN returns empty status."""
        short_body = [0xC0] + [0] * 19  # 20 bytes < 22
        frame = bytes(_assemble_frame(short_body, _MSG_TYPE_QUERY))
        assert self.device.process_message(frame) == {}

    def test_set_attribute_power_on(self) -> None:
        """Test set_attribute(power, True) encodes power=1 in the SET command."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.power, True)
            mock_send.assert_called_once()
            cmd = mock_send.call_args[0][0]
            assert isinstance(cmd, MessageSet)
            assert cmd._params[_PROP_POWER] == bytearray([1])

    def test_set_attribute_power_off(self) -> None:
        """Test set_attribute(power, False) encodes power=0 in the SET command."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.power, False)
            cmd = mock_send.call_args[0][0]
            assert cmd._params[_PROP_POWER] == bytearray([0])

    def test_set_attribute_mode(self) -> None:
        """A mode write carries the power flag, so the unit runs in that mode."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.mode, 2)
            cmd = mock_send.call_args[0][0]
        assert cmd._params[_PROP_MODE] == bytearray([2])
        assert cmd._params[_PROP_POWER] == bytearray([1])
        assert _PROP_DEHUMIDIFY not in cmd._params

    def test_set_attribute_mode_dry_defaults_the_sub_mode(self) -> None:
        """Entering dry selects the recommended sub-mode rather than the last one."""
        self.device.process_message(_make_c0_frame({2: 0x20}))  # currently cool
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.mode, 3)
            cmd = mock_send.call_args[0][0]
        assert cmd._params[_PROP_MODE] == bytearray([3])
        assert cmd._params[_PROP_DEHUMIDIFY] == bytearray([4])

    def test_set_attribute_mode_dry_keeps_a_chosen_sub_mode(self) -> None:
        """Re-selecting dry while already in dry leaves the sub-mode alone."""
        self.device.process_message(_make_c0_frame({2: 0x30}))  # already dry
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.mode, 3)
            cmd = mock_send.call_args[0][0]
        assert cmd._params[_PROP_MODE] == bytearray([3])
        assert _PROP_DEHUMIDIFY not in cmd._params

    def test_set_attribute_target_temperature(self) -> None:
        """Test set_attribute(target_temperature, 24.0) encodes 24*2=48."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.target_temperature, 24.0)
            cmd = mock_send.call_args[0][0]
            assert cmd._params[_PROP_TARGET_TEMP] == bytearray([48])  # 24.0 * 2

    def test_set_attribute_target_temperature_half_degree(self) -> None:
        """Test set_attribute(target_temperature, 22.5) encodes 22.5*2=45."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.target_temperature, 22.5)
            cmd = mock_send.call_args[0][0]
            assert cmd._params[_PROP_TARGET_TEMP] == bytearray([45])  # 22.5 * 2

    def test_set_attribute_fan_speed(self) -> None:
        """Test set_attribute(fan_speed, 50) encodes the speed directly."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.fan_speed, 50)
            cmd = mock_send.call_args[0][0]
            assert cmd._params[_PROP_FAN_SPEED] == bytearray([50])

    def test_set_attribute_swing_vertical(self) -> None:
        """Test set_attribute(swing_vertical, 3) encodes the swing value."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.swing_vertical, 3)
            cmd = mock_send.call_args[0][0]
            assert cmd._params[_PROP_SWING_UD] == bytearray([3])

    def test_set_attribute_swing_horizontal(self) -> None:
        """Test set_attribute(swing_horizontal, 2) encodes the swing value."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.swing_horizontal, 2)
            cmd = mock_send.call_args[0][0]
            assert cmd._params[_PROP_SWING_LR] == bytearray([2])

    def test_set_attribute_eco_mode(self) -> None:
        """Test set_attribute(eco_mode, True) encodes eco=1."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.eco_mode, True)
            cmd = mock_send.call_args[0][0]
            assert cmd._params[_PROP_ECO] == bytearray([1])

    def test_set_attribute_energy_save(self) -> None:
        """Test set_attribute(energy_save, True) encodes energy_save=1."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.energy_save, True)
            cmd = mock_send.call_args[0][0]
            assert cmd._params[_PROP_ENERGY_SAVE] == bytearray([1])

    def test_set_attribute_comfort_airflow(self) -> None:
        """Test set_attribute(comfort_mode, True) encodes comfort_mode=1."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.comfort_mode, True)
            cmd = mock_send.call_args[0][0]
            assert cmd._params[_PROP_COMFORT_AIRFLOW] == bytearray([1])

    def test_set_attribute_prompt_tone_false_updates_local_flag(self) -> None:
        """set_attribute(prompt_tone, False) stores the flag, sends nothing."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.prompt_tone, False)
            mock_send.assert_not_called()
        assert self.device.attributes[DeviceAttributes.prompt_tone] is False

    def test_set_attribute_prompt_tone_true_updates_local_flag(self) -> None:
        """set_attribute(prompt_tone, True) restores the flag, sends nothing."""
        self.device.set_attribute(DeviceAttributes.prompt_tone, False)
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.prompt_tone, True)
            mock_send.assert_not_called()
        assert self.device.attributes[DeviceAttributes.prompt_tone] is True

    def test_prompt_tone_false_injects_mute_into_set_commands(self) -> None:
        """When prompt_tone=False, every SET command leads with 0x1A=0."""
        self.device.set_attribute(DeviceAttributes.prompt_tone, False)
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.power, True)
            cmd = mock_send.call_args[0][0]
        assert _PROP_BUZZER in cmd._params
        assert cmd._params[_PROP_BUZZER] == bytearray([0])

    def test_prompt_tone_true_omits_mute_from_set_commands(self) -> None:
        """When prompt_tone=True (default), SET commands omit property 0x1A."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.power, True)
            cmd = mock_send.call_args[0][0]
        assert _PROP_BUZZER not in cmd._params

    def test_process_message_c0_cleaning_decoded(self) -> None:
        """Cleaning is True when byte[16] bit5 is set in a C0 frame."""
        frame = _make_c0_frame({16: 0x22})  # bit1=anion, bit5=cleaning
        status = self.device.process_message(frame)
        assert status[DeviceAttributes.cleaning] is True
        assert status[DeviceAttributes.clean_manual] is False

    def test_process_message_c0_does_not_overwrite_self_clean(self) -> None:
        """self_clean is a local setting: a C0 frame must not clear it."""
        with patch.object(self.device, "build_send"):
            self.device.set_attribute(DeviceAttributes.self_clean, True)
        status = self.device.process_message(_make_c0_frame({16: 0x00}))
        assert DeviceAttributes.self_clean not in status
        assert self.device.attributes[DeviceAttributes.self_clean] is True

    def test_set_attribute_self_clean_sends_both_bytes(self) -> None:
        """self_clean writes 0x46 as [clean_manual, self_clean]."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.self_clean, True)
            cmd = mock_send.call_args[0][0]
        assert cmd._params[_PROP_CLEAN] == bytearray([0, 1])
        assert self.device.attributes[DeviceAttributes.self_clean] is True

    def test_set_attribute_clean_manual_preserves_self_clean(self) -> None:
        """Writing one clean flag keeps the other one's current value."""
        with patch.object(self.device, "build_send"):
            self.device.set_attribute(DeviceAttributes.self_clean, True)
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.clean_manual, True)
            cmd = mock_send.call_args[0][0]
        assert cmd._params[_PROP_CLEAN] == bytearray([1, 1])

    def test_set_attribute_read_only_does_not_send(self) -> None:
        """Test that setting read-only attributes does not call build_send."""
        with patch.object(self.device, "build_send") as mock_send:
            for attr in [
                DeviceAttributes.indoor_temperature,
                DeviceAttributes.outdoor_temperature,
                DeviceAttributes.indoor_humidity,
                DeviceAttributes.cleaning,
                DeviceAttributes.full_dust,
                DeviceAttributes.error_code,
            ]:
                self.device.set_attribute(attr, 1)
            mock_send.assert_not_called()

    def test_setpoint_limits_are_exposed(self) -> None:
        """min/max_temperature expose the 0x0003 property range to consumers."""
        assert self.device.attributes[DeviceAttributes.min_temperature] == 16.0
        assert self.device.attributes[DeviceAttributes.max_temperature] == 32.0

    def test_set_attribute_unsupported_attr_sends_nothing(self) -> None:
        """An attribute the protocol has no property for is refused, not sent."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute("no_such_attribute", True)
        mock_send.assert_not_called()

    def test_set_customize_without_temperature_step(self) -> None:
        """Valid customize JSON that omits the step leaves the default alone."""
        self.device.set_customize('{"something_else": 1}')
        assert self.device.temperature_step == 0.5

    def test_breezeless_direction_options(self) -> None:
        """breezeless_directions lists every selectable deflection direction."""
        assert self.device.breezeless_directions == ["off", "full", "left", "right"]

    def test_set_target_temperature_without_mode(self) -> None:
        """Only the setpoint is written when no mode is given."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_target_temperature(24.5, None)
            cmd = mock_send.call_args[0][0]
        assert cmd._params[_PROP_TARGET_TEMP] == bytearray([49])
        assert _PROP_POWER not in cmd._params
        assert _PROP_MODE not in cmd._params

    def test_set_target_temperature_with_mode_powers_on(self) -> None:
        """Passing a mode also powers the unit on and switches mode."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_target_temperature(26.0, 2)
            cmd = mock_send.call_args[0][0]
        assert cmd._params[_PROP_TARGET_TEMP] == bytearray([52])
        assert cmd._params[_PROP_POWER] == bytearray([1])
        assert cmd._params[_PROP_MODE] == bytearray([2])

    @pytest.mark.parametrize(
        ("vertical", "horizontal", "expected_ud", "expected_lr"),
        [
            (True, True, 1, 1),
            (True, False, 1, 0),
            (False, True, 0, 1),
            (False, False, 0, 0),
        ],
    )
    def test_set_swing_sends_both_axes(
        self,
        vertical: bool,
        horizontal: bool,
        expected_ud: int,
        expected_lr: int,
    ) -> None:
        """set_swing always writes both oscillation flags in one command."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_swing(vertical, horizontal)
            cmd = mock_send.call_args[0][0]
        assert cmd._params[_PROP_SWING_UD] == bytearray([expected_ud])
        assert cmd._params[_PROP_SWING_LR] == bytearray([expected_lr])

    def test_prompt_tone_off_suppresses_beep_on_wind_angle(self) -> None:
        """A deflector write carries the buzzer property when the tone is off."""
        with patch.object(self.device, "build_send"):
            self.device.set_attribute(DeviceAttributes.prompt_tone, False)
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.wind_ud_angle, "middle")
            cmd = mock_send.call_args[0][0]
        assert cmd._params[_PROP_BUZZER] == bytearray([0])

    def test_prompt_tone_off_suppresses_beep_on_self_clean(self) -> None:
        """A clean write carries the buzzer property when the tone is off."""
        with patch.object(self.device, "build_send"):
            self.device.set_attribute(DeviceAttributes.prompt_tone, False)
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.self_clean, True)
            cmd = mock_send.call_args[0][0]
        assert cmd._params[_PROP_BUZZER] == bytearray([0])

    @pytest.mark.parametrize(
        "call",
        [
            lambda device: device.set_target_temperature(24.0, None),
            lambda device: device.set_swing(swing_vertical=True, swing_horizontal=True),
            lambda device: device.set_attribute(DeviceAttributes.mode, 2),
        ],
        ids=["set_target_temperature", "set_swing", "set_mode"],
    )
    def test_prompt_tone_off_suppresses_beep_on_direct_setters(
        self,
        call: Callable[[MideaX0008ACDevice], None],
    ) -> None:
        """The dedicated setters carry the buzzer property when the tone is off."""
        with patch.object(self.device, "build_send"):
            self.device.set_attribute(DeviceAttributes.prompt_tone, False)
        with patch.object(self.device, "build_send") as mock_send:
            call(self.device)
            cmd = mock_send.call_args[0][0]
        assert cmd._params[_PROP_BUZZER] == bytearray([0])

    @pytest.mark.parametrize(
        ("requested", "expected_sub_mode"),
        [
            (1, 1),  # the unit's own silent
            (20, 1),  # silent -> weak
            (40, 1),  # low -> weak
            (60, 4),  # medium -> recommended
            (80, 2),  # high -> strong
            (100, 2),  # full -> strong
            (102, 4),  # auto -> recommended
        ],
    )
    def test_fan_speed_in_dry_sets_the_sub_mode(
        self,
        requested: int,
        expected_sub_mode: int,
    ) -> None:
        """In dry mode a fan write steers the dehumidify sub-mode instead."""
        self.device.process_message(_make_c0_frame({2: 0x30}))  # dry
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.fan_speed, requested)
            cmd = mock_send.call_args[0][0]
        assert cmd._params[_PROP_DEHUMIDIFY] == bytearray([expected_sub_mode])
        assert _PROP_FAN_SPEED not in cmd._params

    def test_fan_speed_outside_dry_is_written_normally(self) -> None:
        """Outside dry the fan speed is a real setting again."""
        self.device.process_message(_make_c0_frame({2: 0x20}))  # cool
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.fan_speed, 60)
            cmd = mock_send.call_args[0][0]
        assert cmd._params[_PROP_FAN_SPEED] == bytearray([60])
        assert _PROP_DEHUMIDIFY not in cmd._params

    @pytest.mark.parametrize(
        ("sub_mode", "reported"),
        [(1, 40), (2, 80), (4, 102)],
    )
    def test_dry_sub_mode_reported_as_fan_speed(
        self,
        sub_mode: int,
        reported: int,
    ) -> None:
        """The sub-mode reads back as the fan speed a consumer will name."""
        status = self.device.process_message(
            _make_c0_frame({2: 0x30, 3: 0x02, 21: sub_mode << 1}),
        )
        assert status[DeviceAttributes.fan_speed] == reported
        assert self.device.attributes[DeviceAttributes.fan_speed] == reported

    def test_clothes_drying_leaves_the_fan_speed_alone(self) -> None:
        """Clothes-drying has no fan equivalent, so the real speed shows through."""
        status = self.device.process_message(
            _make_c0_frame({2: 0x30, 3: 0x42, 21: 3 << 1}),
        )
        assert status[DeviceAttributes.dehumidify] == 3
        assert status[DeviceAttributes.fan_speed] == 0x42

    def test_fan_speed_untouched_outside_dry(self) -> None:
        """A cool-mode frame reports the fan speed the unit actually sent."""
        status = self.device.process_message(_make_c0_frame({2: 0x20, 3: 0x3C}))
        assert status[DeviceAttributes.fan_speed] == 0x3C

    def test_capabilities_is_empty(self) -> None:
        """No capability report exists, so consumers fall back to their defaults."""
        assert self.device.capabilities == {}

    def test_temperature_step_defaults_to_half_degree(self) -> None:
        """temperature_step matches the half-degree 0x0003 encoding."""
        assert self.device.temperature_step == 0.5

    def test_set_customize_overrides_temperature_step(self) -> None:
        """A customize payload can override the reported temperature step."""
        self.device.set_customize('{"temperature_step": 1}')
        assert self.device.temperature_step == 1

    def test_set_customize_ignores_invalid_json(self) -> None:
        """Malformed customize leaves the default step in place."""
        self.device.set_customize("not json")
        assert self.device.temperature_step == 0.5

    @pytest.mark.parametrize(
        ("value", "expected"),
        [(True, 100), (False, 0), (40, 40)],
    )
    def test_set_screen_display(self, value: bool | int, expected: int) -> None:
        """Switch values map onto the brightness extremes; ints pass through."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.screen_display, value)
        cmd = mock_send.call_args[0][0]
        assert cmd._params[_PROP_SCREEN_DISPLAY] == bytearray([expected])

    def test_set_prompt_tone_notifies_consumers(self) -> None:
        """prompt_tone has no readback, so the flag is pushed out immediately."""
        with patch.object(self.device, "update_all") as mock_update:
            self.device.set_attribute(DeviceAttributes.prompt_tone, False)
        mock_update.assert_called_once_with({"prompt_tone": False})

    def test_wind_angle_options(self) -> None:
        """Both deflector axes advertise their selectable position names."""
        assert self.device.wind_ud_angles == [
            "off",
            "up",
            "up_mid",
            "middle",
            "down_mid",
            "down",
        ]
        assert self.device.wind_lr_angles == [
            "off",
            "left",
            "left_mid",
            "middle",
            "right_mid",
            "right",
        ]

    def test_wind_angles_are_reported_as_names(self) -> None:
        """C0 deflector bytes are translated into position names."""
        status = self.device.process_message(_make_c0_frame({19: 1, 20: 25}))
        assert status[DeviceAttributes.wind_ud_angle] == "up"
        assert status[DeviceAttributes.wind_lr_angle] == "left_mid"

    def test_unknown_wind_angle_reports_none(self) -> None:
        """A position outside the named steps has no name to report."""
        status = self.device.process_message(_make_c0_frame({19: 7}))
        assert status[DeviceAttributes.wind_ud_angle] is None

    @pytest.mark.parametrize(
        ("attr", "value", "expected"),
        [
            (DeviceAttributes.wind_ud_angle, "middle", [50, 0xF0]),
            (DeviceAttributes.wind_ud_angle, "down", [100, 0xF0]),
            (DeviceAttributes.wind_lr_angle, "left", [0xF0, 1]),
            (DeviceAttributes.wind_lr_angle, 75, [0xF0, 75]),
        ],
    )
    def test_set_wind_angle(
        self,
        attr: DeviceAttributes,
        value: str | int,
        expected: list[int],
    ) -> None:
        """Both axes are always sent; the untouched one keeps its position."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(attr, value)
        cmd = mock_send.call_args[0][0]
        assert cmd._params[_PROP_DEFLECTOR_ANGLE] == bytearray(expected)

    def test_set_wind_angle_resends_other_axis_position(self) -> None:
        """The axis that is not being changed keeps its current position."""
        self.device.process_message(_make_c0_frame({19: 25, 20: 75}))
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.wind_ud_angle, "middle")
        cmd = mock_send.call_args[0][0]
        assert cmd._params[_PROP_DEFLECTOR_ANGLE] == bytearray([50, 75])

    def test_wind_angle_auto_reads_as_none(self) -> None:
        """0xF0, the device's own auto position, is not a selectable option."""
        status = self.device.process_message(_make_c0_frame({19: 0xF0, 20: 0xF0}))
        assert status[DeviceAttributes.wind_ud_angle] is None
        assert status[DeviceAttributes.wind_lr_angle] is None

    def test_b0_ack_updates_wind_angles(self) -> None:
        """A 0x0A set ack updates both angles, so the UI need not wait for a poll."""
        # FIVE pack: [param_lo, param_hi, 0x00, length, *value]
        body = [0xB0, 0x01, 0x0A, 0x00, 0x00, 0x02, 25, 75]
        frame = bytes(_assemble_frame(body, 0x0002))
        status = self.device.process_message(frame)
        assert status[DeviceAttributes.wind_ud_angle] == "up_mid"
        assert status[DeviceAttributes.wind_lr_angle] == "right_mid"

    def test_breezeless_direction_round_trip(self) -> None:
        """0x70 carries the direction; C0 body[24] bits 4-5 report it back."""
        status = self.device.process_message(_make_c0_frame({18: 0x01, 24: 0x2A}))
        assert status[DeviceAttributes.breezeless] == 1
        assert status[DeviceAttributes.breezeless_direction] == "left"
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.breezeless_direction, "right")
            cmd = mock_send.call_args[0][0]
        assert cmd._params[_PROP_BREEZELESS_DIRECTION] == bytearray([3])

    def test_breezeless_direction_rejects_unknown_name(self) -> None:
        """An unrecognised direction sends nothing."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.breezeless_direction, "up")
        mock_send.assert_not_called()

    def test_set_wind_angle_rejects_unknown_name(self) -> None:
        """An unrecognised position name sends nothing."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.wind_ud_angle, "sideways")
        mock_send.assert_not_called()
