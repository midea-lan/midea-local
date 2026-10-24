"""Test the AC device on Toshiba IoLife units."""

from unittest.mock import MagicMock, patch

import pytest

from midealocal.base_classes.climate import MideaPreset
from midealocal.const import ProtocolVersion
from midealocal.const.climate_exceptions import AC_EXCEPTIONS
from midealocal.devices.ac import (
    DeviceHVACMode,
    MideaACDevice,
)
from midealocal.devices.ac.message import (
    ACFanSpeed,
    DeviceAttributes,
    MessageQuery,
    MessageToshibaSet,
    ToshibaPropertyTags,
)
from midealocal.message import ListTypes

from .message_ac_toshiba_test import CAPTURED_C0_LEFT, toshiba_frame

# A 32-character serial: manufacturer code 0008, then sn8 0000000F at [9:17].
TOSHIBA_SERIAL = "000800000" + "0000000F" + "0" * 15


def c0_frame(overrides: dict[int, int] | None = None) -> bytes:
    """Return a C0 status frame, all zero but for the given body bytes."""
    body = [0] * 28
    body[0] = 0xC0
    for index, value in (overrides or {}).items():
        body[index] = value
    return bytes(toshiba_frame(body))


def b0_frame(params: list[int]) -> bytes:
    """Return a B0 property frame carrying the given FIVE-packed parameters."""
    return bytes(toshiba_frame([0xB0, 1, *params]))


class TestToshibaACDevice:
    """Test MideaACDevice on a Toshiba IoLife unit."""

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Create a Toshiba IoLife AC device with sending stubbed out."""
        self.device = MideaACDevice(
            name="Toshiba AC",
            device_id=1,
            ip_address="192.168.1.1",
            port=6444,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="0000000F",
            subtype=0,
            customize="",
            serial_number=TOSHIBA_SERIAL,
        )
        self.send = MagicMock()
        self.device.build_send = self.send  # type: ignore[method-assign]

    def sent(self) -> dict[int, bytearray]:
        """Return the properties of the one Toshiba set command sent."""
        self.send.assert_called_once()
        message = self.send.call_args[0][0]
        assert isinstance(message, MessageToshibaSet)
        return message._params

    def test_detected_from_serial(self) -> None:
        """The manufacturer code comes from the serial and selects Toshiba."""
        assert self.device.manufacturer_code == "0008"
        assert self.device._is_toshiba is True
        assert self.device._appliance_query is False

    def test_attributes(self) -> None:
        """Only attributes the protocol carries are exposed."""
        attributes = self.device.attributes
        assert attributes[DeviceAttributes.min_temperature] == 16.0
        assert attributes[DeviceAttributes.max_temperature] == 32.0
        assert attributes[DeviceAttributes.dehumidify] == 0
        assert attributes[DeviceAttributes.breezeless_direction] is None
        assert attributes[DeviceAttributes.screen_display] is False
        assert attributes[DeviceAttributes.indoor_humidity] is None
        assert attributes[DeviceAttributes.wind_ud_angle] is None
        assert DeviceAttributes.sound not in attributes
        assert DeviceAttributes.fresh_air_power not in attributes
        assert DeviceAttributes.boost_mode not in attributes

    def test_climate_capabilities(self) -> None:
        """Every mode is offered; filter reset is not."""
        assert self.device.hvac_modes == set(DeviceHVACMode)
        assert self.device.is_filter_reset_supported is False
        assert self.device.preset_modes == [
            MideaPreset.NONE,
            MideaPreset.COMFORT,
            MideaPreset.ECO,
        ]
        assert self.device.breezeless_directions == ["off", "full", "left", "right"]

    def test_build_query(self) -> None:
        """A single standard query is sent in a 0x55 frame."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)
        assert queries[0].serialize()[0] == ListTypes.X55

    def test_reset_filter_sends_nothing(self) -> None:
        """The protocol has no filter reset."""
        self.device.reset_filter()
        self.send.assert_not_called()

    def test_process_captured_status(self) -> None:
        """A captured status frame reaches the climate read side."""
        status = self.device.process_message(bytes(CAPTURED_C0_LEFT))
        assert status[DeviceAttributes.wind_lr_angle] == "left_mid"
        assert status[DeviceAttributes.wind_ud_angle] == "up"
        assert status[DeviceAttributes.breezeless_direction] == "left"
        assert self.device.hvac_mode() == DeviceHVACMode.DRY
        assert self.device.current_temperature() == pytest.approx(27.8)
        assert self.device.target_temperature() == 26.5
        assert self.device.current_humidity() == 48

    def test_process_unparseable_frame(self) -> None:
        """A frame without a known body updates nothing."""
        assert self.device.process_message(bytes(toshiba_frame([0x99]))) == {}

    def test_auto_wind_angle_reads_as_none(self) -> None:
        """0xF0, the deflector placing itself, is not a named position."""
        status = self.device.process_message(c0_frame({19: 0xF0}))
        assert status[DeviceAttributes.wind_ud_angle] is None

    def test_b0_ack_updates_wind_angles(self) -> None:
        """A deflector echo in a set acknowledgement updates both axes."""
        frame = b0_frame([0x0A, 0x00, 0x00, 0x02, 50, 100])
        status = self.device.process_message(frame)
        assert status[DeviceAttributes.wind_ud_angle] == "middle"
        assert status[DeviceAttributes.wind_lr_angle] == "right"

    @pytest.mark.parametrize(
        ("dehumidify", "fan_mode"),
        [(1, ACFanSpeed.LOW), (2, ACFanSpeed.HIGH), (4, ACFanSpeed.AUTO)],
    )
    def test_dry_sub_mode_reported_as_fan(
        self,
        dehumidify: int,
        fan_mode: ACFanSpeed,
    ) -> None:
        """In dry mode the sub-mode stands in for the fan speed."""
        status = self.device.process_message(
            c0_frame({2: 0x30, 3: 30, 21: dehumidify << 1}),
        )
        assert status[DeviceAttributes.fan_speed] == fan_mode
        assert self.device.fan_mode == fan_mode

    def test_clothes_drying_leaves_the_fan_speed_alone(self) -> None:
        """Clothes drying (sub-mode 3) has no fan equivalent."""
        status = self.device.process_message(c0_frame({2: 0x30, 3: 30, 21: 3 << 1}))
        assert status[DeviceAttributes.fan_speed] == 30

    def test_fan_speed_untouched_outside_dry(self) -> None:
        """Outside dry the reported fan speed is used as is."""
        status = self.device.process_message(c0_frame({2: 0x20, 3: 30, 21: 4 << 1}))
        assert status[DeviceAttributes.fan_speed] == 30

    @pytest.mark.parametrize(
        ("attr", "value", "tag", "payload"),
        [
            (DeviceAttributes.power, True, ToshibaPropertyTags.power, [1]),
            (DeviceAttributes.power, False, ToshibaPropertyTags.power, [0]),
            (DeviceAttributes.eco_mode, True, ToshibaPropertyTags.eco_mode, [1]),
            (DeviceAttributes.anion, True, ToshibaPropertyTags.anion, [1]),
            (DeviceAttributes.energy_save, 1, ToshibaPropertyTags.energy_save, [1]),
            (DeviceAttributes.comfort_mode, 1, ToshibaPropertyTags.comfort_mode, [1]),
            (DeviceAttributes.fan_speed, 50, ToshibaPropertyTags.fan_speed, [50]),
            (
                DeviceAttributes.swing_vertical,
                True,
                ToshibaPropertyTags.swing_vertical,
                [1],
            ),
            (
                DeviceAttributes.swing_horizontal,
                False,
                ToshibaPropertyTags.swing_horizontal,
                [0],
            ),
            (DeviceAttributes.dehumidify, 2, ToshibaPropertyTags.dehumidify, [2]),
            (DeviceAttributes.breezeless, True, ToshibaPropertyTags.breezeless, [1]),
            (
                DeviceAttributes.target_temperature,
                22.5,
                ToshibaPropertyTags.target_temperature,
                [45],
            ),
            (
                DeviceAttributes.screen_display,
                True,
                ToshibaPropertyTags.screen_display,
                [100],
            ),
            (
                DeviceAttributes.screen_display,
                False,
                ToshibaPropertyTags.screen_display,
                [0],
            ),
            (
                DeviceAttributes.screen_display,
                40,
                ToshibaPropertyTags.screen_display,
                [40],
            ),
            (
                DeviceAttributes.breezeless_direction,
                "right",
                ToshibaPropertyTags.breezeless_direction,
                [3],
            ),
        ],
    )
    def test_set_single_property(
        self,
        attr: DeviceAttributes,
        value: bool | float | str,
        tag: ToshibaPropertyTags,
        payload: list[int],
    ) -> None:
        """Single-property attributes write their property."""
        self.device.set_attribute(attr, value)
        assert self.sent() == {tag: bytearray(payload)}

    @pytest.mark.parametrize(
        "attr",
        [
            DeviceAttributes.indoor_temperature,
            DeviceAttributes.outdoor_temperature,
            DeviceAttributes.indoor_humidity,
            DeviceAttributes.cleaning,
            DeviceAttributes.full_dust,
            DeviceAttributes.error_code,
            DeviceAttributes.min_temperature,
        ],
    )
    def test_read_only_attribute_sends_nothing(self, attr: DeviceAttributes) -> None:
        """Read-only attributes are ignored without a warning."""
        with patch("midealocal.devices.ac._LOGGER") as logger:
            self.device.set_attribute(attr, 1)
        self.send.assert_not_called()
        logger.warning.assert_not_called()

    @pytest.mark.parametrize(
        ("attr", "value"),
        [
            ("no_such_attribute", True),
            (DeviceAttributes.breezeless_direction, "sideways"),
        ],
    )
    def test_unsupported_value_is_refused(
        self,
        attr: str,
        value: bool | str,
    ) -> None:
        """Attributes and values with no property write are refused."""
        with patch("midealocal.devices.ac._LOGGER") as logger:
            self.device.set_attribute(attr, value)
        self.send.assert_not_called()
        logger.warning.assert_called_once()

    def test_prompt_tone_is_local(self) -> None:
        """prompt_tone is mirrored locally and sends nothing."""
        with patch.object(self.device, "update_all") as update_all:
            self.device.set_attribute(DeviceAttributes.prompt_tone, False)
        self.send.assert_not_called()
        update_all.assert_called_once_with({"prompt_tone": False})
        assert self.device.attributes[DeviceAttributes.prompt_tone] is False

    def test_prompt_tone_off_mutes_every_command(self) -> None:
        """Without the prompt tone, each command leads with a buzzer mute."""
        self.device.set_attribute(DeviceAttributes.prompt_tone, False)
        self.device.set_attribute(DeviceAttributes.power, True)
        sent = self.sent()
        assert list(sent) == [ToshibaPropertyTags.buzzer, ToshibaPropertyTags.power]
        assert sent[ToshibaPropertyTags.buzzer] == bytearray([0])

    def test_set_mode_powers_on(self) -> None:
        """A mode write carries the power flag, so the unit runs in that mode."""
        self.device.set_hvac_mode(DeviceHVACMode.COOL)
        assert self.sent() == {
            ToshibaPropertyTags.power: bytearray([1]),
            ToshibaPropertyTags.mode: bytearray([2]),
        }

    def test_set_hvac_mode_off_powers_off(self) -> None:
        """The off HVAC mode is a power write."""
        self.device.set_hvac_mode(DeviceHVACMode.OFF)
        assert self.sent() == {ToshibaPropertyTags.power: bytearray([0])}

    def test_entering_dry_selects_the_recommended_sub_mode(self) -> None:
        """Entering dry starts from the recommended sub-mode."""
        self.device.process_message(c0_frame({2: 0x20}))
        self.device.set_attribute(DeviceAttributes.mode, 3)
        assert self.sent()[ToshibaPropertyTags.dehumidify] == bytearray([4])

    def test_reselecting_dry_keeps_the_sub_mode(self) -> None:
        """Re-selecting dry while in dry leaves the chosen sub-mode alone."""
        self.device.process_message(c0_frame({2: 0x30}))
        self.device.set_attribute(DeviceAttributes.mode, 3)
        assert ToshibaPropertyTags.dehumidify not in self.sent()

    @pytest.mark.parametrize(
        ("fan_mode", "dehumidify"),
        [
            (ACFanSpeed.SILENT, 1),
            (ACFanSpeed.LOW, 1),
            (ACFanSpeed.MEDIUM, 4),
            (ACFanSpeed.HIGH, 2),
            (ACFanSpeed.FULL, 2),
            (ACFanSpeed.AUTO, 4),
        ],
    )
    def test_fan_mode_in_dry_sets_the_sub_mode(
        self,
        fan_mode: ACFanSpeed,
        dehumidify: int,
    ) -> None:
        """In dry mode a fan setting picks the nearest dehumidify sub-mode."""
        self.device.process_message(c0_frame({2: 0x30}))
        self.device.set_fan_mode(fan_mode)
        assert self.sent() == {ToshibaPropertyTags.dehumidify: bytearray([dehumidify])}

    def test_set_target_temperature(self) -> None:
        """Without a mode only the setpoint is written."""
        self.device.set_target_temperature(23.5, None)
        assert self.sent() == {
            ToshibaPropertyTags.target_temperature: bytearray([47]),
        }

    def test_set_target_temperature_with_mode(self) -> None:
        """With a mode the unit is also powered on in that mode."""
        self.device.set_target_temperature(24.0, DeviceHVACMode.HEAT)
        assert self.sent() == {
            ToshibaPropertyTags.target_temperature: bytearray([48]),
            ToshibaPropertyTags.power: bytearray([1]),
            ToshibaPropertyTags.mode: bytearray([4]),
        }

    def test_set_target_temperature_with_off(self) -> None:
        """The off mode powers the unit off."""
        self.device.set_target_temperature(24.0, DeviceHVACMode.OFF)
        assert self.sent()[ToshibaPropertyTags.power] == bytearray([0])

    def test_set_swing_mode(self) -> None:
        """Both swing axes are written together."""
        self.device.set_swing_mode(self.device.swing_modes[2])  # horizontal
        assert self.sent() == {
            ToshibaPropertyTags.swing_vertical: bytearray([0]),
            ToshibaPropertyTags.swing_horizontal: bytearray([1]),
        }

    def test_set_preset_mode(self) -> None:
        """Presets map onto the eco and comfort flags."""
        self.device.set_preset_mode(MideaPreset.ECO)
        assert self.sent() == {ToshibaPropertyTags.eco_mode: bytearray([1])}

    @pytest.mark.parametrize(
        ("attr", "value", "payload"),
        [
            (DeviceAttributes.wind_ud_angle, "middle", [50, 75]),
            (DeviceAttributes.wind_lr_angle, "right", [25, 100]),
            (DeviceAttributes.wind_ud_angle, 30, [30, 75]),
        ],
    )
    def test_set_wind_angle(
        self,
        attr: DeviceAttributes,
        value: str | int,
        payload: list[int],
    ) -> None:
        """Deflector writes carry both axes, the other one as last reported."""
        self.device.process_message(c0_frame({19: 25, 20: 75}))
        self.device.set_attribute(attr, value)
        assert self.sent() == {ToshibaPropertyTags.wind_angle: bytearray(payload)}

    @pytest.mark.parametrize("other", [0xF0, 30])
    def test_set_wind_angle_resends_unnamed_positions(self, other: int) -> None:
        """Auto and between-step positions are resent as reported."""
        self.device.process_message(c0_frame({19: 25, 20: other}))
        assert self.device.attributes[DeviceAttributes.wind_lr_angle] is None
        self.device.set_attribute(DeviceAttributes.wind_ud_angle, "down")
        assert self.sent() == {
            ToshibaPropertyTags.wind_angle: bytearray([100, other]),
        }

    def test_back_to_back_wind_angle_writes(self) -> None:
        """A second write before the next status keeps the first one's axis."""
        self.device.process_message(c0_frame({19: 25, 20: 75}))
        self.device.set_attribute(DeviceAttributes.wind_ud_angle, "down")
        self.send.reset_mock()
        self.device.set_attribute(DeviceAttributes.wind_lr_angle, "left")
        assert self.sent() == {
            ToshibaPropertyTags.wind_angle: bytearray([100, 1]),
        }

    def test_b0_ack_tracks_wind_angles(self) -> None:
        """Angles echoed in a B0 acknowledgement are resent from then on."""
        self.device.process_message(b0_frame([0x0A, 0x00, 0x00, 0x02, 50, 30]))
        self.device.set_attribute(DeviceAttributes.wind_ud_angle, "up")
        assert self.sent() == {ToshibaPropertyTags.wind_angle: bytearray([1, 30])}

    def test_set_wind_angle_before_any_status_is_refused(self) -> None:
        """Without a reported position for the other axis nothing is sent."""
        with patch("midealocal.devices.ac._LOGGER") as logger:
            self.device.set_attribute(DeviceAttributes.wind_ud_angle, "middle")
        self.send.assert_not_called()
        logger.warning.assert_called_once()

    @pytest.mark.parametrize("value", ["sideways", 101, None])
    def test_set_wind_angle_rejects_bad_values(self, value: str | int | None) -> None:
        """Unknown names and out-of-range angles are refused."""
        self.device.process_message(c0_frame({19: 25, 20: 75}))
        self.device.set_attribute(DeviceAttributes.wind_ud_angle, value)  # type: ignore[arg-type]
        self.send.assert_not_called()

    def test_set_self_clean(self) -> None:
        """self_clean writes both clean flags and is mirrored locally."""
        with patch.object(self.device, "update_all") as update_all:
            self.device.set_attribute(DeviceAttributes.self_clean, True)
        assert self.sent() == {ToshibaPropertyTags.clean: bytearray([0, 1])}
        update_all.assert_called_once_with({"self_clean": True})
        assert self.device.attributes[DeviceAttributes.self_clean] is True

    def test_set_clean_manual_keeps_self_clean(self) -> None:
        """Writing one clean flag resends the other as it is."""
        self.device.set_attribute(DeviceAttributes.self_clean, True)
        self.send.reset_mock()
        self.device.set_attribute(DeviceAttributes.clean_manual, True)
        assert self.sent() == {ToshibaPropertyTags.clean: bytearray([1, 1])}

    def test_status_does_not_clear_self_clean(self) -> None:
        """self_clean has no readback, so a status frame leaves it alone."""
        self.device.set_attribute(DeviceAttributes.self_clean, True)
        status = self.device.process_message(c0_frame())
        assert DeviceAttributes.self_clean not in status
        assert self.device.attributes[DeviceAttributes.self_clean] is True


def test_model_exception_overrides_the_setpoint_range() -> None:
    """A per-model exception wins over the protocol's setpoint range."""
    with patch.dict(
        AC_EXCEPTIONS,
        {"0000000F": {"min_temperature": 18.0, "max_temperature": 30.0}},
    ):
        device = MideaACDevice(
            name="Toshiba AC",
            device_id=1,
            ip_address="192.168.1.1",
            port=6444,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="0000000F",
            subtype=0,
            customize="",
            serial_number=TOSHIBA_SERIAL,
        )
    assert device.min_temperature() == 18.0
    assert device.max_temperature() == 30.0


def test_non_toshiba_serial_keeps_the_midea_protocol() -> None:
    """A Midea serial leaves the device on the standard protocol."""
    device = MideaACDevice(
        name="Midea AC",
        device_id=1,
        ip_address="192.168.1.1",
        port=6444,
        token="AA",
        key="BB",
        device_protocol=ProtocolVersion.V3,
        model="00000Q11",
        subtype=0,
        customize="",
        serial_number="0000" + "0" * 28,
    )
    assert device._is_toshiba is False
    assert device.breezeless_directions == []
    assert len(device.build_query()) > 1
