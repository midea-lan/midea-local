"""Test ED Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.ed import DeviceAttributes, MideaEDDevice
from midealocal.devices.ed.message import (
    MessageEDBase,
    MessageOldSet,
    MessageQuery,
    MessageQuery01,
    MessageQuery04,
    MessageQuery05,
    MessageQuery06,
    MessageQuery07,
    MessageQuery09,
    MessageQueryFF,
)

TEST_AUTH_VALUE = "AA"


class TestMideaEDDevice:
    """Test Midea ED Device."""

    device: MideaEDDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea ed Device setup."""
        self.device = MideaEDDevice(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.100",
            port=6444,
            token=TEST_AUTH_VALUE,
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="test_model",
            subtype=1,
            customize="test_customize",
        )

    def test_initial_attributes(self) -> None:
        """Test initial attributes."""
        assert not self.device.attributes[DeviceAttributes.power]
        assert self.device.attributes[DeviceAttributes.water_consumption] is None
        assert self.device.attributes[DeviceAttributes.in_tds] is None
        assert self.device.attributes[DeviceAttributes.out_tds] is None
        assert self.device.attributes[DeviceAttributes.filter1] is None
        assert self.device.attributes[DeviceAttributes.filter2] is None
        assert self.device.attributes[DeviceAttributes.filter3] is None
        assert self.device.attributes[DeviceAttributes.life1] is None
        assert self.device.attributes[DeviceAttributes.life2] is None
        assert self.device.attributes[DeviceAttributes.life3] is None
        assert not self.device.attributes[DeviceAttributes.child_lock]

    def test_process_message(self) -> None:
        """Test process message."""
        with patch("midealocal.devices.ed.MessageEDResponse") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.protocol_version = ProtocolVersion.V3
            mock_message.power = True
            mock_message.water_consumption = 123
            mock_message.in_tds = 200
            mock_message.out_tds = 5
            mock_message.filter1 = 30
            mock_message.filter2 = 20
            mock_message.filter3 = 10
            mock_message.life1 = 2
            mock_message.life2 = 3
            mock_message.life3 = 4
            mock_message.child_lock = True
            new_status = self.device.process_message(b"")
            assert new_status[DeviceAttributes.power.value]
            assert new_status[DeviceAttributes.water_consumption.value] == 123
            assert new_status[DeviceAttributes.in_tds.value] == 200
            assert new_status[DeviceAttributes.out_tds.value] == 5
            assert new_status[DeviceAttributes.filter1.value] == 30
            assert new_status[DeviceAttributes.filter2.value] == 20
            assert new_status[DeviceAttributes.filter3.value] == 10
            assert new_status[DeviceAttributes.life1.value] == 2
            assert new_status[DeviceAttributes.life2.value] == 3
            assert new_status[DeviceAttributes.life3.value] == 4

            mock_message.child_lock = False
            mock_message.water_consumption = 456
            mock_message.in_tds = 300
            mock_message.out_tds = 15
            mock_message.filter1 = 15
            mock_message.life3 = 15
            new_status = self.device.process_message(b"")
            assert not new_status[DeviceAttributes.child_lock.value]
            assert new_status[DeviceAttributes.water_consumption.value] == 456
            assert new_status[DeviceAttributes.in_tds.value] == 300
            assert new_status[DeviceAttributes.out_tds.value] == 15
            assert new_status[DeviceAttributes.filter1.value] == 15
            assert new_status[DeviceAttributes.life3.value] == 15

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 3
        assert isinstance(queries[0], MessageQuery)
        assert isinstance(queries[1], MessageQuery01)
        assert isinstance(queries[2], MessageQueryFF)

    @pytest.mark.parametrize(
        ("subtype", "expected_query"),
        [
            (309, MessageQuery04),
            (316, MessageQuery05),
            (290, MessageQuery06),
            (288, MessageQuery07),
            (775, MessageQuery01),
        ],
    )
    def test_build_query_subtypes(
        self,
        subtype: int,
        expected_query: type[MessageEDBase],
    ) -> None:
        """Test build query for subtype specific queries."""
        device = MideaEDDevice(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.100",
            port=6444,
            token=TEST_AUTH_VALUE,
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="test_model",
            subtype=subtype,
            customize="test_customize",
        )
        queries = device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], expected_query)

    def test_set_attribute(self) -> None:
        """Test set attribute."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.power, True)
            mock_build_send.assert_called_once()

            self.device.set_attribute(DeviceAttributes.child_lock, True)
            mock_build_send.assert_called()

    def test_tea_bar_attributes_are_model_specific(self) -> None:
        """Expose tea bar status attributes only for the verified model."""
        tea_bar = MideaEDDevice(
            name="Tea Bar",
            device_id=2,
            ip_address="192.0.2.1",
            port=6444,
            token=TEST_AUTH_VALUE,
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="63000622",
            subtype=395,
            customize="",
        )
        assert tea_bar.attributes[DeviceAttributes.current_temperature] is None
        assert tea_bar.attributes[DeviceAttributes.target_temperature] is None
        assert tea_bar.attributes[DeviceAttributes.heating] is False
        assert tea_bar.attributes[DeviceAttributes.dispensing] is False
        assert tea_bar.attributes[DeviceAttributes.boil_temperature] is None
        assert tea_bar.attributes[DeviceAttributes.boiling] is False
        assert tea_bar.attributes[DeviceAttributes.keep_warm] is False
        assert tea_bar.attributes[DeviceAttributes.keep_warm_time] is None
        assert tea_bar.attributes[DeviceAttributes.keep_warm_remaining] is None
        assert tea_bar.attributes[DeviceAttributes.sleep] is False
        assert tea_bar.attributes[DeviceAttributes.screen_display] is True
        assert tea_bar.attributes[DeviceAttributes.cooling] is False
        assert tea_bar.attributes[DeviceAttributes.lack_water] is False
        assert tea_bar.attributes[DeviceAttributes.standby] is False
        assert tea_bar.attributes[DeviceAttributes.hot_water_dispensing] is False
        assert tea_bar.attributes[DeviceAttributes.fault_code] == 0
        assert tea_bar.attributes[DeviceAttributes.fault] is False
        assert DeviceAttributes.current_temperature not in self.device.attributes
        assert DeviceAttributes.target_temperature not in self.device.attributes
        assert DeviceAttributes.heating not in self.device.attributes
        assert DeviceAttributes.dispensing not in self.device.attributes
        assert DeviceAttributes.boil_temperature not in self.device.attributes
        assert DeviceAttributes.boiling not in self.device.attributes
        assert DeviceAttributes.keep_warm not in self.device.attributes
        assert DeviceAttributes.keep_warm_time not in self.device.attributes
        assert DeviceAttributes.keep_warm_remaining not in self.device.attributes
        assert DeviceAttributes.sleep not in self.device.attributes
        assert DeviceAttributes.screen_display not in self.device.attributes
        assert DeviceAttributes.cooling not in self.device.attributes
        assert DeviceAttributes.lack_water not in self.device.attributes
        assert DeviceAttributes.standby not in self.device.attributes
        assert DeviceAttributes.hot_water_dispensing not in self.device.attributes
        assert DeviceAttributes.fault_code not in self.device.attributes
        assert DeviceAttributes.fault not in self.device.attributes

        wrong_subtype = MideaEDDevice(
            name="Same model, different subtype",
            device_id=4,
            ip_address="192.0.2.4",
            port=6444,
            token=TEST_AUTH_VALUE,
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="63000622",
            subtype=394,
            customize="",
        )
        for attribute in (
            DeviceAttributes.current_temperature,
            DeviceAttributes.target_temperature,
            DeviceAttributes.heating,
            DeviceAttributes.dispensing,
            DeviceAttributes.boil_temperature,
            DeviceAttributes.boiling,
            DeviceAttributes.keep_warm,
            DeviceAttributes.keep_warm_time,
            DeviceAttributes.keep_warm_remaining,
            DeviceAttributes.sleep,
            DeviceAttributes.screen_display,
            DeviceAttributes.cooling,
            DeviceAttributes.lack_water,
            DeviceAttributes.standby,
            DeviceAttributes.hot_water_dispensing,
            DeviceAttributes.fault_code,
            DeviceAttributes.fault,
        ):
            assert attribute not in wrong_subtype.attributes
        with patch.object(wrong_subtype, "build_send") as mock_build_send:
            wrong_subtype.set_attribute(DeviceAttributes.boil_temperature, 80)
            wrong_subtype.set_attribute(DeviceAttributes.keep_warm, True)
        mock_build_send.assert_not_called()

    def test_tea_bar_query_is_model_specific(self) -> None:
        """Use body-06 queries only for the verified subtype and model."""
        tea_bar = MideaEDDevice(
            name="Tea Bar",
            device_id=2,
            ip_address="192.0.2.1",
            port=6444,
            token=TEST_AUTH_VALUE,
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="63000622",
            subtype=395,
            customize="",
        )
        queries = tea_bar.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery06)

        other_model = MideaEDDevice(
            name="Other subtype-395 appliance",
            device_id=3,
            ip_address="192.0.2.2",
            port=6444,
            token=TEST_AUTH_VALUE,
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="63000000",
            subtype=395,
            customize="",
        )
        queries = other_model.build_query()
        assert len(queries) == 3
        assert isinstance(queries[0], MessageQuery)
        assert DeviceAttributes.current_temperature not in other_model.attributes

        with patch("midealocal.devices.ed.MessageEDResponse") as response:
            other_model.process_message(b"")
        response.assert_called_once_with(b"", 0)

    @pytest.mark.parametrize("target", [80, 80.0])
    def test_tea_bar_set_target_starts_heating(self, target: float) -> None:
        """Set target temperature with the official compound start command."""
        tea_bar = MideaEDDevice(
            name="Tea Bar",
            device_id=2,
            ip_address="192.0.2.1",
            port=6444,
            token=TEST_AUTH_VALUE,
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="63000622",
            subtype=395,
            customize="",
        )
        tea_bar._attributes[DeviceAttributes.current_temperature] = 60

        with patch.object(tea_bar, "build_send") as mock_build_send:
            tea_bar.set_attribute(DeviceAttributes.boil_temperature, target)

        message = mock_build_send.call_args.args[0]
        assert message.body == bytearray(
            [
                0x15,
                0x01,
                0x02,
                0x01,
                0x04,
                0x50,
                0x0A,
                0x00,
                0x05,
                0x04,
                0x01,
                0x00,
                0x00,
            ],
        )

    def test_tea_bar_status_updates_control_entities(self) -> None:
        """Mirror reported target and heating state into writable controls."""
        tea_bar = MideaEDDevice(
            name="Tea Bar",
            device_id=2,
            ip_address="192.0.2.1",
            port=6444,
            token=TEST_AUTH_VALUE,
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="63000622",
            subtype=395,
            customize="",
        )
        with patch("midealocal.devices.ed.MessageEDResponse") as response:
            message = response.return_value
            message.target_temperature = 80
            message.heating = True
            status = tea_bar.process_message(b"")

        assert status[DeviceAttributes.boil_temperature] == 80
        assert status[DeviceAttributes.boiling] is True
        assert tea_bar.attributes[DeviceAttributes.boil_temperature] == 80
        assert tea_bar.attributes[DeviceAttributes.boiling] is True

    def test_tea_bar_heating_switch_uses_official_tea_heat_command(self) -> None:
        """Use the model-specific App command for normal 100-degree boiling."""
        tea_bar = MideaEDDevice(
            name="Tea Bar",
            device_id=2,
            ip_address="192.0.2.1",
            port=6444,
            token=TEST_AUTH_VALUE,
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="63000622",
            subtype=395,
            customize="",
        )
        tea_bar._attributes[DeviceAttributes.current_temperature] = 60
        tea_bar._attributes[DeviceAttributes.boil_temperature] = 80

        with patch.object(tea_bar, "build_send") as mock_build_send:
            tea_bar.set_attribute(DeviceAttributes.boiling, True)
            start_message = mock_build_send.call_args.args[0]
            assert start_message.body == bytearray(
                [
                    0x15,
                    0x01,
                    0x02,
                    0x01,
                    0x04,
                    0x64,
                    0x0A,
                    0x00,
                    0x05,
                    0x04,
                    0x01,
                    0x00,
                    0x00,
                ],
            )

            tea_bar.set_attribute(DeviceAttributes.boiling, False)
            stop_message = mock_build_send.call_args.args[0]
            assert stop_message.body == bytearray(
                [
                    0x15,
                    0x01,
                    0x02,
                    0x01,
                    0x04,
                    0x64,
                    0x0A,
                    0x00,
                    0x05,
                    0x04,
                    0x00,
                    0x00,
                    0x00,
                ],
            )

    @pytest.mark.parametrize(("locked", "raw_value"), [(True, 0x01), (False, 0x00)])
    def test_tea_bar_child_lock_uses_official_lua_command(
        self,
        locked: bool,
        raw_value: int,
    ) -> None:
        """Encode the model-specific official child-lock command."""
        tea_bar = MideaEDDevice(
            name="Tea Bar",
            device_id=2,
            ip_address="192.0.2.1",
            port=6444,
            token=TEST_AUTH_VALUE,
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="63000622",
            subtype=395,
            customize="",
        )

        with patch.object(tea_bar, "build_send") as mock_build_send:
            tea_bar.set_attribute(DeviceAttributes.child_lock, locked)

        message = mock_build_send.call_args.args[0]
        assert message.body == bytearray(
            [0x15, 0x01, 0x01, 0x01, 0x02, raw_value, 0x00, 0x00],
        )

    @pytest.mark.parametrize(
        ("attribute", "enabled", "expected"),
        [
            (
                DeviceAttributes.sleep,
                True,
                [0x15, 0x01, 0x01, 0x04, 0x01, 0x01, 0x00, 0x00],
            ),
            (
                DeviceAttributes.sleep,
                False,
                [0x15, 0x01, 0x01, 0x04, 0x01, 0x00, 0x00, 0x00],
            ),
            (
                DeviceAttributes.screen_display,
                True,
                [0x15, 0x01, 0x01, 0x04, 0x01, 0x00, 0x00, 0x00],
            ),
            (
                DeviceAttributes.screen_display,
                False,
                [0x15, 0x01, 0x01, 0x04, 0x01, 0x01, 0x00, 0x00],
            ),
            (
                DeviceAttributes.cooling,
                True,
                [0x15, 0x01, 0x01, 0x00, 0x05, 0x01, 0x00, 0x00],
            ),
            (
                DeviceAttributes.cooling,
                False,
                [0x15, 0x01, 0x01, 0x00, 0x05, 0x00, 0x00, 0x00],
            ),
        ],
    )
    def test_tea_bar_auxiliary_controls_use_official_lua_commands(
        self,
        attribute: DeviceAttributes,
        enabled: bool,
        expected: list[int],
    ) -> None:
        """Encode the model-specific screen and signal-cooling controls."""
        tea_bar = MideaEDDevice(
            name="Tea Bar",
            device_id=2,
            ip_address="192.0.2.1",
            port=6444,
            token=TEST_AUTH_VALUE,
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="63000622",
            subtype=395,
            customize="",
        )

        with patch.object(tea_bar, "build_send") as mock_build_send:
            tea_bar.set_attribute(attribute, enabled)

        assert mock_build_send.call_args.args[0].body == bytearray(expected)

    def test_tea_bar_rejects_stopping_cooling_while_dispensing(self) -> None:
        """Match the official App safety check for signal cooling."""
        tea_bar = MideaEDDevice(
            name="Tea Bar",
            device_id=2,
            ip_address="192.0.2.1",
            port=6444,
            token=TEST_AUTH_VALUE,
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="63000622",
            subtype=395,
            customize="",
        )
        tea_bar._attributes[DeviceAttributes.dispensing] = True

        with (
            patch.object(tea_bar, "build_send") as mock_build_send,
            pytest.raises(ValueError, match="cannot be stopped"),
        ):
            tea_bar.set_attribute(DeviceAttributes.cooling, False)
        mock_build_send.assert_not_called()

    @pytest.mark.parametrize("target", [39, 101])
    def test_tea_bar_rejects_unsafe_target(self, target: int) -> None:
        """Reject target temperatures outside the supported safe range."""
        tea_bar = MideaEDDevice(
            name="Tea Bar",
            device_id=2,
            ip_address="192.0.2.1",
            port=6444,
            token=TEST_AUTH_VALUE,
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="63000622",
            subtype=395,
            customize="",
        )
        tea_bar._attributes[DeviceAttributes.current_temperature] = 20

        with (
            patch.object(tea_bar, "build_send") as mock_build_send,
            pytest.raises(ValueError, match="must be between"),
        ):
            tea_bar.set_attribute(DeviceAttributes.boil_temperature, target)
        mock_build_send.assert_not_called()

    def test_tea_bar_rejects_target_not_above_current_temperature(self) -> None:
        """Match the official App preflight for a non-increasing target."""
        tea_bar = MideaEDDevice(
            name="Tea Bar",
            device_id=2,
            ip_address="192.0.2.1",
            port=6444,
            token=TEST_AUTH_VALUE,
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="63000622",
            subtype=395,
            customize="",
        )
        tea_bar._attributes[DeviceAttributes.current_temperature] = 70

        with (
            patch.object(tea_bar, "build_send") as mock_build_send,
            pytest.raises(ValueError, match="is not below target"),
        ):
            tea_bar.set_attribute(DeviceAttributes.boil_temperature, 70)
        mock_build_send.assert_not_called()

    def test_tea_bar_rejects_fractional_target_temperature(self) -> None:
        """Reject fractional targets instead of silently truncating them."""
        tea_bar = MideaEDDevice(
            name="Tea Bar",
            device_id=2,
            ip_address="192.0.2.1",
            port=6444,
            token=TEST_AUTH_VALUE,
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="63000622",
            subtype=395,
            customize="",
        )
        tea_bar._attributes[DeviceAttributes.current_temperature] = 20

        with (
            patch.object(tea_bar, "build_send") as mock_build_send,
            pytest.raises(ValueError, match="must be a whole number"),
        ):
            tea_bar.set_attribute(DeviceAttributes.boil_temperature, 80.5)
        mock_build_send.assert_not_called()

    def test_non_tea_bar_cannot_send_tea_bar_controls(self) -> None:
        """Never apply tea bar controls to another ED subtype."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.boil_temperature, 80)
            self.device.set_attribute(DeviceAttributes.boiling, True)
        mock_build_send.assert_not_called()

    def test_other_model_cannot_send_tea_bar_controls(self) -> None:
        """Never apply model-specific commands by subtype alone."""
        other_model = MideaEDDevice(
            name="Other subtype-395 appliance",
            device_id=3,
            ip_address="192.0.2.2",
            port=6444,
            token=TEST_AUTH_VALUE,
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="63000000",
            subtype=395,
            customize="",
        )

        with patch.object(other_model, "build_send") as mock_build_send:
            other_model.set_attribute(DeviceAttributes.boil_temperature, 80)
            other_model.set_attribute(DeviceAttributes.boiling, True)
            other_model.set_attribute(DeviceAttributes.keep_warm, True)
            other_model.set_attribute(DeviceAttributes.sleep, True)
            other_model.set_attribute(DeviceAttributes.screen_display, True)
            other_model.set_attribute(DeviceAttributes.cooling, True)
        mock_build_send.assert_not_called()

    def test_tea_bar_keep_warm_uses_official_lua_command(self) -> None:
        """Send the model-specific keep-warm toggle with its saved duration."""
        tea_bar = MideaEDDevice(
            name="Tea Bar",
            device_id=2,
            ip_address="192.0.2.1",
            port=6444,
            token=TEST_AUTH_VALUE,
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="63000622",
            subtype=395,
            customize="",
        )
        tea_bar._attributes[DeviceAttributes.keep_warm_time] = 3.0

        with patch.object(tea_bar, "build_send") as mock_build_send:
            tea_bar.set_attribute(DeviceAttributes.keep_warm, True)

        message = mock_build_send.call_args.args[0]
        assert message.body == bytearray(
            [0x15, 0x01, 0x01, 0x08, 0x04, 0x01, 0x06, 0x00],
        )

    def test_tea_bar_keep_warm_time_preserves_off_state(self) -> None:
        """Save a duration without unexpectedly enabling keep-warm."""
        tea_bar = MideaEDDevice(
            name="Tea Bar",
            device_id=2,
            ip_address="192.0.2.1",
            port=6444,
            token=TEST_AUTH_VALUE,
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="63000622",
            subtype=395,
            customize="",
        )

        with patch.object(tea_bar, "build_send") as mock_build_send:
            tea_bar.set_attribute(DeviceAttributes.keep_warm_time, 4.5)

        message = mock_build_send.call_args.args[0]
        assert message.body == bytearray(
            [0x15, 0x01, 0x01, 0x08, 0x04, 0x00, 0x09, 0x00],
        )

    @pytest.mark.parametrize("duration", [0.5, 12.5, 1.25])
    def test_tea_bar_rejects_invalid_keep_warm_time(self, duration: float) -> None:
        """Reject durations outside the official model range and step."""
        tea_bar = MideaEDDevice(
            name="Tea Bar",
            device_id=2,
            ip_address="192.0.2.1",
            port=6444,
            token=TEST_AUTH_VALUE,
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="63000622",
            subtype=395,
            customize="",
        )

        with (
            patch.object(tea_bar, "build_send") as mock_build_send,
            pytest.raises(ValueError, match=r"0\.5-hour steps"),
        ):
            tea_bar.set_attribute(DeviceAttributes.keep_warm_time, duration)
        mock_build_send.assert_not_called()


class TestMideaEDDeviceSoftWater:
    """Test Midea ED Device soft water machine (subtype 703)."""

    device: MideaEDDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea soft water device setup (subtype 703)."""
        self.device = MideaEDDevice(
            name="Soft Water",
            device_id=2,
            ip_address="192.0.2.1",
            port=6444,
            token=TEST_AUTH_VALUE,
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="6360000A",
            subtype=703,
            customize="",
        )

    def test_initial_soft_water_attributes(self) -> None:
        """Test initial soft water machine attributes."""
        attrs = self.device.attributes
        assert attrs[DeviceAttributes.velocity] is None
        assert attrs[DeviceAttributes.soft_available] is None
        assert attrs[DeviceAttributes.left_salt] is None
        assert attrs[DeviceAttributes.leak_water_protection_value] is None
        assert attrs[DeviceAttributes.remaining_days] is None
        assert attrs[DeviceAttributes.water_hardness] is None
        assert attrs[DeviceAttributes.flushing_days] is None
        assert attrs[DeviceAttributes.timing_regeneration_hour] is None
        assert attrs[DeviceAttributes.timing_regeneration_min] is None
        assert attrs[DeviceAttributes.regeneration_left_seconds] is None
        assert attrs[DeviceAttributes.use_days] is None
        assert attrs[DeviceAttributes.salt_setting] is None
        assert attrs[DeviceAttributes.soften] is False
        assert attrs[DeviceAttributes.cl_sterilization] is False
        assert attrs[DeviceAttributes.leak_water_protection] is False
        assert attrs[DeviceAttributes.water_way] is False
        assert attrs[DeviceAttributes.regeneration] is False
        assert attrs[DeviceAttributes.error] is None

    def test_build_query_uses_message_query09(self) -> None:
        """Test subtype 703 uses MessageQuery09."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery09)

    def test_set_attribute_soften(self) -> None:
        """Test setting soften switch."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.soften, True)
            mock_build_send.assert_called_once()

    def test_set_attribute_water_hardness(self) -> None:
        """Test setting water_hardness number."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.water_hardness, 150)
            mock_build_send.assert_called_once()

    def test_set_attribute_timing_regeneration_hour_couples_min(self) -> None:
        """Test setting hour also sends current min value (coupled write)."""
        # Set current min value in attributes
        self.device._attributes[DeviceAttributes.timing_regeneration_min] = 30
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.timing_regeneration_hour, 2)
            mock_build_send.assert_called_once()
            sent_message = mock_build_send.call_args[0][0]
            assert sent_message.timing_regeneration_hour == 2
            assert sent_message.timing_regeneration_min == 30

    def test_set_attribute_timing_regeneration_min_couples_hour(self) -> None:
        """Test setting min also sends current hour value (coupled write)."""
        self.device._attributes[DeviceAttributes.timing_regeneration_hour] = 5
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.timing_regeneration_min, 45)
            mock_build_send.assert_called_once()
            sent_message = mock_build_send.call_args[0][0]
            assert sent_message.timing_regeneration_min == 45
            assert sent_message.timing_regeneration_hour == 5

    def test_set_attribute_leak_water_protection_value_couples_switch(self) -> None:
        """Test setting leak_water_protection_value also sends current switch state."""
        self.device._attributes[DeviceAttributes.leak_water_protection] = True
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.leak_water_protection_value, 400)
            mock_build_send.assert_called_once()
            sent_message = mock_build_send.call_args[0][0]
            assert sent_message.leak_water_protection_value == 400
            assert sent_message.leak_water_protection is True

    def test_set_attribute_old_set(self) -> None:
        """Test set attribute with the old set message."""
        with (
            patch.object(self.device, "_use_new_set", return_value=False),
            patch.object(self.device, "build_send") as mock_build_send,
        ):
            self.device.set_attribute(DeviceAttributes.power, True)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageOldSet)
            # power is set dynamically via setattr in set_attribute
            assert getattr(message, "power", None) is True
