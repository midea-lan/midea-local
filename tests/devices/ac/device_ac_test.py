"""Test AC Device."""

import logging
from types import SimpleNamespace
from typing import cast
from unittest.mock import patch

import pytest

from midealan.const import ProtocolVersion
from midealan.devices.ac import DeviceAttributes, MideaACDevice
from midealan.devices.ac.message import (
    CapabilitiesAdditionalQuery,
    CapabilitiesQuery,
    CapabilityTag,
    CapabilityValue,
    GroupOneQuery,
    GroupSevenQuery,
    GroupTwoQuery,
    GroupZeroQuery,
    HumidityQuery,
    MessageACResponse,
    PowerFormats,
    PowerQuery,
    PropertiesCapsQuery,
    PropertiesCapsQuery1,
    PropertiesDefaultQuery,
    StateQuery,
    SubProtocolFreshAirSet,
    SubProtocolQuery,
    SubProtocolQuery10,
    SubProtocolQuery11,
    SubProtocolQuery30,
    ToggleDisplay,
)
from midealan.message import ListTypes, MessageBase

# C0 body from the public capture in
# https://github.com/wuwentao/midea_ac_lan/issues/998
MODEL_220F4047_C0_BODY = bytes.fromhex(
    "c00150667f7f0000000c002e200b0003000000000000000058020000f0ff533d",
)


class TestMideaACDevice:
    """Test Midea AC Device."""

    device: MideaACDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea AC Device setup."""
        self.device = MideaACDevice(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.1",
            port=12345,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model="test_model",
            subtype=1,
            customize='{"temperature_step": 1, "power_analysis_method": 2}',
        )

    def test_initial_attributes(self) -> None:
        """Test initial attributes."""
        assert self.device.attributes[DeviceAttributes.prompt_tone]
        assert not self.device.attributes[DeviceAttributes.power]
        assert self.device.attributes[DeviceAttributes.mode] == 0
        assert self.device.attributes[DeviceAttributes.target_temperature] == 24.0
        assert self.device.attributes[DeviceAttributes.fan_speed] == 102
        assert not self.device.attributes[DeviceAttributes.swing_vertical]
        assert not self.device.attributes[DeviceAttributes.swing_horizontal]
        assert not self.device.attributes[DeviceAttributes.power_saving]
        assert not self.device.attributes[DeviceAttributes.out_silent]
        assert self.device.temperature_step == 1
        assert self.device.fresh_air_fan_speeds is not None
        assert DeviceAttributes.compressor_frequency in self.device.attributes
        assert not self.device.fresh_air_exhaust_fan_speeds

    @staticmethod
    def _make_device(model: str, subtype: int) -> MideaACDevice:
        """Create a model-specific AC device."""
        return MideaACDevice(
            name="Model Device",
            device_id=2,
            ip_address="192.168.1.2",
            port=12345,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model=model,
            subtype=subtype,
            customize="",
        )

    @staticmethod
    def _response(body: bytearray) -> bytes:
        """Wrap an AC response body in a complete query frame."""
        header = bytearray([0xAA, 0, 0xAC, 0, 0, 0, 0, 0, 1, 3])
        header[1] = len(header) + len(body)
        frame = header + body
        frame.append(MessageBase.checksum(frame[1:]))
        return bytes(frame)

    def test_customize_accepts_bcd_energy_binary_power_format(self) -> None:
        """Test customize can select BCD energy with binary realtime power."""
        device = MideaACDevice(
            name="Custom Power Format Device",
            device_id=1,
            ip_address="192.168.1.1",
            port=12345,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model="test_model",
            subtype=1,
            customize='{"power_analysis_method": 101}',
        )

        assert device._power_analysis_method == PowerFormats.BCD_ENERGY_BINARY_POWER

    def test_set_attribute(self) -> None:
        """Test set attribute."""
        with (
            patch.object(self.device, "send_message_v2") as mock_build_send,
            patch(
                "midealan.devices.ac.MessageACResponse",
            ) as mock_message_response,
        ):
            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.power.value, False)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.mode.value, 2)
            mock_build_send.assert_called()

            self.device.set_target_temperature(26, 2)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.prompt_tone.value, False)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.screen_display.value, False)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.breezeless.value, False)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.indirect_wind.value, False)
            mock_build_send.assert_called()

            self.device.set_attribute(
                DeviceAttributes.screen_display_alternate.value,
                False,
            )
            mock_build_send.assert_called()

            mock_message = mock_message_response.return_value
            mock_message.used_subprotocol = True
            mock_message.timer = 30
            mock_message.fresh_air_power = False
            mock_message.fresh_air_1 = 1

            self.device.process_message(b"")

            self.device.set_attribute(DeviceAttributes.fresh_air_power.value, True)
            mock_build_send.assert_called()

            mock_message.fresh_air_1 = None
            mock_message.fresh_air_2 = 1
            self.device.process_message(b"")

            self.device.set_attribute(DeviceAttributes.fresh_air_mode.value, "Medium")
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.fresh_air_fan_speed.value, 50)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.comfort_mode.value, True)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.power_saving.value, True)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.fresh_air_mode.value, False)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.out_silent.value, True)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.out_silent.value, False)
            mock_build_send.assert_called()

    def test_set_attribute_angles_and_rate_select(self) -> None:
        """Test set attribute for wind angles and rate select."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.wind_lr_angle.value, "left")
            message = mock_build_send.call_args[0][0]
            assert message.wind_lr_angle == 1

            self.device.set_attribute(DeviceAttributes.wind_ud_angle.value, "up")
            message = mock_build_send.call_args[0][0]
            assert message.wind_ud_angle == 1

            # 5-level device: "40" maps back to raw value 40
            self.device._capabilities["rate_select"] = 2
            self.device.set_attribute(DeviceAttributes.rate_select.value, "40")
            message = mock_build_send.call_args[0][0]
            assert message.rate_select == 40

            # 2-level device: only 50/75/100 are valid gears
            self.device._capabilities["rate_select"] = 1
            self.device.set_attribute(DeviceAttributes.rate_select.value, "75")
            message = mock_build_send.call_args[0][0]
            assert message.rate_select == 75

            # Value not in the active level map resolves to None
            self.device.set_attribute(DeviceAttributes.rate_select.value, "40")
            message = mock_build_send.call_args[0][0]
            assert message.rate_select is None

    def test_set_attribute_fresh_air_mode_named_speed(self) -> None:
        """Test set attribute for fresh air mode with a named fan speed."""
        self.device._fresh_air_version = DeviceAttributes.fresh_air_1
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.fresh_air_mode.value, "medium")
            message = mock_build_send.call_args[0][0]
            assert message.fresh_air_1 == [True, 60]

            self.device.set_attribute(DeviceAttributes.fresh_air_mode.value, "off")
            message = mock_build_send.call_args[0][0]
            assert message.fresh_air_1 == [False, 0]

    def test_set_screen_display_is_idempotent(self) -> None:
        """screen_display toggles only when the requested state differs.

        The firmware exposes a toggle-only command, so setting the switch to
        its current state must send nothing; only a differing request emits a
        single ToggleDisplay.
        https://github.com/wuwentao/midea_ac_lan/issues/623
        """
        with patch.object(self.device, "build_send") as mock_build_send:
            # Currently off: turning off again is a no-op.
            self.device._attributes[DeviceAttributes.screen_display] = False
            self.device.set_attribute(DeviceAttributes.screen_display.value, False)
            mock_build_send.assert_not_called()

            # Currently off: turning on sends one toggle.
            self.device.set_attribute(DeviceAttributes.screen_display.value, True)
            mock_build_send.assert_called_once()
            assert isinstance(mock_build_send.call_args[0][0], ToggleDisplay)

            mock_build_send.reset_mock()

            # Currently on: turning on again is a no-op.
            self.device._attributes[DeviceAttributes.screen_display] = True
            self.device.set_attribute(DeviceAttributes.screen_display.value, True)
            mock_build_send.assert_not_called()

            # Currently on: turning off sends one toggle.
            self.device.set_attribute(DeviceAttributes.screen_display.value, False)
            mock_build_send.assert_called_once()
            assert isinstance(mock_build_send.call_args[0][0], ToggleDisplay)

    def test_set_attribute_eco_mode_resets_exclusive_modes(self) -> None:
        """Test eco mode set resets comfort and frost protect on general set."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.eco_mode.value, True)
            message = mock_build_send.call_args[0][0]
            assert message.eco_mode is True
            assert message.boost_mode is False
            assert message.sleep_mode is False
            assert message.comfort_mode is False
            assert message.frost_protect is False

    def test_set_attribute_mode_change_from_dry(self) -> None:
        """Test mode change out of dry mode forces fan speed to auto."""
        self.device._attributes[DeviceAttributes.mode] = 3  # DRY_MODE
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.mode.value, 1)
            message = mock_build_send.call_args[0][0]
            assert message.mode == 1
            assert message.power is True
            assert message.dry is False
            assert message.fan_speed == 102

    def test_set_mode_then_temperature_keeps_unit_on(self) -> None:
        """A mode change followed immediately by a temperature write stays on.

        set_attribute("mode") only forced power=True on the outgoing packet, so
        a rapid follow-up set_target_temperature (built from make_message_uniq_set)
        reused the stale last-confirmed power=False and turned the unit back off.
        The mode change now optimistically caches power=True + the new mode.
        https://github.com/midea-lan/midea-local/issues/495
        """
        # Start from the confirmed "off" state, as after a fresh query.
        self.device._attributes[DeviceAttributes.power] = False
        self.device._attributes[DeviceAttributes.mode] = 0
        with patch.object(self.device, "build_send") as mock_build_send:
            # 1. set HVAC mode to cool (value 2)
            self.device.set_attribute(DeviceAttributes.mode.value, 2)
            mode_message = mock_build_send.call_args[0][0]
            assert mode_message.power is True
            assert mode_message.mode == 2
            # Cache reflects the commanded state before the device responds.
            assert self.device.attributes[DeviceAttributes.power] is True
            assert self.device.attributes[DeviceAttributes.mode] == 2

            # 2. immediately set target temperature (mode=None, as the climate
            #    entity does) - must not resurrect the stale power=False.
            self.device.set_target_temperature(21, None)
            temp_message = mock_build_send.call_args[0][0]
            assert temp_message.power is True
            assert temp_message.mode == 2
            assert temp_message.target_temperature == 21

    def test_customize_temperature_limits(self) -> None:
        """Test customize min/max temperature limits."""
        self.device.set_customize('{"min_temperature": 17, "max_temperature": 28}')
        assert self.device.attributes[DeviceAttributes.min_temperature] == 17
        assert self.device.attributes[DeviceAttributes.max_temperature] == 28

    def test_capability_temperature_limits_missing_range(self) -> None:
        """Test capability limits fall back when the mode range is absent.

        The nested ``temperature`` map may lack the entry for the current mode
        (e.g. a malformed B5 payload). The resolver must return None instead of
        raising, so the consumer keeps its own default range.
        """
        self.device._attributes[DeviceAttributes.mode] = 2  # -> "cool"
        # temperature dict is present but has no "cool" key.
        self.device._capabilities["temperature"] = {"heat": {"min": 16, "max": 30}}
        assert self.device._capability_temperature_limits() is None

    def test_capability_temperature_limits_missing_min_max(self) -> None:
        """Test capability limits return None when min/max keys are missing.

        A range entry that is a dict but lacks the ``min``/``max`` keys must not
        raise a KeyError; the resolver returns None instead.
        """
        self.device._attributes[DeviceAttributes.mode] = 2  # -> "cool"
        self.device._capabilities["temperature"] = {"cool": {"min": 16}}
        assert self.device._capability_temperature_limits() is None

    def test_build_query(self) -> None:
        """Test build query."""
        self.device._used_subprotocol = True
        queries = self.device.build_query()
        assert len(queries) == 3
        assert isinstance(queries[0], SubProtocolQuery)
        assert isinstance(queries[1], SubProtocolQuery)
        assert isinstance(queries[2], SubProtocolQuery)

        self.device._used_subprotocol = False
        queries = self.device.build_query()
        # The new-protocol query is now split into PropertiesDefaultQuery +
        # optional PropertiesCapsQuery/PropertiesCapsQuery1 batches. Capability
        # queries are no longer part of the recurring status cycle; they are
        # returned by build_init_query().
        assert len(queries) >= 8  # At least 8, more if capability queries added
        assert isinstance(queries[0], StateQuery)
        assert isinstance(queries[1], PropertiesDefaultQuery)
        # queries[2..N] may be PropertiesCapsQuery/...1 if capabilities exist
        # Find the index of PowerQuery to verify remaining queries
        power_idx = next(i for i, q in enumerate(queries) if isinstance(q, PowerQuery))
        assert isinstance(queries[power_idx], PowerQuery)
        assert isinstance(queries[power_idx + 1], HumidityQuery)
        assert isinstance(queries[power_idx + 2], GroupZeroQuery)
        assert isinstance(queries[power_idx + 3], GroupOneQuery)
        assert isinstance(queries[power_idx + 4], GroupTwoQuery)
        assert isinstance(queries[power_idx + 5], GroupSevenQuery)
        assert not any(
            isinstance(q, CapabilitiesQuery | CapabilitiesAdditionalQuery)
            for q in queries
        )

    def test_build_init_query_capability_lifecycle(self) -> None:
        """Test build_init_query arms/clears the one-shot B5 capability probes."""
        self.device._used_subprotocol = False
        # Basic query is armed at construction; additional is not yet.
        assert self.device._capability_query is True
        assert self.device._capability_addition_query is False
        init = self.device.build_init_query()
        assert len(init) == 1
        assert isinstance(init[0], CapabilitiesQuery)
        assert not isinstance(init[0], CapabilitiesAdditionalQuery)

        # After the basic reply advertises a second frame, only the additional
        # query is due.
        self.device._capability_query = False
        self.device._capability_addition_query = True
        init = self.device.build_init_query()
        assert len(init) == 1
        assert isinstance(init[0], CapabilitiesAdditionalQuery)

        # Once both are resolved, no capability query is sent.
        self.device._capability_addition_query = False
        assert self.device.build_init_query() == []

        # Subprotocol (BB) devices never use B5 capability probes.
        self.device._used_subprotocol = True
        self.device._capability_query = True
        self.device._capability_addition_query = True
        assert self.device.build_init_query() == []

    def test_build_query_omits_optional_tags_until_capability_confirmed(self) -> None:
        """Test optional tags stay out of the B1 query until capabilities confirm them.

        Before any B5 capabilities response is seen, `_capabilities` is empty, so
        the query built for the device must not ask for rate_select or self_clean.
        With the new split query structure, these would only appear in
        PropertiesCapsQuery batches, not in PropertiesDefaultQuery.
        """
        self.device._used_subprotocol = False
        assert self.device.capabilities == {}
        queries = self.device.build_query()
        # Should only have PropertiesDefaultQuery, no PropertiesCapsQuery batches
        caps_queries = [
            q
            for q in queries
            if isinstance(
                q,
                (PropertiesCapsQuery, PropertiesCapsQuery1),
            )
        ]
        # With empty capabilities, no capability queries should be generated
        assert len(caps_queries) == 0

        self.device._capabilities["rate_select"] = True
        self.device._capabilities["self_clean"] = True
        queries = self.device.build_query()
        # Now should have at least one capability query
        caps_queries = [
            q
            for q in queries
            if isinstance(
                q,
                (PropertiesCapsQuery, PropertiesCapsQuery1),
            )
        ]
        assert len(caps_queries) >= 1
        # Check that rate_select and self_clean appear in at least one caps query
        all_caps_bodies = b"".join(q._body for q in caps_queries)
        assert CapabilityTag.rate_select in all_caps_bodies
        assert CapabilityTag.self_clean in all_caps_bodies

    def test_customize_capabilities_override_query_and_property(self) -> None:
        """Test a customize capabilities entry forces an optional tag on.

        A user can enable a feature the B5 query never advertised; the merged
        capabilities property and the B1 query both reflect the override.
        """
        self.device._used_subprotocol = False
        self.device.set_customize('{"capabilities": {"self_clean": true}}')
        assert self.device.capabilities["self_clean"] is True
        queries = self.device.build_query()
        # Should have at least one capability query with self_clean
        caps_queries = [
            q
            for q in queries
            if isinstance(
                q,
                (PropertiesCapsQuery, PropertiesCapsQuery1),
            )
        ]
        assert len(caps_queries) >= 1
        all_caps_bodies = b"".join(q._body for q in caps_queries)
        assert CapabilityTag.self_clean in all_caps_bodies

    def test_customize_capabilities_disable_overrides_reported_value(self) -> None:
        """Test a customize false value overrides a B5-reported capability."""
        self.device._used_subprotocol = False
        self.device._capabilities["rate_select"] = 2
        self.device.set_customize('{"capabilities": {"rate_select": false}}')
        assert self.device.capabilities["rate_select"] is False
        queries = self.device.build_query()
        # Should not have rate_select in any capability query
        caps_queries = [
            q
            for q in queries
            if isinstance(
                q,
                (PropertiesCapsQuery, PropertiesCapsQuery1),
            )
        ]
        if caps_queries:
            all_caps_bodies = b"".join(q._body for q in caps_queries)
            assert CapabilityTag.rate_select not in all_caps_bodies

    def test_customize_capabilities_reset_when_absent(self) -> None:
        """Test customize capabilities clear when a later customize omits them."""
        self.device.set_customize('{"capabilities": {"self_clean": true}}')
        assert self.device._customize_capabilities == {"self_clean": True}
        self.device.set_customize('{"temperature_step": 1}')
        assert self.device._customize_capabilities == {}

    def test_customize_capabilities_ignores_non_dict(self) -> None:
        """Test a non-dict capabilities value is ignored, not applied."""
        self.device.set_customize('{"capabilities": "self_clean"}')
        assert self.device._customize_capabilities == {}

    def test_customize_capabilities_override_priority(self) -> None:
        """Test customize override wins when both B5 and customize set the same key.

        When _capabilities and _customize_capabilities both have a key, the
        merged capabilities property must return the customize value (higher
        priority), ensuring users can correct wrong B5 reports.
        """
        self.device._capabilities["rate_select"] = 1
        self.device._capabilities["self_clean"] = False
        self.device.set_customize(
            '{"capabilities": {"rate_select": 2, "self_clean": true}}',
        )
        merged = self.device.capabilities
        assert merged["rate_select"] == 2  # customize wins over B5 value 1
        assert merged["self_clean"] is True  # customize wins over B5 value False

    def test_customize_capabilities_publishes_event_on_enable(self) -> None:
        """Test set_customize emits a capabilities event when enabling an override.

        When set_customize applies a capability override, it must notify listeners
        (e.g., Home Assistant) via update_all so they see the merged capabilities
        immediately, not after the next B5 query (which is one-shot).
        """
        with patch.object(self.device, "update_all") as update_all_mock:
            self.device.set_customize('{"capabilities": {"self_clean": true}}')
            # Verify update_all was called with the merged capabilities dict
            calls = [call.args[0] for call in update_all_mock.call_args_list]
            # Should have at least one call with capabilities key
            capabilities_updates = [c for c in calls if "capabilities" in c]
            assert len(capabilities_updates) > 0
            # The published capabilities should include the override
            published_caps = capabilities_updates[-1]["capabilities"]
            assert published_caps["self_clean"] is True

    def test_customize_capabilities_publishes_event_on_clear(self) -> None:
        """Test set_customize emits a capabilities event when clearing overrides.

        When set_customize is called with no capabilities key (or empty customize),
        it resets _customize_capabilities to {}. This must still publish the merged
        capabilities so listeners know the overrides are gone and the effective map
        has reverted to B5-only values.
        """
        # First set an override
        self.device.set_customize('{"capabilities": {"rate_select": 3}}')
        assert self.device._customize_capabilities == {"rate_select": 3}
        # Now clear it by calling set_customize with no capabilities key
        with patch.object(self.device, "update_all") as update_all_mock:
            self.device.set_customize('{"temperature_step": 1}')
            # Verify update_all was called with capabilities
            calls = [call.args[0] for call in update_all_mock.call_args_list]
            capabilities_updates = [c for c in calls if "capabilities" in c]
            assert len(capabilities_updates) > 0
            # The published capabilities should not have rate_select override
            published_caps = capabilities_updates[-1]["capabilities"]
            assert "rate_select" not in published_caps or not published_caps.get(
                "rate_select",
            )

    def test_bb_model_builds_distinct_queries_and_attributes(self) -> None:
        """Test verified BB model starts with independent BB queries."""
        device = self._make_device("23096633", 1)

        queries = device.build_query()

        assert [type(query) for query in queries] == [
            SubProtocolQuery10,
            SubProtocolQuery11,
            SubProtocolQuery30,
        ]
        assert DeviceAttributes.compressor_frequency in device.attributes
        assert DeviceAttributes.target_compressor_frequency in device.attributes
        assert DeviceAttributes.fresh_air_exhaust_power in device.attributes
        assert device.fresh_air_fan_speeds == [
            "off",
            "low",
            "medium",
            "high",
            "full",
        ]
        assert device.fresh_air_exhaust_fan_speeds == [
            "off",
            "silent",
            "high",
            "full",
        ]

    @pytest.mark.parametrize(
        ("model", "subtype"),
        [("unknown", 1), ("23096633", 8), ("22390001", 1)],
    )
    def test_model_attribute_gating(self, model: str, subtype: int) -> None:
        """Test diagnostics and commands require an exact model/subtype pair."""
        device = self._make_device(model, subtype)

        assert DeviceAttributes.fresh_air_exhaust_power not in device.attributes
        queries = device.build_query()
        assert isinstance(queries[0], StateQuery)
        assert not any(
            isinstance(
                query,
                SubProtocolQuery10 | SubProtocolQuery11 | SubProtocolQuery30,
            )
            for query in queries
        )
        with patch.object(device, "build_send") as build_send:
            device.set_attribute(
                DeviceAttributes.fresh_air_exhaust_power,
                True,
            )
            build_send.assert_not_called()

    @pytest.mark.parametrize(
        ("decimal", "expected_temperature"),
        [(0x03, 23.3), (0x08, 23.8)],
    )
    def test_220f4047_c0_temperature_uses_model_specific_encoding(
        self,
        decimal: int,
        expected_temperature: float,
    ) -> None:
        """Decode the C0 temperatures reported by model 220F4047 subtype 8."""
        device = self._make_device("220F4047", 8)
        body = bytearray(MODEL_220F4047_C0_BODY)
        body[15] = decimal

        status = device.process_message(self._response(body))

        assert status[DeviceAttributes.indoor_temperature.value] == expected_temperature
        assert status[DeviceAttributes.outdoor_temperature.value] is None

    @pytest.mark.parametrize(
        ("model", "subtype"),
        [("220F4047", 1), ("other", 8)],
    )
    def test_220f4047_c0_temperature_encoding_is_exactly_gated(
        self,
        model: str,
        subtype: int,
    ) -> None:
        """Keep the standard C0 decoder for every other model/subtype pair."""
        device = self._make_device(model, subtype)

        status = device.process_message(
            self._response(bytearray(MODEL_220F4047_C0_BODY)),
        )

        assert status[DeviceAttributes.indoor_temperature.value] == -2.3
        assert status[DeviceAttributes.outdoor_temperature.value] == -9.0

    def test_c0_temperature_fix_keeps_non_placeholder_outdoor_temperature(
        self,
    ) -> None:
        """Keep the parsed outdoor temperature when it is not a placeholder."""
        device = self._make_device("220F4047", 8)
        body = bytearray(MODEL_220F4047_C0_BODY)
        body[12] = 0x50

        status = device.process_message(self._response(body))

        assert status[DeviceAttributes.indoor_temperature.value] == 23.3
        assert status[DeviceAttributes.outdoor_temperature.value] == 15.0

    def test_c0_temperature_fix_ignores_short_body(self) -> None:
        """Ignore malformed C0 bodies before reading temperature indexes."""
        device = self._make_device("220F4047", 8)
        message = SimpleNamespace(
            body_type=ListTypes.C0,
            body=bytearray(12),
            indoor_temperature="unchanged",
            outdoor_temperature="unchanged",
        )

        device._fix_c0_temperature(cast("MessageACResponse", message))

        assert message.indoor_temperature == "unchanged"
        assert message.outdoor_temperature == "unchanged"

    def test_actual_frequency_only_model_gating(self) -> None:
        """Test the naturally detected BB model exposes only actual frequency."""
        actual_only = self._make_device("23096725", 1)

        assert DeviceAttributes.compressor_frequency in actual_only.attributes
        assert DeviceAttributes.target_compressor_frequency in actual_only.attributes

    def test_process_bb_airflow_and_frequency(self) -> None:
        """Test verified BB model publishes airflow and compressor frequency."""
        device = self._make_device("23096633", 1)
        basic_body = bytearray(56)
        basic_body[:6] = bytearray([0xBB, 0, 0, 0, 0, 0x11])
        basic_body[51] = 0x01
        basic_body[52] = 60
        basic_body[53] = 100
        outdoor_body = bytearray(24)
        outdoor_body[:6] = bytearray([0xBB, 0, 0, 0, 0, 0x30])
        outdoor_body[16] = 49
        outdoor_body[17] = 47

        airflow = device.process_message(self._response(basic_body))
        frequency = device.process_message(self._response(outdoor_body))

        assert airflow[DeviceAttributes.fresh_air_power] is True
        assert airflow[DeviceAttributes.fresh_air_fan_speed] == 60
        assert airflow[DeviceAttributes.fresh_air_mode] == "medium"
        assert airflow[DeviceAttributes.fresh_air_exhaust_power] is False
        assert airflow[DeviceAttributes.fresh_air_exhaust_speed] == 100
        assert airflow[DeviceAttributes.fresh_air_exhaust_mode] == "off"
        assert frequency[DeviceAttributes.compressor_frequency] == 47
        assert frequency[DeviceAttributes.target_compressor_frequency] == 49

    def test_process_c1_frequency(self) -> None:
        """Test verified C1 model publishes compressor frequency."""
        device = self._make_device("22390001", 8)
        body = bytearray(15)
        body[0] = 0xC1
        body[3] = 0x41
        body[4] = 47
        body[5] = 49
        body[7] = 3
        body[8] = 229

        status = device.process_message(self._response(body))

        assert status[DeviceAttributes.compressor_frequency] == 47
        assert status[DeviceAttributes.target_compressor_frequency] == 49
        assert status[DeviceAttributes.compressor_current] == 3
        assert status[DeviceAttributes.compressor_voltage] == 229

    def test_bb_fresh_air_set_attribute(self) -> None:
        """Test BB model sends intake and exhaust single-control commands."""
        device = self._make_device("23096633", 1)
        with patch.object(device, "build_send") as build_send:
            device.set_attribute(DeviceAttributes.fresh_air_mode, "medium")
            intake = build_send.call_args.args[0]
            assert isinstance(intake, SubProtocolFreshAirSet)
            assert intake.power is True
            assert intake.speed == 60
            assert intake.exhaust is False

            device.set_attribute(DeviceAttributes.fresh_air_exhaust_mode, "high")
            exhaust = build_send.call_args.args[0]
            assert isinstance(exhaust, SubProtocolFreshAirSet)
            assert exhaust.power is True
            assert exhaust.speed == 80
            assert exhaust.exhaust is True

            device.set_attribute(DeviceAttributes.fresh_air_exhaust_power, False)
            exhaust_off = build_send.call_args.args[0]
            assert exhaust_off.power is False
            assert exhaust_off.exhaust is True

    def test_bb_fresh_air_exhaust_power_defaults_to_advertised_speed(self) -> None:
        """Test exhaust power-on uses a speed exposed by the preset list."""
        device = self._make_device("23096633", 1)

        with patch.object(device, "build_send") as build_send:
            device.set_attribute(DeviceAttributes.fresh_air_exhaust_power, True)

        message = build_send.call_args.args[0]
        assert isinstance(message, SubProtocolFreshAirSet)
        assert message.power is True
        assert message.speed == 80
        assert message.exhaust is True

    def test_bb_fresh_air_set_attribute_speed(self) -> None:
        """Test BB model sends intake and exhaust numeric speed commands."""
        device = self._make_device("23096633", 1)
        with patch.object(device, "build_send") as build_send:
            device.set_attribute(DeviceAttributes.fresh_air_fan_speed, 55)
            intake = build_send.call_args.args[0]
            assert isinstance(intake, SubProtocolFreshAirSet)
            assert intake.power is True
            assert intake.speed == 55
            assert intake.exhaust is False

            device.set_attribute(DeviceAttributes.fresh_air_exhaust_speed, 30)
            exhaust = build_send.call_args.args[0]
            assert isinstance(exhaust, SubProtocolFreshAirSet)
            assert exhaust.power is True
            assert exhaust.speed == 30
            assert exhaust.exhaust is True

            # Out-of-range values clamp to [0, 100]; 0 powers off and falls
            # back to the current speed. set_attribute does not itself
            # mutate _attributes, so the "current" exhaust speed used as a
            # fallback remains the model's advertised default.
            device.set_attribute(DeviceAttributes.fresh_air_exhaust_speed, 150)
            clamped = build_send.call_args.args[0]
            assert clamped.speed == 100

            device.set_attribute(DeviceAttributes.fresh_air_exhaust_speed, 0)
            zero_speed = build_send.call_args.args[0]
            assert zero_speed.power is False
            assert zero_speed.speed == 80

    def test_wind_angle_and_rate_select_properties(self) -> None:
        """Test wind angle and rate select option lists."""
        assert self.device.wind_lr_angles == [
            "off",
            "left",
            "left-mid",
            "middle",
            "right-mid",
            "right",
        ]
        assert self.device.wind_ud_angles == [
            "off",
            "up",
            "up-mid",
            "middle",
            "down-mid",
            "down",
        ]
        # No rate_select capability reported yet: no options offered
        assert self.device.rate_selects == []

        # 2-level device (b5_electricity value 1) reports 50/75/100 gears
        self.device._capabilities["rate_select"] = 1
        assert self.device.rate_selects == ["50", "75", "100"]

        # 5-level device (b5_electricity value 2 or 3) reports the full ladder
        self.device._capabilities["rate_select"] = 2
        assert self.device.rate_selects == ["1", "20", "40", "60", "80", "100"]
        self.device._capabilities["rate_select"] = 3
        assert self.device.rate_selects == ["1", "20", "40", "60", "80", "100"]

    def test_process_message_decodes_rate_select_per_level(self) -> None:
        """Test an incoming rate_select value decodes via the reported gear map.

        Regression for the "stays unknown" symptom: the raw value must be
        mapped through the level-specific gear map instead of a fixed table.
        """
        with patch("midealan.devices.ac.MessageACResponse") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.used_subprotocol = False
            mock_message.fresh_air_power = False
            mock_message.rate_select = 75

            # 2-level device: raw 75 -> gear "75" (the value from issue #980)
            self.device._capabilities["rate_select"] = 1
            result = self.device.process_message(b"")
            assert result[DeviceAttributes.rate_select.value] == "75"

            # 5-level device: 75 is not a valid gear, so it decodes to None
            self.device._capabilities["rate_select"] = 2
            result = self.device.process_message(b"")
            assert result[DeviceAttributes.rate_select.value] is None

            # 5-level device: raw 40 -> gear "40"
            mock_message.rate_select = 40
            result = self.device.process_message(b"")
            assert result[DeviceAttributes.rate_select.value] == "40"

            # No capability reported: no gear map, decodes to None
            self.device._capabilities["rate_select"] = 0
            result = self.device.process_message(b"")
            assert result[DeviceAttributes.rate_select.value] is None

    def test_capabilities_property_updates_from_b5_response(self) -> None:
        """Test B5 capability flags accumulate into the capabilities property."""
        assert self.device.capabilities == {}
        body = bytearray([0xB5, 0x03])
        body += bytearray([0x14, 0x02, 0x01, 7])  # b5_mode
        body += bytearray([0x12, 0x02, 0x01, 1])  # b5_eco
        body += bytearray([0x1E, 0x02, 0x01, 1])  # b5_anion

        self.device.process_message(self._response(body))

        assert self.device.capabilities == {
            "modes": ["heat", "cool", "auto"],
            "eco": True,
            "anion": True,
        }

    def test_b5_response_publishes_capabilities_in_status(self) -> None:
        """Test the merged capabilities dict is pushed through update_all.

        The HA integration reads ``device.capabilities`` on each status update,
        so process_message must surface the decoded dict rather than only
        caching it internally.
        """
        body = bytearray([0xB5, 0x02])
        body += bytearray([0x14, 0x02, 0x01, 7])  # b5_mode
        body += bytearray([0x12, 0x02, 0x01, 1])  # b5_eco

        # process_message's return value is what parse_message forwards verbatim
        # to update_all(), so the dict here is what listeners receive.
        status = self.device.process_message(self._response(body))

        assert "capabilities" in status
        assert "heat" in status["capabilities"]["modes"]
        assert status["capabilities"] == self.device.capabilities
        # It is a copy, not the internal dict, so listeners cannot corrupt it.
        assert status["capabilities"] is not self.device.capabilities

    def test_non_b5_response_omits_capabilities_from_status(self) -> None:
        """Test non-capability responses do not carry a capabilities key."""
        # A plain C0 state body has no capabilities.
        body = bytearray([0xC0]) + bytearray(20)
        status = self.device.process_message(self._response(body))

        assert "capabilities" not in status

    def test_reset_init_query_re_arms_capability_probes(self) -> None:
        """Test close_socket re-arms the B5 probes like the appliance query.

        A reconnected device must re-probe capabilities from scratch instead of
        reusing the previous result.
        """
        basic = bytearray.fromhex(
            "aa3dac00000000000803b50a1202010114020101150201001e020101170201021a"
            "02010110020101250207203c203c203c00240201014800010101199831",
        )
        additional = bytearray.fromhex(
            "aa2fac00000000000803b5081f0201002c020101160201043900010151000101e3"
            "00010113020101cd000103001a6910",
        )
        self.device.process_message(bytes(basic))
        self.device.process_message(bytes(additional))
        # Snapshot into locals: mypy narrows an asserted attribute to a literal
        # and can't see the opaque reset_init_query() below flips it back, so a
        # direct `is True`/`is False` pair would be reported unreachable.
        probed = (
            self.device._capability_query,
            self.device._support_capability,
            self.device._support_capability_addition,
        )
        assert probed == (False, True, True)

        # A socket close re-arms the basic probe (additional stays disarmed until
        # a fresh basic frame advertises it again).
        self.device.reset_init_query()
        rearmed = (
            self.device._capability_query,
            self.device._capability_addition_query,
            self.device._support_capability,
            self.device._support_capability_addition,
        )
        assert rearmed == (True, False, False, False)
        assert [type(q) for q in self.device.build_init_query()] == [CapabilitiesQuery]

    def test_capability_query_lifecycle_stops_after_both_frames(self) -> None:
        """Test the two B5 probes run once then stop, merging both frames.

        The basic frame advertises a second frame, which arms the additional
        query; once the additional frame is parsed, both flags are cleared so no
        capability query is ever sent again.
        """
        basic = bytearray.fromhex(
            "aa3dac00000000000803b50a1202010114020101150201001e020101170201021a"
            "02010110020101250207203c203c203c00240201014800010101199831",
        )
        additional = bytearray.fromhex(
            "aa2fac00000000000803b5081f0201002c020101160201043900010151000101e3"
            "00010113020101cd000103001a6910",
        )

        # Initial state: only the basic probe is armed. Snapshot into a local so
        # mypy's warn_unreachable does not treat the later contradicting asserts
        # (after the opaque process_message calls) as unreachable.
        initial = (
            self.device._capability_query,
            self.device._capability_addition_query,
            self.device._support_capability,
            self.device._support_capability_addition,
        )
        assert initial == (True, False, False, False)
        assert [type(q) for q in self.device.build_init_query()] == [CapabilitiesQuery]

        # Basic frame: records support, clears the basic probe, arms additional.
        self.device.process_message(bytes(basic))
        after_basic = (
            self.device._support_capability,
            self.device._capability_query,
            self.device._capability_addition_query,
        )
        assert after_basic == (True, False, True)
        assert [type(q) for q in self.device.build_init_query()] == [
            CapabilitiesAdditionalQuery,
        ]

        # Additional frame: records support and clears the additional probe.
        self.device.process_message(bytes(additional))
        after_additional = (
            self.device._support_capability_addition,
            self.device._capability_addition_query,
        )
        assert after_additional == (True, False)
        assert self.device.build_init_query() == []

        # Both frames merged into a single capability dict. rate_select carries
        # the raw B5 b5_electricity level count (4 in this frame), not a bool.
        assert self.device.capabilities["rate_select"] == 4
        modes = self.device.capabilities["modes"]
        assert isinstance(modes, list)
        assert "cool" in modes

    def test_process_message(self) -> None:
        """Test process message."""
        with patch("midealan.devices.ac.MessageACResponse") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.used_subprotocol = False
            mock_message.prompt_tone = False
            mock_message.power = True
            mock_message.mode = 1
            mock_message.target_temperature = 25.0
            mock_message.fan_speed = 102
            mock_message.swing_vertical = True
            mock_message.swing_horizontal = True
            mock_message.smart_eye = True
            mock_message.dry = True
            mock_message.aux_heating = True
            mock_message.boost_mode = True
            mock_message.power_saving = True
            mock_message.sleep_mode = True
            mock_message.frost_protect = True
            mock_message.comfort_mode = True
            mock_message.eco_mode = True
            mock_message.natural_wind = True
            mock_message.temp_fahrenheit = True
            mock_message.screen_display = True
            mock_message.screen_display_alternate = True
            mock_message.full_dust = True
            mock_message.indoor_temperature = None
            mock_message.outdoor_temperature = None
            mock_message.indoor_humidity = None
            mock_message.breezeless = True
            mock_message.total_energy_consumption = None
            mock_message.current_energy_consumption = None
            mock_message.realtime_power = None
            mock_message.fresh_air_power = True
            mock_message.fresh_air_fan_speed = 0
            mock_message.fresh_air_1 = 1
            mock_message.fresh_air_2 = 1
            mock_message.out_silent = True

            result = self.device.process_message(b"")
            assert result[DeviceAttributes.power.value]
            assert not result[DeviceAttributes.prompt_tone.value]
            assert result[DeviceAttributes.mode.value] == 1
            assert result[DeviceAttributes.target_temperature.value] == 25.0
            assert result[DeviceAttributes.fan_speed.value] == 102
            assert result[DeviceAttributes.swing_vertical.value]
            assert result[DeviceAttributes.swing_horizontal.value]
            assert result[DeviceAttributes.smart_eye.value]
            assert result[DeviceAttributes.dry.value]
            assert result[DeviceAttributes.aux_heating.value]
            assert result[DeviceAttributes.boost_mode.value]
            assert result[DeviceAttributes.power_saving.value]
            assert result[DeviceAttributes.sleep_mode.value]
            assert result[DeviceAttributes.frost_protect.value]
            assert result[DeviceAttributes.comfort_mode.value]
            assert result[DeviceAttributes.eco_mode.value]
            assert result[DeviceAttributes.natural_wind.value]
            assert result[DeviceAttributes.temp_fahrenheit.value]
            assert result[DeviceAttributes.screen_display.value]
            assert result[DeviceAttributes.screen_display_alternate.value]
            assert result[DeviceAttributes.full_dust.value]
            assert result[DeviceAttributes.indoor_temperature.value] is None
            assert result[DeviceAttributes.outdoor_temperature.value] is None
            assert result[DeviceAttributes.indoor_humidity.value] is None
            assert result[DeviceAttributes.breezeless.value]
            assert result[DeviceAttributes.total_energy_consumption.value] is None
            assert result[DeviceAttributes.current_energy_consumption.value] is None
            assert result[DeviceAttributes.realtime_power.value] is None
            assert result[DeviceAttributes.fresh_air_power.value]
            assert result[DeviceAttributes.fresh_air_mode.value] == "off"
            assert result[DeviceAttributes.fresh_air_1.value] == 1
            assert result[DeviceAttributes.fresh_air_2.value] == 1
            assert result[DeviceAttributes.out_silent.value]

            mock_message.fresh_air_fan_speed = 55
            mock_message.fresh_air_1 = None
            result = self.device.process_message(b"")
            assert result[DeviceAttributes.fresh_air_mode.value] == "low"

            mock_message.fresh_air_power = False
            result = self.device.process_message(b"")
            assert result[DeviceAttributes.fresh_air_mode.value] == "off"

            mock_message.power = False
            result = self.device.process_message(b"")
            assert not result[DeviceAttributes.screen_display.value]
            assert not self.device.attributes[DeviceAttributes.screen_display]

    def test_process_message_group_data(self) -> None:
        """Test that group 1/2/7 data is stored in the device attributes."""
        with patch("midealan.devices.ac.MessageACResponse") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.used_subprotocol = False
            mock_message.power = True
            mock_message.fresh_air_power = False
            mock_message.fresh_air_fan_speed = 0
            mock_message.fresh_air_1 = None
            mock_message.fresh_air_2 = None
            mock_message.swing_vertical = False
            # group 1
            mock_message.compressor_frequency = 28
            mock_message.target_compressor_frequency = 25
            mock_message.compressor_current = 1
            mock_message.compressor_voltage = 232
            mock_message.indoor_ambient_temperature = 20.5
            mock_message.indoor_coil_temperature = 4.0
            mock_message.outdoor_coil_temperature = 26.0
            mock_message.outdoor_ambient_temperature = 19.0
            mock_message.discharge_pipe_temperature = 36
            # group 2
            mock_message.indoor_fan_speed = 424
            mock_message.target_indoor_fan_speed = 416
            mock_message.water_pump_running = False
            # group 7
            mock_message.compressor_power = 269

            result = self.device.process_message(b"")

            assert result[DeviceAttributes.compressor_frequency.value] == 28
            assert result[DeviceAttributes.target_compressor_frequency.value] == 25
            assert result[DeviceAttributes.compressor_current.value] == 1
            assert result[DeviceAttributes.compressor_voltage.value] == 232
            assert result[DeviceAttributes.indoor_ambient_temperature.value] == 20.5
            assert result[DeviceAttributes.indoor_coil_temperature.value] == 4.0
            assert result[DeviceAttributes.outdoor_coil_temperature.value] == 26.0
            assert result[DeviceAttributes.outdoor_ambient_temperature.value] == 19.0
            assert result[DeviceAttributes.discharge_pipe_temperature.value] == 36
            assert result[DeviceAttributes.indoor_fan_speed.value] == 424
            assert result[DeviceAttributes.target_indoor_fan_speed.value] == 416
            assert result[DeviceAttributes.water_pump_running.value] is False
            assert result[DeviceAttributes.compressor_power.value] == 269

    def test_set_attribute_group_data_is_read_only(self) -> None:
        """Test that group data attributes never send a set message."""
        with patch.object(self.device, "build_send") as mock_build_send:
            for attr in [
                DeviceAttributes.compressor_frequency,
                DeviceAttributes.target_compressor_frequency,
                DeviceAttributes.compressor_current,
                DeviceAttributes.compressor_voltage,
                DeviceAttributes.indoor_ambient_temperature,
                DeviceAttributes.indoor_coil_temperature,
                DeviceAttributes.outdoor_coil_temperature,
                DeviceAttributes.outdoor_ambient_temperature,
                DeviceAttributes.discharge_pipe_temperature,
                DeviceAttributes.indoor_fan_speed,
                DeviceAttributes.target_indoor_fan_speed,
                DeviceAttributes.water_pump_running,
                DeviceAttributes.compressor_power,
            ]:
                self.device.set_attribute(attr.value, 1)
            mock_build_send.assert_not_called()

    def test_set_target_temperature(self) -> None:
        """Test set target temperature."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_target_temperature(22.5, 1)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.target_temperature == 22.5
            assert message.mode == 1
            assert message.power
            self.device._used_subprotocol = True
            self.device.set_target_temperature(22.5, 1)

    def test_process_message_ignores_stale_c0_temperatures_after_new_protocol(
        self,
    ) -> None:
        """After 0x7e temperatures are seen, stale C0 temperatures are ignored."""
        new_protocol_msg = SimpleNamespace(
            body_type=ListTypes.B5,
            has_new_protocol_temperature=True,
            power=True,
            target_temperature=27.0,
            indoor_temperature=28.8,
            outdoor_temperature=None,
        )
        stale_c0_msg = SimpleNamespace(
            body_type=ListTypes.C0,
            power=True,
            target_temperature=16.0,
            indoor_temperature=4.2,
            outdoor_temperature=None,
        )

        with patch(
            "midealan.devices.ac.MessageACResponse",
            side_effect=[new_protocol_msg, stale_c0_msg],
        ):
            first = self.device.process_message(b"")
            assert first[DeviceAttributes.target_temperature.value] == 27.0
            assert first[DeviceAttributes.indoor_temperature.value] == 28.8

            second = self.device.process_message(b"")
            assert DeviceAttributes.target_temperature.value not in second
            assert DeviceAttributes.indoor_temperature.value not in second
            assert self.device.attributes[DeviceAttributes.target_temperature] == 27.0
            assert self.device.attributes[DeviceAttributes.indoor_temperature] == 28.8

    @staticmethod
    def _new_protocol_temperature_response() -> bytes:
        """Build a B1 query frame carrying a valid 0x7e temperature payload."""
        body = bytearray(62)
        body[0] = 0xB1
        body[1] = 0x01  # one property
        body[2] = 0x7E  # tag 0x7e, low byte
        body[3] = 0x00  # tag 0x7e, high byte
        body[4] = 0x00  # fixed byte of the 5-byte pack
        body[5] = 0x38  # payload length: 56
        payload = bytearray(56)
        payload[1] = 0x1D  # 26.0 C setpoint
        payload[40] = 0x6A  # 28.8 C indoor temperature
        payload[41] = 0x08
        body[6 : 6 + len(payload)] = payload
        header = bytearray([0xAA, 0, 0xAC, 0, 0, 0, 0, 0, 1, 3])
        header[1] = len(header) + len(body)
        frame = header + body
        frame.append(MessageBase.checksum(frame[1:]))
        return bytes(frame)

    def test_process_message_0x7e_temperatures_are_gated_by_model(self) -> None:
        """Only model 22013279 takes temperatures from the 0x7e tag."""
        frame = self._new_protocol_temperature_response()

        # The gate is deliberately model-only, including subtype 1 which was
        # not among the prior subtype allowlist values.
        for subtype in (0, 1, 8):
            device = self._make_device("22013279", subtype)
            status = device.process_message(frame)
            assert status[DeviceAttributes.target_temperature.value] == 26.0
            assert status[DeviceAttributes.indoor_temperature.value] == 28.8
            assert device._prefer_new_protocol_temperature

        # The known 22251759 / 32773 device keeps its C0 temperatures, which
        # include an outdoor reading not available from the 0x7e response.
        other = self._make_device("22251759", 32773)
        status = other.process_message(frame)
        assert DeviceAttributes.target_temperature.value not in status
        assert DeviceAttributes.indoor_temperature.value not in status
        assert not other._prefer_new_protocol_temperature

    def test_power_saving_control(self) -> None:
        """Test power saving control and preset exclusivity."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.power_saving, True)
            message = mock_build_send.call_args[0][0]
            assert message.power_saving
            assert not message.boost_mode
            assert not message.sleep_mode
            assert not message.eco_mode
            assert not message.comfort_mode
            assert not message.frost_protect

            self.device._attributes[DeviceAttributes.power_saving] = True
            self.device.set_target_temperature(22.5, None)
            message = mock_build_send.call_args[0][0]
            assert message.power_saving

            self.device.set_attribute(DeviceAttributes.boost_mode, True)
            message = mock_build_send.call_args[0][0]
            assert message.boost_mode
            assert not message.power_saving

    def test_power_saving_unsupported_for_subprotocol(self) -> None:
        """Test power saving is not sent with the unsupported subprotocol."""
        self.device._used_subprotocol = True
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.power_saving, True)
            mock_build_send.assert_not_called()

    def test_set_swing(self) -> None:
        """Test set swing."""
        with patch.object(self.device, "send_message_v2") as mock_build_send:
            self.device.set_swing(True, False)
            mock_build_send.assert_called()

    def test_set_swing_subprotocol(self) -> None:
        """Test set swing with subprotocol device."""
        self.device._used_subprotocol = True
        with patch.object(self.device, "send_message_v2") as mock_build_send:
            self.device.set_swing(True, False)
            mock_build_send.assert_called()

    def test_self_clean_syncs_from_self_clean_active(self) -> None:
        """Test that self_clean attribute tracks self_clean_active status reports."""
        with patch("midealan.devices.ac.MessageACResponse") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.used_subprotocol = False
            mock_message.power = False
            mock_message.fresh_air_power = False
            mock_message.fresh_air_fan_speed = 0
            mock_message.fresh_air_1 = None
            mock_message.fresh_air_2 = None
            mock_message.swing_vertical = False
            mock_message.indoor_temperature = None
            mock_message.outdoor_temperature = None
            mock_message.indoor_humidity = None
            mock_message.total_energy_consumption = None
            mock_message.current_energy_consumption = None
            mock_message.realtime_power = None

            mock_message.self_clean_active = True
            result = self.device.process_message(b"")
            assert result[DeviceAttributes.self_clean.value] is True
            assert self.device.attributes[DeviceAttributes.self_clean] is True

            mock_message.self_clean_active = False
            result = self.device.process_message(b"")
            assert result[DeviceAttributes.self_clean.value] is False
            assert self.device.attributes[DeviceAttributes.self_clean] is False

    def test_self_clean_ignores_stale_status_after_set(self) -> None:
        """Test stale self-clean status does not undo a pending command."""
        with patch("midealan.devices.ac.MessageACResponse") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.used_subprotocol = False
            mock_message.power = False
            mock_message.fresh_air_power = False
            mock_message.fresh_air_fan_speed = 0
            mock_message.fresh_air_1 = None
            mock_message.fresh_air_2 = None
            mock_message.swing_vertical = False
            mock_message.indoor_temperature = None
            mock_message.outdoor_temperature = None
            mock_message.indoor_humidity = None
            mock_message.total_energy_consumption = None
            mock_message.current_energy_consumption = None
            mock_message.realtime_power = None
            del mock_message.self_clean

            self.device._pending_self_clean = (True, 100.0)
            mock_message.self_clean_active = False
            with patch("midealan.devices.ac.time.monotonic", return_value=101.0):
                result = self.device.process_message(b"")

            assert DeviceAttributes.self_clean.value not in result
            assert self.device.attributes[DeviceAttributes.self_clean] is False
            assert self.device._pending_self_clean == (True, 100.0)

            mock_message.self_clean_active = True
            with patch("midealan.devices.ac.time.monotonic", return_value=102.0):
                result = self.device.process_message(b"")

            assert result[DeviceAttributes.self_clean.value] is True
            assert self.device.attributes[DeviceAttributes.self_clean] is True
            assert self.device._pending_self_clean is None

    def test_self_clean_accepts_status_after_refresh_interval(self) -> None:
        """Test stale-status guard expires after the configured refresh interval."""
        with patch("midealan.devices.ac.MessageACResponse") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.used_subprotocol = False
            mock_message.power = False
            mock_message.fresh_air_power = False
            mock_message.fresh_air_fan_speed = 0
            mock_message.fresh_air_1 = None
            mock_message.fresh_air_2 = None
            mock_message.swing_vertical = False
            mock_message.indoor_temperature = None
            mock_message.outdoor_temperature = None
            mock_message.indoor_humidity = None
            mock_message.total_energy_consumption = None
            mock_message.current_energy_consumption = None
            mock_message.realtime_power = None
            del mock_message.self_clean

            self.device.set_refresh_interval(5)
            self.device._pending_self_clean = (True, 100.0)
            mock_message.self_clean_active = False
            with patch("midealan.devices.ac.time.monotonic", return_value=106.0):
                result = self.device.process_message(b"")

            assert result[DeviceAttributes.self_clean.value] is False
            assert self.device.attributes[DeviceAttributes.self_clean] is False
            assert self.device._pending_self_clean is None

    def test_self_clean_accepts_status_at_refresh_interval_boundary(self) -> None:
        """Test stale-status guard expires exactly at the refresh interval."""
        with patch("midealan.devices.ac.MessageACResponse") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.used_subprotocol = False
            mock_message.power = False
            mock_message.fresh_air_power = False
            mock_message.fresh_air_fan_speed = 0
            mock_message.fresh_air_1 = None
            mock_message.fresh_air_2 = None
            mock_message.swing_vertical = False
            mock_message.indoor_temperature = None
            mock_message.outdoor_temperature = None
            mock_message.indoor_humidity = None
            mock_message.total_energy_consumption = None
            mock_message.current_energy_consumption = None
            mock_message.realtime_power = None
            del mock_message.self_clean

            self.device.set_refresh_interval(5)
            self.device._pending_self_clean = (True, 100.0)
            mock_message.self_clean_active = False
            with patch("midealan.devices.ac.time.monotonic", return_value=105.0):
                result = self.device.process_message(b"")

            assert result[DeviceAttributes.self_clean.value] is False
            assert self.device.attributes[DeviceAttributes.self_clean] is False
            assert self.device._pending_self_clean is None

    def test_set_self_clean_updates_status_after_send(self) -> None:
        """Test self-clean command publishes its requested state after sending."""
        updates: list[dict[str, bool]] = []
        self.device.register_update(updates.append)

        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.self_clean, True)

        mock_build_send.assert_called_once()
        assert self.device.attributes[DeviceAttributes.self_clean] is True
        assert updates == [{DeviceAttributes.self_clean.value: True}]
        assert self.device._pending_self_clean is not None
        assert self.device._pending_self_clean[0] is True

    def test_set_self_clean_does_not_update_when_send_fails(self) -> None:
        """Test a failed self-clean command does not publish the requested state."""
        updates: list[dict[str, bool]] = []
        self.device.register_update(updates.append)

        with (
            patch.object(
                self.device,
                "build_send",
                side_effect=OSError("send failed"),
            ),
            pytest.raises(OSError, match="send failed"),
        ):
            self.device.set_attribute(DeviceAttributes.self_clean, True)

        assert self.device.attributes[DeviceAttributes.self_clean] is False
        assert updates == []
        assert self.device._pending_self_clean is None

    def test_ieco_in_initial_attributes(self) -> None:
        """Test iECO defaults to off and gear 1."""
        assert self.device.attributes[DeviceAttributes.ieco] is False
        assert self.device._ieco_number == 1

    def test_set_ieco_echoes_reported_number(self) -> None:
        """Test setting iECO builds a PropertiesSet echoing the last gear."""
        self.device._ieco_number = 3
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.ieco.value, True)

        message = mock_build_send.call_args[0][0]
        assert message.ieco is True
        assert message.ieco_number == 3

    def test_set_ieco_off(self) -> None:
        """Test turning iECO off builds a PropertiesSet with ieco False."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.ieco.value, False)

        message = mock_build_send.call_args[0][0]
        assert message.ieco is False

    def test_process_message_captures_ieco_state_and_number(self) -> None:
        """Test process_message publishes iECO state and records its gear."""
        with patch("midealan.devices.ac.MessageACResponse") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.used_subprotocol = False
            mock_message.fresh_air_power = False
            mock_message.ieco = True
            mock_message.ieco_number = 5

            result = self.device.process_message(b"")

        assert result[DeviceAttributes.ieco.value] is True
        assert self.device._ieco_number == 5

    def test_invalid_customize_format(self) -> None:
        """Test invalid customize format."""
        self.device.set_customize("{")

    def test_customize_capabilities_legacy_dict_format(self) -> None:
        """Test customize with legacy dict format converts to array format."""
        customize_str = """{
            "capabilities": {
                "modes": {"heat": true, "cool": true, "dry": false, "auto": true},
                "fan_speeds": {
                    "silent": false, "low": true, "medium": true, "high": true
                },
                "swing_modes": {"vertical": true, "horizontal": false, "both": true}
            }
        }"""
        self.device.set_customize(customize_str)

        # Legacy dict format should be converted to array format
        assert self.device.capabilities["modes"] == ["heat", "cool", "auto"]
        assert self.device.capabilities["fan_speeds"] == ["low", "medium", "high"]
        assert self.device.capabilities["swing_modes"] == ["vertical", "both"]

    def test_customize_capabilities_array_format(self) -> None:
        """Test customize with array format works directly."""
        customize_str = """{
            "capabilities": {
                "modes": ["heat", "cool"],
                "fan_speeds": ["low", "high", "auto"],
                "swing_modes": ["vertical"]
            }
        }"""
        self.device.set_customize(customize_str)

        # Array format should be used as-is
        assert self.device.capabilities["modes"] == ["heat", "cool"]
        assert self.device.capabilities["fan_speeds"] == ["low", "high", "auto"]
        assert self.device.capabilities["swing_modes"] == ["vertical"]

    def test_customize_capabilities_invalid_format_skipped(self) -> None:
        """Test customize with invalid format is skipped with warning."""
        customize_str = """{
            "capabilities": {
                "modes": "invalid_string_not_dict_or_list",
                "fan_speeds": 123,
                "other_capability": true
            }
        }"""
        self.device.set_customize(customize_str)

        # Invalid formats should be skipped and not set
        assert "modes" not in self.device._customize_capabilities
        assert "fan_speeds" not in self.device._customize_capabilities
        # Other valid capabilities should still be set
        assert self.device._customize_capabilities.get("other_capability") is True

    def test_customize_capabilities_mixed_valid_invalid(self) -> None:
        """Test customize with mix of valid and invalid capability formats."""
        customize_str = """{
            "capabilities": {
                "modes": ["heat", "cool"],
                "fan_speeds": "invalid",
                "other_capability": true
            }
        }"""
        self.device.set_customize(customize_str)

        # Valid formats should be applied
        assert self.device.capabilities["modes"] == ["heat", "cool"]
        # Other capabilities should remain as-is
        assert self.device.capabilities["other_capability"] is True

    def test_customize_capabilities_array_with_non_string_elements(self) -> None:
        """Test customize rejects arrays containing non-string elements."""
        customize_str = """{
            "capabilities": {
                "modes": ["heat", 123, "cool"],
                "fan_speeds": [1, 2, 3],
                "other_capability": true
            }
        }"""
        self.device.set_customize(customize_str)

        # Arrays with non-string elements should be rejected and not set
        assert "modes" not in self.device._customize_capabilities
        assert "fan_speeds" not in self.device._customize_capabilities
        # Other valid capabilities should still be set
        assert self.device._customize_capabilities.get("other_capability") is True


class TestHASupportProperties:
    """Test Home Assistant integration support properties."""

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Set up test device."""
        self.device = MideaACDevice(
            name="Test AC",
            device_id=123456789012345,
            ip_address="192.168.1.100",
            port=6444,
            token="AA" * 40,
            key="BB" * 16,
            device_protocol=ProtocolVersion.V3,
            model="test_model",
            subtype=0,
            customize="",
        )

    def test_supported_hvac_modes_all_modes(self) -> None:
        """Test supported_hvac_modes with all modes available."""
        self.device._capabilities = {
            "modes": ["auto", "cool", "heat", "dry"],
        }
        expected = ["off", "auto", "cool", "heat", "dry"]
        assert self.device.supported_hvac_modes == expected

    def test_supported_hvac_modes_partial_modes(self) -> None:
        """Test supported_hvac_modes with only some modes available."""
        self.device._capabilities = {
            "modes": ["cool", "heat"],
        }
        expected = ["off", "cool", "heat"]
        assert self.device.supported_hvac_modes == expected

    def test_supported_hvac_modes_no_cool(self) -> None:
        """Test supported_hvac_modes for heat-only device."""
        self.device._capabilities = {
            "modes": ["heat", "auto"],
        }
        expected = ["off", "auto", "heat"]
        assert self.device.supported_hvac_modes == expected

    def test_supported_hvac_modes_with_fan_only(self) -> None:
        """Test supported_hvac_modes includes fan_only when enabled in customize."""
        self.device._capabilities = {
            "modes": ["cool", "heat"],
        }
        self.device._customize_capabilities = {
            "fan_only": True,
        }
        expected = ["off", "cool", "heat", "fan_only"]
        assert self.device.supported_hvac_modes == expected

    def test_supported_hvac_modes_empty_capabilities(self) -> None:
        """Test supported_hvac_modes with empty capabilities.

        Returns default full set.
        """
        self.device._capabilities = {}
        expected = ["off", "auto", "cool", "heat", "dry"]
        assert self.device.supported_hvac_modes == expected

    def test_supported_hvac_modes_customize_override(self) -> None:
        """Test supported_hvac_modes respects customize overrides."""
        self.device._capabilities = {
            "modes": ["auto", "cool", "heat", "dry"],
        }
        self.device._customize_capabilities = {
            "modes": ["cool", "heat"],
        }
        # customize overrides B5 capabilities
        expected = ["off", "cool", "heat"]
        assert self.device.supported_hvac_modes == expected

    def test_supported_fan_modes_all_speeds(self) -> None:
        """Test supported_fan_modes with all speeds available."""
        self.device._capabilities = {
            "fan_speeds": ["auto", "silent", "low", "medium", "high", "custom"],
        }
        expected = ["auto", "silent", "low", "medium", "high", "custom"]
        assert self.device.supported_fan_modes == expected

    def test_supported_fan_modes_partial_speeds(self) -> None:
        """Test supported_fan_modes with only some speeds available."""
        self.device._capabilities = {
            "fan_speeds": ["auto", "low", "high"],
        }
        expected = ["auto", "low", "high"]
        assert self.device.supported_fan_modes == expected

    def test_supported_fan_modes_no_silent(self) -> None:
        """Test supported_fan_modes without silent speed."""
        self.device._capabilities = {
            "fan_speeds": ["auto", "low", "medium", "high"],
        }
        expected = ["auto", "low", "medium", "high"]
        assert self.device.supported_fan_modes == expected

    def test_supported_fan_modes_empty_capabilities(self) -> None:
        """Test supported_fan_modes with empty capabilities.

        Returns default full set.
        """
        self.device._capabilities = {}
        expected: list[str] = ["auto", "silent", "low", "medium", "high", "custom"]
        assert self.device.supported_fan_modes == expected

    def test_supported_fan_modes_customize_override(self) -> None:
        """Test supported_fan_modes respects customize overrides."""
        self.device._capabilities = {
            "fan_speeds": ["auto", "silent", "low", "medium", "high"],
        }
        self.device._customize_capabilities = {
            "fan_speeds": ["auto", "low", "high"],
        }
        # customize overrides B5 capabilities
        expected = ["auto", "low", "high"]
        assert self.device.supported_fan_modes == expected

    def test_supported_fan_modes_custom_returns_full_set(self) -> None:
        """Test supported_fan_modes returns full set when custom is present."""
        self.device._capabilities = {
            "fan_speeds": ["auto", "custom"],
        }
        # custom in list means return full set
        expected = ["auto", "silent", "low", "medium", "high", "custom"]
        assert self.device.supported_fan_modes == expected

    def test_supported_fan_modes_custom_in_customize(self) -> None:
        """Test supported_fan_modes with custom in customize returns only custom."""
        self.device._customize_capabilities = {
            "fan_speeds": ["custom"],
        }
        # custom in customize is explicit user config, only return what's specified
        expected = ["custom"]
        assert self.device.supported_fan_modes == expected

    def test_supported_swing_modes_both_directions(self) -> None:
        """Test supported_swing_modes with both directions available."""
        self.device._capabilities = {
            "swing_modes": ["vertical", "horizontal"],
        }
        expected = ["off", "vertical", "horizontal", "both"]
        assert self.device.supported_swing_modes == expected

    def test_supported_swing_modes_vertical_only(self) -> None:
        """Test supported_swing_modes with only vertical available."""
        self.device._capabilities = {
            "swing_modes": ["vertical"],
        }
        expected = ["off", "vertical"]
        assert self.device.supported_swing_modes == expected

    def test_supported_swing_modes_horizontal_only(self) -> None:
        """Test supported_swing_modes with only horizontal available."""
        self.device._capabilities = {
            "swing_modes": ["horizontal"],
        }
        expected = ["off", "horizontal"]
        assert self.device.supported_swing_modes == expected

    def test_supported_swing_modes_none(self) -> None:
        """Test supported_swing_modes with no swing support.

        Returns default full set.
        """
        self.device._capabilities = {}
        expected = ["off", "vertical", "horizontal", "both"]
        assert self.device.supported_swing_modes == expected

    def test_supported_swing_modes_customize_override(self) -> None:
        """Test supported_swing_modes respects customize overrides."""
        self.device._capabilities = {
            "swing_modes": ["vertical", "horizontal"],
        }
        self.device._customize_capabilities = {
            "swing_modes": ["vertical"],
        }
        # customize overrides B5 capabilities
        expected = ["off", "vertical"]
        assert self.device.supported_swing_modes == expected

    def test_supported_preset_modes_all_features(self) -> None:
        """Test supported_preset_modes with all features available."""
        self.device._capabilities = {
            "modes": ["auto", "cool", "heat"],  # B5 indicator
            "eco_mode": True,
            "turbo_cool": True,
            "turbo_heat": True,
            "sleep_mode": True,
            "comfort_mode": True,
        }
        expected = ["none", "comfort", "eco", "boost", "sleep"]
        assert self.device.supported_preset_modes == expected

    def test_supported_preset_modes_eco_only(self) -> None:
        """Test supported_preset_modes with only eco available."""
        self.device._capabilities = {
            "modes": ["cool"],  # B5 indicator
            "eco_mode": True,
        }
        # comfort and sleep are always available (no B5 flag)
        expected = ["none", "comfort", "eco", "sleep"]
        assert self.device.supported_preset_modes == expected

    def test_supported_preset_modes_ieco(self) -> None:
        """Test supported_preset_modes with ieco (independent preset)."""
        self.device._capabilities = {
            "modes": ["cool"],  # B5 indicator
            "ieco": True,
        }
        # comfort and sleep are always available (no B5 flag)
        # ieco is a separate preset from eco
        expected = ["none", "comfort", "sleep", "ieco"]
        assert self.device.supported_preset_modes == expected

    def test_supported_preset_modes_eco_and_ieco(self) -> None:
        """Test supported_preset_modes with both eco and ieco modes.

        eco_mode and ieco are independent presets (not the same).
        """
        self.device._capabilities = {
            "modes": ["cool"],  # B5 indicator
            "eco_mode": True,
            "ieco": True,
        }
        # comfort and sleep are always available (no B5 flag)
        # eco and ieco are both present as separate presets
        expected = ["none", "comfort", "eco", "sleep", "ieco"]
        assert self.device.supported_preset_modes == expected

    def test_supported_preset_modes_turbo_cool_only(self) -> None:
        """Test supported_preset_modes with only turbo_cool (maps to boost)."""
        self.device._capabilities = {
            "modes": ["cool"],  # B5 indicator
            "turbo_cool": True,
        }
        # comfort and sleep are always available (no B5 flag)
        expected = ["none", "comfort", "boost", "sleep"]
        assert self.device.supported_preset_modes == expected

    def test_supported_preset_modes_turbo_heat_only(self) -> None:
        """Test supported_preset_modes with only turbo_heat (maps to boost)."""
        self.device._capabilities = {
            "modes": ["heat"],  # B5 indicator
            "turbo_heat": True,
        }
        # comfort and sleep are always available (no B5 flag)
        expected = ["none", "comfort", "boost", "sleep"]
        assert self.device.supported_preset_modes == expected

    def test_supported_preset_modes_both_turbo(self) -> None:
        """Test supported_preset_modes with both turbo modes (single boost preset)."""
        self.device._capabilities = {
            "modes": ["cool", "heat"],  # B5 indicator
            "turbo_cool": True,
            "turbo_heat": True,
        }
        # comfort and sleep are always available (no B5 flag)
        expected = ["none", "comfort", "boost", "sleep"]
        assert self.device.supported_preset_modes == expected

    def test_supported_preset_modes_empty_capabilities(self) -> None:
        """Test supported_preset_modes with empty capabilities.

        Returns default basic set (without B5-only presets).
        """
        self.device._capabilities = {}
        expected = ["none", "comfort", "eco", "boost", "sleep"]
        assert self.device.supported_preset_modes == expected

    def test_supported_preset_modes_partial_features(self) -> None:
        """Test supported_preset_modes with some features available."""
        self.device._capabilities = {
            "modes": ["cool"],  # B5 indicator
            "eco_mode": True,
            "sleep_mode": True,
        }
        # comfort and sleep are always available (no B5 flag)
        expected = ["none", "comfort", "eco", "sleep"]
        assert self.device.supported_preset_modes == expected

    def test_supported_preset_modes_customize_priority(self) -> None:
        """Test supported_preset_modes with customize override."""
        self.device._capabilities = {
            "modes": ["cool"],
            "eco_mode": True,
        }
        self.device._customize_capabilities = {
            "eco_mode": False,  # Disable eco via customize
            "turbo_cool": True,  # Enable boost via customize
        }
        # customize overrides B5 capabilities
        expected = ["none", "comfort", "boost", "sleep"]
        assert self.device.supported_preset_modes == expected

    def test_supported_preset_modes_customize_with_ieco(self) -> None:
        """Test supported_preset_modes customize with ieco."""
        self.device._customize_capabilities = {
            "ieco": True,
            "comfort_mode": False,  # Disable comfort
        }
        # customize controls all presets
        expected = ["none", "sleep", "ieco"]
        assert self.device.supported_preset_modes == expected

    def test_supported_preset_modes_customize_enable_eco(self) -> None:
        """Test supported_preset_modes customize enables eco."""
        self.device._customize_capabilities = {
            "eco_mode": True,  # Enable eco via customize
            "sleep_mode": True,  # Explicitly enable sleep
        }
        # customize with eco and explicit sleep
        expected = ["none", "comfort", "eco", "sleep"]
        assert self.device.supported_preset_modes == expected

    def test_supported_preset_modes_customize_disable_sleep(self) -> None:
        """Test supported_preset_modes customize disables sleep."""
        self.device._customize_capabilities = {
            "sleep_mode": False,  # Explicitly disable sleep
        }
        # customize with sleep disabled
        expected = ["none", "comfort"]
        assert self.device.supported_preset_modes == expected

    def test_supported_hvac_modes_customize_with_fan_only(self) -> None:
        """Test supported_hvac_modes customize modes with fan_only enabled."""
        self.device._customize_capabilities = {
            "modes": ["cool", "heat"],
            "fan_only": True,
        }
        # customize modes + fan_only enabled
        expected = ["off", "cool", "heat", "fan_only"]
        assert self.device.supported_hvac_modes == expected

    def test_supported_hvac_modes_default_with_fan_only(self) -> None:
        """Test supported_hvac_modes default set with fan_only enabled."""
        self.device._capabilities = {}
        self.device._customize_capabilities = {
            "fan_only": True,
        }
        # default full set + fan_only (no modes in customize or B5)
        expected = ["off", "auto", "cool", "heat", "dry", "fan_only"]
        assert self.device.supported_hvac_modes == expected

    def test_supported_swing_modes_customize_horizontal_only(self) -> None:
        """Test supported_swing_modes customize with horizontal only."""
        self.device._customize_capabilities = {
            "swing_modes": ["horizontal"],
        }
        expected = ["off", "horizontal"]
        assert self.device.supported_swing_modes == expected

    def test_supported_swing_modes_customize_both(self) -> None:
        """Test supported_swing_modes customize with both directions."""
        self.device._customize_capabilities = {
            "swing_modes": ["vertical", "horizontal"],
        }
        expected = ["off", "vertical", "horizontal", "both"]
        assert self.device.supported_swing_modes == expected

    def test_supported_preset_modes_b5_without_modes_key(self) -> None:
        """Test supported_preset_modes B5 capabilities without modes key.

        Falls through to default basic set.
        """
        self.device._capabilities = {
            "eco_mode": True,  # capabilities present but no "modes" key
        }
        # No "modes" key means not a valid B5 preset indicator
        # falls through to default basic set
        expected = ["none", "comfort", "eco", "boost", "sleep"]
        assert self.device.supported_preset_modes == expected

    def test_build_query_single_capability_batch(self) -> None:
        """Test build_query builds one PropertiesCapsQuery for the real pool.

        The allowlist limits the dynamic pool to at most 11 tags today, so a
        realistic device fills only the first batch (PropertiesCapsQuery).
        """
        self.device._used_subprotocol = False
        capabilities = cast(
            "dict[str, CapabilityValue]",
            {
                "self_clean": True,
                "rate_select": True,
                "out_silent": True,
                "ieco": True,
                "sound": True,
                "anion": True,
                "gentle_wind_sense": True,
                "temperature": True,  # capability-only, excluded from B1
                "indirect_wind": True,  # default property, excluded
                "fresh_air_1": True,  # default property, excluded
            },
        )
        self.device._capabilities = capabilities
        queries = self.device.build_query()

        batch1 = [q for q in queries if isinstance(q, PropertiesCapsQuery)]
        batch2 = [q for q in queries if isinstance(q, PropertiesCapsQuery1)]
        assert len(batch1) == 1
        # Real pool never exceeds one batch, so batch 2 is not built.
        assert len(batch2) == 0
        # Decode the queried tags from the body: [count, lo, hi, lo, hi, ...].
        body = batch1[0]._body
        queried = {body[i] | (body[i + 1] << 8) for i in range(1, len(body), 2)}
        # Capability-only tag must never leak into the B1 query.
        assert int(CapabilityTag.temperature) not in queried
        assert int(CapabilityTag.self_clean) in queried

    def test_build_query_debug_log_lists_property_names(
        self,
        caplog: pytest.LogCaptureFixture,
    ) -> None:
        """Test build_query debug logs list the actual property names per query."""
        self.device._used_subprotocol = False
        self.device._capabilities = cast(
            "dict[str, CapabilityValue]",
            {"self_clean": True, "sound": True},
        )
        with caplog.at_level(logging.DEBUG):
            self.device.build_query()

        debug_messages = [
            record.message
            for record in caplog.records
            if record.levelno == logging.DEBUG
        ]
        joined = "\n".join(debug_messages)
        # Default query logs count and each default property by name.
        assert "PropertiesDefaultQuery: 8 properties" in joined
        assert "indirect_wind(0x0042)" in joined
        # Capability batch logs count and its collected properties by name.
        assert "PropertiesCapsQuery: 2 properties" in joined
        assert "self_clean(0x0039)" in joined
        assert "sound(0x022C)" in joined

    def test_build_query_with_two_capability_batches(self) -> None:
        """Test build_query splits an oversized pool into two batches.

        The dynamic pool cannot exceed one batch with the current allowlist, so
        the collector is patched to simulate future growth past the batch-1
        limit.
        """
        self.device._used_subprotocol = False
        self.device._capabilities = cast(
            "dict[str, CapabilityValue]",
            {"self_clean": True},
        )
        # 15 synthetic property tags -> batch 1 (9) + batch 2 (6).
        pool = list(range(0x0300, 0x0300 + 15))
        with patch(
            "midealan.devices.ac._PropertiesCapsQueryBase"
            ".collect_capability_properties",
            return_value=pool,
        ):
            queries = self.device.build_query()

        batch1 = [q for q in queries if isinstance(q, PropertiesCapsQuery)]
        batch2 = [q for q in queries if isinstance(q, PropertiesCapsQuery1)]
        assert len(batch1) == 1
        assert len(batch2) == 1
        assert batch1[0]._body[0] == 9  # first 9 properties
        assert batch2[0]._body[0] == 6  # remaining 6 properties

    def test_build_query_warns_on_excessive_properties(
        self,
        caplog: pytest.LogCaptureFixture,
    ) -> None:
        """Test build_query warns when the pool exceeds total batch capacity."""
        self.device._used_subprotocol = False
        self.device._capabilities = cast(
            "dict[str, CapabilityValue]",
            {"self_clean": True},
        )
        # 30 synthetic tags exceed the 18-tag (2 x 9) capacity.
        pool = list(range(0x0300, 0x0300 + 30))
        with (
            patch(
                "midealan.devices.ac._PropertiesCapsQueryBase"
                ".collect_capability_properties",
                return_value=pool,
            ),
            caplog.at_level(logging.WARNING),
        ):
            queries = self.device.build_query()

        # Only two batches are built; excess tags are dropped.
        batch1 = [q for q in queries if isinstance(q, PropertiesCapsQuery)]
        batch2 = [q for q in queries if isinstance(q, PropertiesCapsQuery1)]
        assert len(batch1) == 1
        assert len(batch2) == 1
        warning_messages = [
            record.message
            for record in caplog.records
            if record.levelno == logging.WARNING
        ]
        assert any("exceed" in msg.lower() for msg in warning_messages)
