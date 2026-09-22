"""Test ac message."""

import logging
from typing import cast

import pytest

from midealan.const import ProtocolVersion
from midealan.crc8 import calculate
from midealan.devices.ac.message import (
    _B1_DEFAULT_PROPERTIES,
    _B1_MAX_CAPABILITY_BATCHES,
    _B1_MAX_PROPERTIES_PER_BATCH,
    A0_A1_C0_MIN_BODY_LENGTH,
    CAPABILITY_ONLY_TAGS,
    COMMON_TAGS,
    CONFORT_MODE_MIN_LENGTH2,
    FROST_PROTECT_MIN_LENGTH,
    PROPERTIES_TAGS,
    SMART_DRY_MIN_LENGTH,
    CapabilitiesQuery,
    CapabilityBody,
    CapabilityTag,
    CapabilityValue,
    GroupDataQuery,
    GroupOneQuery,
    GroupSevenQuery,
    GroupTwoQuery,
    GroupZeroQuery,
    HumidityQuery,
    MessageA0LongQuery,
    MessageA0Query,
    MessageACBase,
    MessageACResponse,
    MessageSubProtocol,
    MessageSubProtocolSet,
    PowerFormats,
    PowerQuery,
    PropertiesCapsQuery,
    PropertiesCapsQuery1,
    PropertiesDefaultQuery,
    PropertiesSet,
    StateQuery,
    StateSet,
    SubProtocolFreshAirSet,
    SubProtocolQuery10,
    SubProtocolQuery11,
    SubProtocolQuery30,
    ToggleDisplay,
    _PropertiesCapsQueryBase,
    format_property_tags,
)
from midealan.message import ListTypes, MessageBase, MessageType


class TestMessageACBase:
    """Test AC Message Base."""

    def test_message_id_increment(self) -> None:
        """Test message Id Increment."""
        msg = MessageACBase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )
        msg2 = MessageACBase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )
        assert msg2._message_id == msg._message_id + 1
        # test reset
        for _ in range(254 - msg2._message_id):
            msg = MessageACBase(
                protocol_version=ProtocolVersion.V1,
                message_type=MessageType.query,
                body_type=ListTypes.X01,
            )
        assert msg._message_id == 1

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageACBase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test Message Query."""

    def test_query_body(self) -> None:
        """Test query body."""
        msg = StateQuery(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray(
            [
                0x41,
                0x81,
                0x00,
                0xFF,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
            ],
        )
        assert msg.body[:-2] == expected_body


class TestCapabilitiesQuery:
    """Test Message Capabilities Query."""

    def test_capabilities_query_body(self) -> None:
        """Test capabilities query body."""
        msg = CapabilitiesQuery(ProtocolVersion.V1, False)
        expected_body = bytearray(
            [0xB5, 0x01, 0x00],
        )
        assert msg.body[:-2] == expected_body

    def test_capabilities_query_body_additional(self) -> None:
        """Test capabilities query body."""
        msg = CapabilitiesQuery(ProtocolVersion.V1, True)
        expected_body = bytearray(
            [0xB5, 0x01, 0x01, 0x01],
        )
        assert msg.body[:-2] == expected_body


class TestMessageA0Query:
    """Test Message A0 Query."""

    def test_a0_query_body(self) -> None:
        """Test A0 query body."""
        msg = MessageA0Query(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0xA0, 0xA7])
        assert msg.body[:2] == expected_body
        assert len(msg.body) == 4  # body type + query + message id + crc

    def test_a0_long_query_body(self) -> None:
        """Test A0 long query body."""
        msg = MessageA0LongQuery(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0xA0] + [0x00] * 19)
        assert msg.body[:-2] == expected_body


class TestPowerQuery:
    """Test Message Power Query."""

    def test_power_query_body(self) -> None:
        """Test power query body."""
        msg = PowerQuery(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0x41, 0x21, 0x01, 0x44, 0x00, 0x01])
        assert msg.body[:-1] == expected_body


class TestGroupDataQuery:
    """Test Message Group Data Query."""

    @pytest.mark.parametrize(
        ("message_class", "group"),
        [
            (GroupZeroQuery, 0),
            (GroupOneQuery, 1),
            (GroupTwoQuery, 2),
            (PowerQuery, 4),
            (HumidityQuery, 5),
            (GroupSevenQuery, 7),
        ],
    )
    def test_group_query_body(
        self,
        message_class: type[GroupDataQuery],
        group: int,
    ) -> None:
        """Test that every group query encodes its group number."""
        msg = message_class(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0x41, 0x21, 0x01, 0x40 | group, 0x00, 0x01])
        assert msg.body[:-1] == expected_body


class TestGroupZeroQuery:
    """Test Message Group Zero Query."""

    def test_group_zero_query_body(self) -> None:
        """Test group zero query body."""
        msg = GroupZeroQuery(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0x41, 0x21, 0x01, 0x40, 0x00, 0x01])
        assert msg.body[:-1] == expected_body


class TestHumidityQuery:
    """Test Message Humidity Query."""

    def test_humidity_query_body(self) -> None:
        """Test humidity query body."""
        msg = HumidityQuery(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0x41, 0x21, 0x01, 0x45, 0x00, 0x01])
        assert msg.body[:-1] == expected_body


class TestToggleDisplay:
    """Test Message Toggle Display."""

    def test_toggle_disply_body(self) -> None:
        """Test toggle display body."""
        msg = ToggleDisplay(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray(
            [
                0x41,
                0x02,
                0x00,
                0xFF,
                0x02,
                0x00,
                0x02,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
            ],
        )
        assert msg.body[:-2] == expected_body
        msg.prompt_tone = True
        expected_body = bytearray(
            [
                0x41,
                0x02 | 0x40,
                0x00,
                0xFF,
                0x02,
                0x00,
                0x02,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
            ],
        )
        assert msg.body[:-2] == expected_body


class TestNewProtocolQuery:
    """Test Message New Protocol Query."""

    def test_new_protocol_default_query_body(self) -> None:
        """Test new protocol default query body contains only default properties.

        PropertiesDefaultQuery includes 8 fixed default properties and never
        includes capability-based properties.
        """
        msg = PropertiesDefaultQuery(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray(
            [
                0xB1,
                0x08,  # params count (8 default properties)
                CapabilityTag.indirect_wind & 0xFF,
                CapabilityTag.indirect_wind >> 8,
                CapabilityTag.breezeless & 0xFF,
                CapabilityTag.breezeless >> 8,
                CapabilityTag.indoor_humidity & 0xFF,
                CapabilityTag.indoor_humidity >> 8,
                CapabilityTag.screen_display & 0xFF,
                CapabilityTag.screen_display >> 8,
                CapabilityTag.fresh_air_1 & 0xFF,
                CapabilityTag.fresh_air_1 >> 8,
                CapabilityTag.fresh_air_2 & 0xFF,
                CapabilityTag.fresh_air_2 >> 8,
                CapabilityTag.wind_lr_angle & 0xFF,
                CapabilityTag.wind_lr_angle >> 8,
                CapabilityTag.wind_ud_angle & 0xFF,
                CapabilityTag.wind_ud_angle >> 8,
            ],
        )

        assert msg.body[:-2] == expected_body

    def test_new_protocol_caps_query1_with_rate_select(self) -> None:
        """Test PropertiesCapsQuery includes rate_select when provided."""
        msg = PropertiesCapsQuery(
            protocol_version=ProtocolVersion.V1,
            properties_subset=[int(CapabilityTag.rate_select)],
        )
        expected_body = bytearray(
            [
                0xB1,
                0x01,  # params count
                CapabilityTag.rate_select & 0xFF,
                CapabilityTag.rate_select >> 8,
            ],
        )

        assert msg.body[:-2] == expected_body

    def test_new_protocol_caps_query1_with_self_clean(self) -> None:
        """Test PropertiesCapsQuery includes self_clean when provided."""
        msg = PropertiesCapsQuery(
            protocol_version=ProtocolVersion.V1,
            properties_subset=[int(CapabilityTag.self_clean)],
        )
        expected_body = bytearray(
            [
                0xB1,
                0x01,  # params count
                CapabilityTag.self_clean & 0xFF,
                CapabilityTag.self_clean >> 8,
            ],
        )

        assert msg.body[:-2] == expected_body

    def test_new_protocol_caps_query1_with_multiple_properties(self) -> None:
        """Test PropertiesCapsQuery includes multiple capability properties."""
        msg = PropertiesCapsQuery(
            protocol_version=ProtocolVersion.V1,
            properties_subset=[
                int(CapabilityTag.self_clean),
                int(CapabilityTag.rate_select),
                int(CapabilityTag.sound),
            ],
        )
        # Properties are sorted by tag value in the query
        expected_body = bytearray(
            [
                0xB1,
                0x03,  # params count
                CapabilityTag.self_clean & 0xFF,
                CapabilityTag.self_clean >> 8,
                CapabilityTag.rate_select & 0xFF,
                CapabilityTag.rate_select >> 8,
                CapabilityTag.sound & 0xFF,
                CapabilityTag.sound >> 8,
            ],
        )

        assert msg.body[:-2] == expected_body

    def test_new_protocol_caps_query2_independent_properties(self) -> None:
        """Test PropertiesCapsQuery1 (batch 2) is independent from batch 1."""
        msg = PropertiesCapsQuery1(
            protocol_version=ProtocolVersion.V1,
            properties_subset=[int(CapabilityTag.out_silent)],
        )
        expected_body = bytearray(
            [
                0xB1,
                0x01,  # params count
                CapabilityTag.out_silent & 0xFF,
                CapabilityTag.out_silent >> 8,
            ],
        )

        assert msg.body[:-2] == expected_body

    def test_new_protocol_query_body_blocks_degerming_poisoner(self) -> None:
        """Test degerming is never collected for a B1 query (poisoner tag).

        A B1 query carrying 0x5A makes the device answer with an empty
        parameter list, which suppresses every other tag in the request; the
        tag therefore stays out of PROPERTIES_TAGS and can never enter a B1
        query. The degerming state is read from the 0x7e payload instead.
        """
        assert int(CapabilityTag.degerming) not in PROPERTIES_TAGS
        assert int(CapabilityTag.degerming) in CAPABILITY_ONLY_TAGS

        collected = _PropertiesCapsQueryBase.collect_capability_properties(
            cast("dict[str, CapabilityValue]", {"degerming": True, "self_clean": True}),
        )
        assert int(CapabilityTag.degerming) not in collected
        assert int(CapabilityTag.self_clean) in collected

    def test_new_protocol_caps_query_empty_subset(self) -> None:
        """Test PropertiesCapsQuery with empty subset produces empty query."""
        msg = PropertiesCapsQuery(
            protocol_version=ProtocolVersion.V1,
            properties_subset=[],
        )
        expected_body = bytearray(
            [
                0xB1,
                0x00,  # params count (0)
            ],
        )

        assert msg.body[:-2] == expected_body

    def test_default_properties_constant_has_expected_tags(self) -> None:
        """Test _B1_DEFAULT_PROPERTIES constant contains expected tags."""
        assert len(_B1_DEFAULT_PROPERTIES) == 8
        assert int(CapabilityTag.indirect_wind) in _B1_DEFAULT_PROPERTIES
        assert int(CapabilityTag.breezeless) in _B1_DEFAULT_PROPERTIES
        assert int(CapabilityTag.indoor_humidity) in _B1_DEFAULT_PROPERTIES
        assert int(CapabilityTag.screen_display) in _B1_DEFAULT_PROPERTIES
        assert int(CapabilityTag.fresh_air_1) in _B1_DEFAULT_PROPERTIES
        assert int(CapabilityTag.fresh_air_2) in _B1_DEFAULT_PROPERTIES
        assert int(CapabilityTag.wind_lr_angle) in _B1_DEFAULT_PROPERTIES
        assert int(CapabilityTag.wind_ud_angle) in _B1_DEFAULT_PROPERTIES

    def test_max_properties_constants(self) -> None:
        """Test max properties constants are correctly defined."""
        assert _B1_MAX_PROPERTIES_PER_BATCH == 11
        assert _B1_MAX_CAPABILITY_BATCHES == 2


class TestTagDatasets:
    """Test the COMMON/PROPERTIES/CAPABILITY_ONLY tag datasets."""

    def test_dataset_sizes(self) -> None:
        """Test each dataset has the expected number of tags."""
        assert len(COMMON_TAGS) == 14
        assert len(PROPERTIES_TAGS) == 19
        assert len(CAPABILITY_ONLY_TAGS) == 23

    def test_common_tags_included_in_properties(self) -> None:
        """Test COMMON_TAGS is a subset of PROPERTIES_TAGS."""
        assert COMMON_TAGS <= PROPERTIES_TAGS

    def test_common_tags_excluded_from_capability_only(self) -> None:
        """Test COMMON_TAGS never appears in CAPABILITY_ONLY_TAGS."""
        assert COMMON_TAGS.isdisjoint(CAPABILITY_ONLY_TAGS)

    def test_properties_and_capability_only_disjoint(self) -> None:
        """Test the B1 allowlist and capability-only sets never overlap."""
        assert PROPERTIES_TAGS.isdisjoint(CAPABILITY_ONLY_TAGS)

    def test_defaults_are_properties(self) -> None:
        """Test every default property is in the B1 allowlist."""
        assert set(_B1_DEFAULT_PROPERTIES) <= PROPERTIES_TAGS

    def test_properties_extras_present(self) -> None:
        """Test midea-lan property extras are in the allowlist."""
        assert int(CapabilityTag.screen_display) in PROPERTIES_TAGS
        assert int(CapabilityTag.fresh_air_1) in PROPERTIES_TAGS
        assert int(CapabilityTag.error_code) in PROPERTIES_TAGS
        assert int(CapabilityTag.indoor_humidity) in PROPERTIES_TAGS
        assert int(CapabilityTag.prompt_tone) in PROPERTIES_TAGS

    def test_capability_only_tags_present(self) -> None:
        """Test newly aligned and original capability-only tags are excluded."""
        assert int(CapabilityTag.temperature) in CAPABILITY_ONLY_TAGS
        assert int(CapabilityTag.body_check) in CAPABILITY_ONLY_TAGS
        assert int(CapabilityTag.eco) in CAPABILITY_ONLY_TAGS
        assert int(CapabilityTag.filter_remind) in CAPABILITY_ONLY_TAGS


class TestFormatPropertyTags:
    """Test the format_property_tags debug-log helper."""

    def test_known_tags_render_name_and_hex(self) -> None:
        """Test known tags render as name(0xHHHH)."""
        result = format_property_tags(
            [int(CapabilityTag.self_clean), int(CapabilityTag.sound)],
        )
        assert result == "self_clean(0x0039), sound(0x022C)"

    def test_unknown_tag_falls_back_to_hex(self) -> None:
        """Test an unknown tag value falls back to just its hex."""
        assert format_property_tags([0x0999]) == "0x0999"

    def test_empty_list_renders_empty_string(self) -> None:
        """Test an empty tag list renders an empty string."""
        assert format_property_tags([]) == ""

    def test_accepts_tuple_input(self) -> None:
        """Test the helper accepts the default-properties tuple."""
        result = format_property_tags(_B1_DEFAULT_PROPERTIES)
        assert "indirect_wind(0x0042)" in result
        assert result.count(",") == len(_B1_DEFAULT_PROPERTIES) - 1


class TestPropertiesQueryExposesTags:
    """Test query classes expose their properties for debug logging."""

    def test_default_query_exposes_default_properties(self) -> None:
        """Test PropertiesDefaultQuery.properties matches the constant."""
        msg = PropertiesDefaultQuery(protocol_version=ProtocolVersion.V1)
        assert msg.properties == _B1_DEFAULT_PROPERTIES

    def test_caps_query_exposes_sorted_subset(self) -> None:
        """Test PropertiesCapsQuery.properties is the sorted subset."""
        msg = PropertiesCapsQuery(
            protocol_version=ProtocolVersion.V1,
            properties_subset=[
                int(CapabilityTag.sound),
                int(CapabilityTag.self_clean),
            ],
        )
        assert msg.properties == (
            int(CapabilityTag.self_clean),
            int(CapabilityTag.sound),
        )


class TestCollectCapabilityProperties:
    """Test _PropertiesCapsQueryBase.collect_capability_properties method."""

    def test_collect_excludes_falsy_values(self) -> None:
        """Test that falsy capability values are excluded."""
        caps = cast(
            "dict[str, CapabilityValue]",
            {
                "self_clean": True,
                "rate_select": False,  # Falsy, should be excluded
                "sound": 0,  # Falsy, should be excluded
            },
        )
        result = _PropertiesCapsQueryBase.collect_capability_properties(caps)
        assert int(CapabilityTag.self_clean) in result
        assert int(CapabilityTag.rate_select) not in result
        assert int(CapabilityTag.sound) not in result

    def test_collect_excludes_invalid_keys(self) -> None:
        """Test that invalid capability keys are excluded."""
        caps = cast(
            "dict[str, CapabilityValue]",
            {
                "self_clean": True,
                "invalid_key": True,  # Not a valid CapabilityTag
                "another_bad_key": 1,
            },
        )
        result = _PropertiesCapsQueryBase.collect_capability_properties(caps)
        assert int(CapabilityTag.self_clean) in result
        assert len(result) == 1  # Only self_clean should be included

    def test_collect_excludes_capability_only_tags(self) -> None:
        """Test that B5-only capability tags are excluded."""
        caps = cast(
            "dict[str, CapabilityValue]",
            {
                "self_clean": True,
                "eco": True,  # B5-only, should be excluded
                "filter_remind": True,  # B5-only, should be excluded
                "ptc": True,  # B5-only, should be excluded
            },
        )
        result = _PropertiesCapsQueryBase.collect_capability_properties(caps)
        assert int(CapabilityTag.self_clean) in result
        assert int(CapabilityTag.eco) not in result
        assert int(CapabilityTag.filter_remind) not in result
        assert int(CapabilityTag.ptc) not in result

    def test_collect_excludes_default_properties(self) -> None:
        """Test that default properties are excluded."""
        caps = cast(
            "dict[str, CapabilityValue]",
            {
                "self_clean": True,
                "breezeless": True,  # Default property, should be excluded
                "indoor_humidity": True,  # Default property, should be excluded
            },
        )
        result = _PropertiesCapsQueryBase.collect_capability_properties(caps)
        assert int(CapabilityTag.self_clean) in result
        assert int(CapabilityTag.breezeless) not in result
        assert int(CapabilityTag.indoor_humidity) not in result

    def test_collect_returns_sorted_unique_list(self) -> None:
        """Test that collect returns sorted unique properties."""
        caps = cast(
            "dict[str, CapabilityValue]",
            {
                "sound": True,
                "self_clean": True,
                "rate_select": True,
            },
        )
        result = _PropertiesCapsQueryBase.collect_capability_properties(caps)
        # Should be sorted by tag value
        assert result == sorted(result)
        # Should be unique
        assert len(result) == len(set(result))


class TestCapabilityBodyParsing:
    """Test B5 capability body parsing does not poison subsequent queries."""

    def test_b5_capability_only_tags_do_not_leak_into_query(self) -> None:
        """Test B5 tags auto-parsed as capability keys don't poison next query.

        B5 responses carry capability-only tags (eco, filter_remind, ptc, ...)
        that the generic auto-parse loop echoes into the capabilities dict.
        Those keys must never be auto-appended to a B1 query.
        """
        # Minimal B5 body with eco (0x0212) and filter_remind (0x0217).
        body = bytearray(
            [
                0xB5,
                0x02,  # 2 params
                CapabilityTag.eco & 0xFF,
                CapabilityTag.eco >> 8,
                0x01,  # length
                0x01,  # eco supported
                CapabilityTag.filter_remind & 0xFF,
                CapabilityTag.filter_remind >> 8,
                0x01,  # length
                0x01,  # filter_remind supported
            ],
        )
        # Parse the B5 body.
        parsed = CapabilityBody(body)
        caps = parsed.capabilities
        # Confirm both tags were auto-parsed.
        assert "eco" in caps
        assert "filter_remind" in caps

        # Now build a default query - it should never include these tags.
        msg = PropertiesDefaultQuery(protocol_version=ProtocolVersion.V1)
        params_count = msg.body[1]
        # Should only have 8 default properties, no capability properties.
        assert params_count == 8

    def test_b5_sound_presence_yields_true_capability(self) -> None:
        """Test B5 sound presence sets caps['sound'] = True."""
        # Minimal B5 body with sound (0x022C).
        body = bytearray(
            [
                0xB5,
                0x01,  # 1 param
                CapabilityTag.sound & 0xFF,
                CapabilityTag.sound >> 8,
                0x01,  # length
                0x00,  # raw value 0 (but presence -> True)
            ],
        )
        parsed = CapabilityBody(body)
        caps = parsed.capabilities
        # Presence sets sound to True regardless of raw[0].
        assert caps.get("sound") is True

        # Query with this capability should include sound in caps query.
        msg = PropertiesCapsQuery(
            protocol_version=ProtocolVersion.V1,
            properties_subset=[int(CapabilityTag.sound)],
        )
        params_count = msg.body[1]
        assert params_count == 1


class TestNewProtocolSetOutSilent:
    """Test Message New Protocol Set for out_silent."""

    @pytest.mark.parametrize(
        ("value", "expected_byte"),
        [(True, 0x03), (False, 0x00)],
    )
    def test_out_silent_on_off(self, value: bool, expected_byte: int) -> None:
        """Test out_silent set to on/off sends correct byte."""
        msg = PropertiesSet(protocol_version=ProtocolVersion.V1)
        msg.out_silent = value
        body = msg.body
        assert body[0] == 0xB0
        assert body[1] == 0x01  # 1 param packed
        assert body[2] == CapabilityTag.out_silent & 0xFF  # 0xCD
        assert body[3] == CapabilityTag.out_silent >> 8  # 0x00
        assert body[4] == 0x01  # length byte
        assert body[5] == expected_byte

    def test_out_silent_none_not_packed(self) -> None:
        """Test out_silent None does not add to payload."""
        msg = PropertiesSet(protocol_version=ProtocolVersion.V1)
        # out_silent defaults to None, should not be packed
        body = msg.body
        assert body[0] == 0xB0
        assert body[1] == 0x00  # 0 params packed


class TestNewProtocolSetAngles:
    """Test Message New Protocol Set for wind angles and rate select."""

    @pytest.mark.parametrize(
        ("value", "expected_byte"),
        [(25, 25), (0, 0x00)],
    )
    def test_wind_lr_angle(self, value: int, expected_byte: int) -> None:
        """Test wind_lr_angle set sends correct byte."""
        msg = PropertiesSet(protocol_version=ProtocolVersion.V1)
        # source annotates wind_lr_angle as bytes | None but the device sets ints
        setattr(msg, "wind_lr_angle", value)  # noqa: B010
        body = msg.body
        assert body[0] == 0xB0
        assert body[1] == 0x01  # 1 param packed
        assert body[2] == CapabilityTag.wind_lr_angle & 0xFF  # 0x0A
        assert body[3] == CapabilityTag.wind_lr_angle >> 8  # 0x00
        assert body[4] == 0x01  # length byte
        assert body[5] == expected_byte

    @pytest.mark.parametrize(
        ("value", "expected_byte"),
        [(75, 75), (0, 0x00)],
    )
    def test_wind_ud_angle(self, value: int, expected_byte: int) -> None:
        """Test wind_ud_angle set sends correct byte."""
        msg = PropertiesSet(protocol_version=ProtocolVersion.V1)
        # source annotates wind_ud_angle as bytes | None but the device sets ints
        setattr(msg, "wind_ud_angle", value)  # noqa: B010
        body = msg.body
        assert body[0] == 0xB0
        assert body[1] == 0x01  # 1 param packed
        assert body[2] == CapabilityTag.wind_ud_angle & 0xFF  # 0x09
        assert body[3] == CapabilityTag.wind_ud_angle >> 8  # 0x00
        assert body[4] == 0x01  # length byte
        assert body[5] == expected_byte

    def test_rate_select(self) -> None:
        """Test rate_select set sends correct byte."""
        msg = PropertiesSet(protocol_version=ProtocolVersion.V1)
        msg.rate_select = 60
        body = msg.body
        assert body[0] == 0xB0
        assert body[1] == 0x01  # 1 param packed
        assert body[2] == CapabilityTag.rate_select & 0xFF  # 0x48
        assert body[3] == CapabilityTag.rate_select >> 8  # 0x00
        assert body[4] == 0x01  # length byte
        assert body[5] == 60


class TestMessageSubProtocol:
    """Test Message Sub Protocol."""

    def test_sub_protocol_body(self) -> None:
        """Test sub protocol body."""
        msg = MessageSubProtocol(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            subprotocol_query_type=0xCC,
        )
        expected_body = bytearray(
            [
                0xAA,
                0x08,
                0x00,
                0xFF,
                0xFF,
                0xCC,
            ],
        )
        assert msg.body[:-2] == expected_body

    def test_distinct_query_classes(self) -> None:
        """Test BB queries have independent protocol identities."""
        queries = [
            SubProtocolQuery10(ProtocolVersion.V1),
            SubProtocolQuery11(ProtocolVersion.V1),
            SubProtocolQuery30(ProtocolVersion.V1),
        ]

        assert [query.body[5] for query in queries] == [0x10, 0x11, 0x30]
        assert len({query.__class__.__name__ for query in queries}) == 3


class TestGroupOneQuery:
    """Test AC C1 group 0x41 query."""

    def test_query_body(self) -> None:
        """Test exact group 0x41 query body."""
        message = GroupOneQuery(ProtocolVersion.V1)

        assert message.body.hex() == "4121014100013c"


class TestSubProtocolFreshAirSet:
    """Test BB fresh-air single-control commands."""

    @pytest.mark.parametrize(
        ("power", "speed", "exhaust", "expected"),
        [
            (
                True,
                60,
                False,
                (
                    "aa6800ffffc0000101000000000000000001c002540000000000000404000000"
                    "0000000000000000000000000000000000000000000000000000000000000000"
                    "000000000000000000000000bc00000000000000000000000000000000000000"
                    "000000000026002d"
                ),
            ),
            (
                False,
                60,
                False,
                (
                    "aa6800ffffc0000101000000000000000001c002540000000000000400000000"
                    "0000000000000000000000000000000000000000000000000000000000000000"
                    "000000000000000000000000bc00000000000000000000000000000000000000"
                    "00000000002a1c11"
                ),
            ),
            (
                True,
                80,
                True,
                (
                    "aa6800ffffc0000101000000000000000001c002540000000000000808000000"
                    "0000000000000000000000000000000000000000000000000000000000000000"
                    "00000000000000000000000000d0000000000000000000000000000000000000"
                    "00000000000af23b"
                ),
            ),
            (
                False,
                80,
                True,
                (
                    "aa6800ffffc0000101000000000000000001c002540000000000000800000000"
                    "0000000000000000000000000000000000000000000000000000000000000000"
                    "00000000000000000000000000d0000000000000000000000000000000000000"
                    "000000000012ca63"
                ),
            ),
        ],
    )
    def test_command_body(
        self,
        power: bool,
        speed: int,
        exhaust: bool,
        expected: str,
    ) -> None:
        """Test exact intake and exhaust command bytes."""
        message = SubProtocolFreshAirSet(
            ProtocolVersion.V1,
            power,
            speed,
            exhaust=exhaust,
        )

        assert message.body.hex() == expected


class TestMessageSubProtocolSet:
    """Test Message Sub Protocol Set."""

    def test_sub_protocol_set_body(self) -> None:
        """Test sub protocol set body."""
        msg = MessageSubProtocolSet(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray(
            [
                0xAA,
                45,
                0x00,
                0xFF,
                0xFF,
                0x20,
                0x02,
                0x80,
                0x00,
                0x00,
                0x00,
                0x00,
                20 * 2 + 30,
                102,
                0x32,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x01,
                0x01,
                0x00,
                0x01,
                19 * 2 + 50,
                0x00,
                20 * 2 + 30,
                0x32,
                0x66,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x08,
            ],
        )
        assert msg.body[:-2] == expected_body

        msg.power = True
        msg.mode = 6
        msg.target_temperature = 24.0
        msg.fan_speed = 90
        msg.boost_mode = True
        msg.aux_heating = True
        msg.dry = True
        msg.eco_mode = True
        msg.sleep_mode = True
        msg.sn8_flag = True
        msg.timer = True
        msg.prompt_tone = True
        expected_body[6] = 0x02 | 0x20 | 0x01 | 0x10
        expected_body[7] = 0x40
        expected_body[8] = 0x80
        expected_body[11] = 0x02
        expected_body[12] = 24 * 2 + 30
        expected_body[13] = 90
        expected_body[25] = 23 * 2 + 50
        expected_body[26] = 0x01
        expected_body[27] = 24 * 2 + 30
        expected_body[31] = 0x40 | 0x04
        assert msg.body[:-2] == expected_body


class TestMessageSet:
    """Test Message General Set."""

    def test_general_set_body(self) -> None:
        """Test general set body."""
        msg = StateSet(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray(
            [
                0x40,
                0x40,
                0x00 | (20 & 0xF) | (0x10 if 20 % 2 != 0 else 0),
                102 & 0x7F,
                0x00,
                0x00,
                0x00,
                0x30,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
            ],
        )
        assert msg.body[:-2] == expected_body
        msg.power = True
        msg.prompt_tone = False
        msg.mode = 2
        msg.target_temperature = 24.0
        msg.fan_speed = 92
        msg.swing_vertical = True
        msg.swing_horizontal = True
        msg.boost_mode = True
        msg.power_saving = True
        msg.smart_eye = True
        msg.dry = True
        msg.aux_heating = True
        msg.eco_mode = True
        msg.temp_fahrenheit = True
        msg.sleep_mode = True
        msg.natural_wind = True
        msg.frost_protect = True
        msg.comfort_mode = True
        expected_body[1] = 0x01
        expected_body[2] = (
            (0x02 << 5) & 0xE0 | (24 & 0xF) | (0x10 if 24 % 2 != 0 else 0)
        )
        expected_body[3] = 92 & 0x7F
        expected_body[7] = 0x30 | 0x0C | 0x03
        expected_body[8] = 0x20 | 0x08
        expected_body[9] = 0x01 | 0x04 | 0x08 | 0x80
        expected_body[10] = 0x04 | 0x01 | 0x02
        expected_body[17] = 0x40
        expected_body[21] = 0x80
        expected_body[22] = 0x01
        assert msg.body[:-2] == expected_body


class TestMessageACResponse:
    """Test Message AC Response."""

    @pytest.fixture(autouse=True)
    def _setup_header(self) -> None:
        """Do setup header."""
        self.header = bytearray(
            [
                0xAA,
                0x00,
                0xAC,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x01,
                0x05,
            ],
        )

    def test_message_notify2_a0(self) -> None:
        """Test Message parse notify2 A0."""
        body = bytearray(19)
        body[0] = 0xA0  # Body type
        body[1] = 0b01011111  # Power on, target temperature with 0.5 increment
        body[2] = 0b11100000  # Mode
        body[3] = 0b01111111  # Fan speed
        body[7] = 0b00001111  # Swing vertical and horizontal
        body[8] = 0b00101000  # Boost mode, power saving
        body[9] = 0b00011101  # Smart eye, dry, aux heating, eco mode
        body[10] = 0b01000011  # Sleep mode, natural wind
        body[13] = 0b00100000  # Full dust
        body[14] = 0b00000001  # Comfort mode

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "power")
        assert hasattr(response, "target_temperature")
        assert response.target_temperature == 27.5  # ((31 >> 1) - 4 + 16 + 0.5) = 27.5
        assert hasattr(response, "mode")
        assert response.mode == 7
        assert hasattr(response, "fan_speed")
        assert response.fan_speed == 127
        assert hasattr(response, "swing_vertical")
        assert hasattr(response, "swing_horizontal")
        assert hasattr(response, "boost_mode")
        assert hasattr(response, "power_saving")
        assert response.power_saving is True
        assert hasattr(response, "smart_eye")
        assert hasattr(response, "dry")
        assert hasattr(response, "aux_heating")
        assert hasattr(response, "eco_mode")
        assert hasattr(response, "sleep_mode")
        assert hasattr(response, "natural_wind")
        assert hasattr(response, "full_dust")
        assert hasattr(response, "comfort_mode")

    def test_b1_degerming_state_on(self) -> None:
        """Test degerming state is read from the 0x7e payload (captured on)."""
        response = MessageACResponse(
            bytearray.fromhex(
                "aa6bac00000000000803"
                "b10a42000001011800000100150000013f1700000100330211004b000004002815000a"
                "00000100090000014b39000001007e00002aa01ba5647f7f0033000c00000065005802"
                "0700f2000000e000000040000000003c0028283f051400720500d839",
            ),
        )
        assert response.degerming_active is True

    def test_b1_degerming_state_off(self) -> None:
        """Test degerming state is read from the 0x7e payload (captured off)."""
        response = MessageACResponse(
            bytearray.fromhex(
                "aa6bac00000000000803"
                "b10a4200000101180000010015000001431700000100330211004b000004002813000a"
                "00000164090000010039000001007e00002aa01a41667f7f0000000c00000065005802"
                "9000f0000000e000000040000000003c00282843011400700000e329",
            ),
        )
        assert response.degerming_active is False

    def test_b5_degerming_state_reported(self) -> None:
        """Test a B5 notify body reports live degerming state (captured off).

        Unlike self_clean, whose B5 tag is only a capability flag, the 0x7e
        payload in a B5 body carries the live degerming state.
        """
        response = MessageACResponse(
            bytearray.fromhex(
                "aa3cac00000000000805"
                "b5017e002b001a41667f7f0000000c000000650058029000f0000000e0000000400000"
                "00003c002828490114006c0900014dd5",
            ),
        )
        assert response.degerming_active is False

    def test_b5_degerming_state_on(self) -> None:
        """Test a B5 notify body reports live degerming state (captured on)."""
        response = MessageACResponse(
            bytearray.fromhex(
                "aa3cac00000000000805b5017e002b001ba5647f7f0000000c000000650058029700f2000000e0"
                "00000040000000003c00282835051400720500019c",
            ),
        )
        assert response.degerming_active is True

    def test_b5_degerming_state_on_extended_payload(self) -> None:
        """Test degerming on from a B5 notify of the extended payload variant.

        Model 22019061 (COLMO KFR-50GW/CA3) pushes the live state bit in the
        notify body as well.
        """
        response = MessageACResponse(
            bytearray.fromhex(
                "aa3cac00000000000805b5017e0038a11fa5647f7f0033000c00070000000f000000f2000000e0"
                "00000040000000003c00282835850e00720000000000200008000000000005000145",
            ),
        )
        assert response.degerming_active is True

    def test_b5_degerming_state_off_extended_payload(self) -> None:
        """Test degerming off from a B5 notify of the extended payload variant."""
        response = MessageACResponse(
            bytearray.fromhex(
                "aa3cac00000000000805b5017e0038a51fa5647f7f0000000c00070000000f009000f0000000e0"
                "00000040000000003c00282836850e00720300000000200008000000000005000198",
            ),
        )
        assert response.degerming_active is False

    def test_b1_degerming_state_on_extended_payload(self) -> None:
        """Test degerming on from the extended 0x7e payload variant.

        Model 22019061 (COLMO KFR-50GW/CA3) reports a 55-byte 0x7e payload;
        the same byte 19 bit 0x02 holds the state (captured with the feature
        on).
        """
        response = MessageACResponse(
            bytearray.fromhex(
                "aa78ac00000000000803b10a4200000101180000010015000001351700000164330211004b00"
                "0004002816000a00000100090000010039000001007e000037a01fa5647f7f0033000c000000"
                "00000f000000f2000000e000000040000000003c00282835850e007200000000002000080000"
                "00000000007592",
            ),
        )
        assert response.degerming_active is True

    def test_b1_degerming_state_off_extended_payload(self) -> None:
        """Test degerming off from the extended 0x7e payload variant."""
        response = MessageACResponse(
            bytearray.fromhex(
                "aa78ac00000000000803b10a4200000101180000010015000001331700000100330211004b00"
                "0004002816000a00000164090000010039000001007e000037a01ea1647f7f0000000c000700"
                "00000f009000f0000000e000000040000000003c00282833810e007009000000002000080000"
                "0000000000e5c6",
            ),
        )
        assert response.degerming_active is False

    def test_message_notify2_a0_short_body(self) -> None:
        """Skip Message parse notify2 A0 when the body is too short."""
        body = bytearray(A0_A1_C0_MIN_BODY_LENGTH)
        body[0] = 0xA0  # Body type

        response = MessageACResponse(self.header + body)

        assert not hasattr(response, "power")

    def test_message_notify2_a0_fresh_filter(self) -> None:
        """Test Message parse notify2 A0 with fresh filter bytes."""
        body = bytearray(31)  # stripped body length 30 >= FRESH_AIR_C0_MIN_LENGTH
        body[0] = 0xA0  # Body type
        body[13] = 0x40  # Fresh filter timeout bit
        body[15] = 0x20  # Fresh filter time use low byte
        body[16] = 0x02  # Fresh filter time use high byte
        body[24] = 0x10  # Fresh filter time total low byte
        body[25] = 0x01  # Fresh filter time total high byte

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "fresh_filter_time_total")
        assert response.fresh_filter_time_total == 0x01 * 256 + 0x10
        assert hasattr(response, "fresh_filter_time_use")
        assert response.fresh_filter_time_use == 0x02 * 256 + 0x20
        assert hasattr(response, "fresh_filter_timeout")
        assert response.fresh_filter_timeout == 1

    def test_message_notify1_a1(self) -> None:
        """Test Message parse notify1 A1."""
        self.header[9] = 0x04
        body = bytearray(22)
        body[0] = 0xA1  # Body type
        body[13] = 100  # Indoor temperature byte
        body[14] = 60  # Outdoor temperature byte
        body[17] = 50  # Indoor humidity byte
        body[18] = 0xF3  # Decimal part for temperature
        response = MessageACResponse(self.header + body)

        assert hasattr(response, "indoor_temperature")
        assert response.indoor_temperature == 25.3  # ((100 - 50) / 2) + 0.3 = 25.3
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature == 6.5  # ((60 - 50) / 2) + 1.5 = 6.5
        assert hasattr(response, "indoor_humidity")
        assert response.indoor_humidity == 50

        body[14] = 0xFF  # Outdoor temperature byte
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature is None

        body[13] = 48  # Indoor temperature byte
        body[14] = 40  # Outdoor temperature byte
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "indoor_temperature")
        assert response.indoor_temperature == -1.3  # ((49 - 50) / 2) - 0.3 = -1.3
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature == -6.5  # ((40 - 50) / 2) - 1.5 = -6.5

    def test_message_notify1_a1_short_body(self) -> None:
        """Test Message parse notify1 A1 with a body too short to parse."""
        self.header[9] = 0x04
        # Real frame from a 00000Q1B / subtype 44204 unit: 7-byte body
        # (last byte is the checksum and is stripped by MessageResponse).
        # XA1MessageBody reads up to body[17], so it must be skipped, not parsed.
        body = bytearray([0xA1, 0x00, 0x03, 0x8A, 0x95, 0xB6, 0xC1, 0x02])
        response = MessageACResponse(self.header + body)

        assert not hasattr(response, "indoor_temperature")
        assert not hasattr(response, "outdoor_temperature")
        assert not hasattr(response, "indoor_humidity")
        assert not hasattr(response, "current_work_time")

    def test_message_notify1_a1_body_length_boundary(self) -> None:
        """Test Message parse notify1 A1 boundary at A0_A1_C0_MIN_BODY_LENGTH."""
        self.header[9] = 0x04

        # One byte short of the minimum: skipped, and must not raise.
        # +1 accounts for the trailing checksum byte stripped by MessageResponse.
        body = bytearray(A0_A1_C0_MIN_BODY_LENGTH - 1 + 1)
        body[0] = 0xA1
        response = MessageACResponse(self.header + body)
        assert not hasattr(response, "indoor_temperature")

        # Exactly the minimum: parsed.
        body = bytearray(A0_A1_C0_MIN_BODY_LENGTH + 1)
        body[0] = 0xA1
        body[13] = 100  # Indoor temperature byte
        body[14] = 60  # Outdoor temperature byte
        body[17] = 50  # Indoor humidity byte
        response = MessageACResponse(self.header + body)

        assert hasattr(response, "indoor_temperature")
        assert response.indoor_temperature == 25.0  # (100 - 50) / 2
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature == 5.0  # (60 - 50) / 2
        assert hasattr(response, "indoor_humidity")
        assert response.indoor_humidity == 50

    def test_message_query_b5(self) -> None:
        """Test message query b5."""
        body = bytearray(
            [
                0xB5,
                0x05,
                0x15,  # indoor_humidity
                0x00,
                0x01,  # length
                0x00,  # value
                0x17,  # screen_display_alternate
                0x00,
                0x01,  # length
                0x00,  # value
                0x18,  # breezeless
                0x00,
                0x01,  # length
                0x00,  # value
                0x09,  # wind_ud_angle
                0x00,
                0x01,  # length
                0x00,  # value
                0x0A,  # wind_lr_angle
                0x00,
                0x01,  # length
                0x00,  # value
                0x01,
                0xD6,
            ],
        )
        response = MessageACResponse(self.header + body)
        # query message
        assert hasattr(response, "indoor_humidity")
        assert hasattr(response, "screen_display_alternate")
        assert hasattr(response, "breezeless")
        assert hasattr(response, "wind_ud_angle")
        assert hasattr(response, "wind_lr_angle")
        assert not hasattr(response, "indirect_wind")

    def test_message_notify2_b0(self) -> None:
        """Test Message parse notify2 B0."""
        body = bytearray(29)
        body[0] = 0xB0  # Body type
        body[1] = 0x05  # Params count
        body[2] = CapabilityTag.indirect_wind & 0xFF  # Low byte param
        body[3] = CapabilityTag.indirect_wind >> 8  # High byte param
        body[5] = 0x01  # Value length
        body[6] = 0x02  # Value True
        body[7] = CapabilityTag.indoor_humidity & 0xFF  # Low byte param
        body[8] = CapabilityTag.indoor_humidity >> 8  # High byte param
        body[10] = 0x01  # Value length
        body[11] = 30  # Value 30
        body[12] = CapabilityTag.breezeless & 0xFF  # Low byte param
        body[13] = CapabilityTag.breezeless >> 8  # High byte param
        body[15] = 0x01  # Value length
        body[16] = 0x01  # Value True
        body[17] = CapabilityTag.screen_display & 0xFF  # Low byte param
        body[18] = CapabilityTag.screen_display >> 8  # High byte param
        body[20] = 0x01  # Value length
        body[21] = 0x01  # Value True
        body[22] = CapabilityTag.fresh_air_1 & 0xFF  # Low byte param
        body[23] = CapabilityTag.fresh_air_1 >> 8  # High byte param
        body[25] = 0x02  # Value length
        body[26] = 0x02  # Value Power True
        body[27] = 10  # Value Speed 10

        response = MessageACResponse(self.header + body)

        assert hasattr(response, "indirect_wind")
        assert hasattr(response, "indoor_humidity")
        assert response.indoor_humidity == 30
        assert hasattr(response, "breezeless")
        assert hasattr(response, "screen_display_alternate")
        assert hasattr(response, "screen_display_new")
        assert hasattr(response, "fresh_air_1")
        assert hasattr(response, "fresh_air_power")
        assert hasattr(response, "fresh_air_fan_speed")
        assert response.fresh_air_fan_speed == 10

        body[22] = CapabilityTag.fresh_air_2 & 0xFF  # Low byte param
        body[23] = CapabilityTag.fresh_air_2 >> 8  # High byte param
        body[25] = 0x02  # Value length
        body[26] = 0x01  # Value Power True
        body[27] = 20  # Value Speed 20

        response = MessageACResponse(self.header + body)
        assert not hasattr(response, "fresh_air_1")
        assert hasattr(response, "fresh_air_2")
        assert hasattr(response, "fresh_air_power")
        assert hasattr(response, "fresh_air_fan_speed")
        assert response.fresh_air_fan_speed == 20

    def test_message_notify2_b0_rate_select(self) -> None:
        """Test Message parse notify2 B0 with rate_select."""
        body = bytearray(10)
        body[0] = 0xB0  # Body type
        body[1] = 0x01  # Params count
        body[2] = CapabilityTag.rate_select & 0xFF  # Low byte 0x48
        body[3] = CapabilityTag.rate_select >> 8  # High byte 0x00
        body[4] = 0x00  # Padding
        body[5] = 0x01  # Value length
        body[6] = 40  # Value 40

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "rate_select")
        assert response.rate_select == 40

    def test_message_query_b5_capabilities(self) -> None:
        """Test Message parse query B5 capabilities."""
        self.header[9] = 0x03
        body = bytearray([0xB5, 0x0B])  # Body type, params count
        body += bytearray([0x14, 0x02, 0x01, 7])  # mode
        body += bytearray([0x15, 0x02, 0x01, 1])  # wind_swing
        body += bytearray([0x10, 0x02, 0x01, 5])  # wind_speed
        body += bytearray([0x12, 0x02, 0x01, 1])  # eco
        body += bytearray([0x1E, 0x02, 0x01, 1])  # anion
        body += bytearray([0x17, 0x02, 0x01, 1])  # filter_remind
        body += bytearray([0x1A, 0x02, 0x01, 1])  # strong_wind
        body += bytearray([0x25, 0x02, 0x07, 34, 60, 34, 60, 34, 60, 1])  # temperature
        # screen_display_capability
        body += bytearray([0x24, 0x02, 0x01, 1])
        body += bytearray([0x2C, 0x02, 0x01, 1])  # sound
        body += bytearray([0x1F, 0x02, 0x01, 1])  # humidity
        body += bytearray(1)  # trailing checksum byte (stripped by MessageResponse)

        response = MessageACResponse(self.header + body)
        # All capability tags are parsed into capabilities dict, including the
        # temperature capability as a nested per-mode setpoint-limit map.
        assert hasattr(response, "capabilities")
        assert response.capabilities == {
            # Manually parsed capabilities with special logic
            "modes": ["heat", "cool", "auto"],
            "swing_modes": ["horizontal", "vertical"],
            "fan_speeds": ["low", "medium", "high", "auto"],
            "eco": True,
            "anion": True,
            "turbo_cool": True,
            "turbo_heat": True,
            "display_control": True,
            # Presence-based capability (raw value ignored)
            "sound": True,
            # Per-mode setpoint limits (0.5 C units): 34/2=17.0, 60/2=30.0.
            # Decimals flag (index 6 for size=7) indicates 0.5 C support.
            "temperature": {
                "cool": {"min": 17.0, "max": 30.0},
                "auto": {"min": 17.0, "max": 30.0},
                "heat": {"min": 17.0, "max": 30.0},
                "decimals": True,
            },
            # Auto-parsed tags (raw value from first byte)
            "filter_remind": 1,
            "humidity": 1,
        }

    def test_message_query_b5_temperature_decimals_short_size(self) -> None:
        """Test temperature decimals parsing with short size (<=6 bytes)."""
        self.header[9] = 0x03
        body = bytearray([0xB5, 0x01])  # Body type, params count
        # Temperature with 6 bytes: cool/auto/heat min/max only, no trailing byte
        # Decimals flag is at index 2 (auto min) when size <= 6
        body += bytearray([0x25, 0x02, 0x06, 34, 60, 1, 60, 34, 60])  # temperature
        body += bytearray(1)  # trailing checksum byte

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "capabilities")
        assert "temperature" in response.capabilities
        temp = response.capabilities["temperature"]
        assert isinstance(temp, dict)
        # Index 2 (third byte = 1) is the decimals flag when size = 6
        assert temp["decimals"] is True
        assert temp["cool"]["min"] == 17.0
        assert temp["cool"]["max"] == 30.0

    def test_message_query_b5_temperature_too_short(self) -> None:
        """Test temperature capability is skipped when data is too short."""
        self.header[9] = 0x03
        body = bytearray([0xB5, 0x01])  # Body type, params count
        # Temperature with only 5 bytes: missing heat max index (needs 6 minimum)
        body += bytearray([0x25, 0x02, 0x05, 34, 60, 1, 60, 34])
        body += bytearray(1)  # trailing checksum byte

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "capabilities")
        # Temperature capability should be skipped due to insufficient data
        assert "temperature" not in response.capabilities

    def test_message_query_b5_detects_additional_capabilities(self) -> None:
        """Test the basic B5 frame's trailing flag arms the additional query.

        These are full frames captured from a PortaSplit AC. The basic frame
        ends in a non-zero flag (device has a second frame); the additional
        frame ends in a zero flag (no more frames).
        """
        basic = bytearray.fromhex(
            "aa3dac00000000000803b50a1202010114020101150201001e020101170201021a"
            "02010110020101250207203c203c203c00240201014800010101199831",
        )
        additional = bytearray.fromhex(
            "aa2fac00000000000803b5081f0201002c020101160201043900010151000101e3"
            "00010113020101cd000103001a6910",
        )

        basic_response = MessageACResponse(basic)
        assert hasattr(basic_response, "additional_capabilities")
        assert basic_response.additional_capabilities is True

        additional_response = MessageACResponse(additional)
        assert hasattr(additional_response, "additional_capabilities")
        assert additional_response.additional_capabilities is False

    @pytest.mark.parametrize("raw_value", [4, 3, 2, 1, 0])
    def test_message_query_b5_electricity_reports_rate_level_count(
        self,
        raw_value: int,
    ) -> None:
        """Test electricity capability exposes the raw rate level count.

        The electricity byte is a rate level count, not a boolean:
        1 selects the 2-gear map, 2/3 select the 5-gear map, 0 means
        unsupported. The parser stores the raw value so the device layer can
        pick the right gear map.
        """
        self.header[9] = 0x03
        body = bytearray([0xB5, 0x01])  # Body type, params count
        body += bytearray([0x16, 0x02, 0x01, raw_value])  # electricity
        body += bytearray(1)  # trailing checksum byte (stripped by MessageResponse)

        response = MessageACResponse(self.header + body)

        assert hasattr(response, "capabilities")
        assert response.capabilities == {"rate_select": raw_value}

    @pytest.mark.parametrize(
        ("raw_value", "expected"),
        [(1, True), (0, False)],
    )
    def test_message_query_b5_self_clean_reports_support(
        self,
        raw_value: int,
        expected: bool,
    ) -> None:
        """Test the B5 self_clean tag advertises self-clean support.

        In a B5 body tag 0x0039 advertises support (live state is only in
        B0/B1 bodies), so a non-zero byte marks the feature supported.
        """
        self.header[9] = 0x03
        body = bytearray([0xB5, 0x01])  # Body type, params count
        body += bytearray([0x39, 0x00, 0x01, raw_value])  # self_clean (0x0039)
        body += bytearray(1)  # trailing checksum byte (stripped by MessageResponse)

        response = MessageACResponse(self.header + body)

        assert hasattr(response, "capabilities")
        assert response.capabilities == {"self_clean": expected}

    def test_message_query_b5_custom_fan_supports_named_speeds(self) -> None:
        """Test B5 fan custom profile includes named fan speeds."""
        self.header[9] = 0x03
        body = bytearray([0xB5, 0x01])  # Body type, params count
        body += bytearray([0x10, 0x02, 0x01, 1])  # b5_wind_speed: fan_custom
        body += bytearray(1)  # trailing checksum byte (stripped by MessageResponse)

        response = MessageACResponse(self.header + body)

        assert hasattr(response, "capabilities")
        assert response.capabilities == {
            "fan_speeds": ["silent", "low", "medium", "high", "auto", "custom"],
        }

    def test_message_query_b5_value_9_fan_supports_silent_low_high_auto(
        self,
    ) -> None:
        """Test B5 fan profile 9 includes silent, low, high, and auto."""
        self.header[9] = 0x03
        body = bytearray([0xB5, 0x01])  # Body type, params count
        body += bytearray([0x10, 0x02, 0x01, 9])  # b5_wind_speed: profile 9
        body += bytearray(1)  # trailing checksum byte (stripped by MessageResponse)

        response = MessageACResponse(self.header + body)

        assert hasattr(response, "capabilities")
        assert response.capabilities == {
            "fan_speeds": ["silent", "low", "high", "auto"],
        }

    def test_message_query_b5_warns_unknown_tag(
        self,
        caplog: pytest.LogCaptureFixture,
    ) -> None:
        """Test B5 capability parsing warns about unknown tags."""
        self.header[9] = 0x03
        body = bytearray([0xB5, 0x02])  # Body type, 2 params
        # Add a known tag (b5_mode)
        body += bytearray([0x14, 0x02, 0x01, 7])  # b5_mode
        # Add an unknown B5-range tag (0x0299, not in CapabilityTag)
        body += bytearray([0x99, 0x02, 0x01, 0x42])
        body += bytearray(1)  # trailing checksum byte

        with caplog.at_level(logging.WARNING):
            response = MessageACResponse(self.header + body)

        # Known tag should parse
        assert hasattr(response, "capabilities")
        assert "modes" in response.capabilities
        # Unknown tag should trigger warning
        assert any(
            "Unknown capability tag" in record.message and "0x0299" in record.message
            for record in caplog.records
        )

    def test_message_query_b5_mode_excludes_unsupported_modes(self) -> None:
        """Test B5 mode capability excludes modes based on value."""
        self.header[9] = 0x03
        body = bytearray([0xB5, 0x01])  # Body type, 1 param
        # Value 3: no heat (not in B5_HEAT_MODE_VALUES),
        # has cool (not in B5_NO_COOL_MODE_VALUES),
        # no dry (not in B5_DRY_MODE_VALUES),
        # no auto (not in B5_AUTO_MODE_VALUES)
        body += bytearray([0x14, 0x02, 0x01, 3])  # mode tag with value 3
        body += bytearray(1)  # trailing checksum byte

        response = MessageACResponse(self.header + body)

        assert hasattr(response, "capabilities")
        assert response.capabilities["modes"] == ["cool"]

    def test_message_query_b5_mode_excludes_cool_when_in_no_cool_values(
        self,
    ) -> None:
        """Test B5 mode capability excludes cool for no-cool values."""
        self.header[9] = 0x03
        body = bytearray([0xB5, 0x01])  # Body type, 1 param
        # Value 10: has heat (in B5_HEAT_MODE_VALUES),
        # no cool (in B5_NO_COOL_MODE_VALUES),
        # no dry (not in B5_DRY_MODE_VALUES),
        # no auto (not in B5_AUTO_MODE_VALUES)
        body += bytearray([0x14, 0x02, 0x01, 10])  # mode tag with value 10
        body += bytearray(1)  # trailing checksum byte

        response = MessageACResponse(self.header + body)

        assert hasattr(response, "capabilities")
        assert response.capabilities["modes"] == ["heat"]

    def test_message_query_b5_swing_excludes_unsupported_directions(self) -> None:
        """Test B5 swing capability excludes directions based on value."""
        self.header[9] = 0x03
        body = bytearray([0xB5, 0x01])  # Body type, 1 param
        # Value 2: no horizontal (not in B5_SWING_HORIZONTAL_VALUES),
        # no vertical (value >= B5_LOW_VALUE_MAX which is 2)
        body += bytearray([0x15, 0x02, 0x01, 2])  # wind_swing tag with value 2
        body += bytearray(1)  # trailing checksum byte

        response = MessageACResponse(self.header + body)

        assert hasattr(response, "capabilities")
        assert response.capabilities["swing_modes"] == []

    def test_message_query_b5_fan_speed_excludes_unsupported_speeds(self) -> None:
        """Test B5 fan speed capability excludes speeds based on value."""
        self.header[9] = 0x03
        body = bytearray([0xB5, 0x01])  # Body type, 1 param
        # Value 8: not custom, no silent, no low/high, no medium, no auto
        # (8 is not in any of the B5_FAN_* sets)
        body += bytearray([0x10, 0x02, 0x01, 8])  # wind_speed tag with value 8
        body += bytearray(1)  # trailing checksum byte

        response = MessageACResponse(self.header + body)

        assert hasattr(response, "capabilities")
        assert response.capabilities["fan_speeds"] == []

    @pytest.mark.parametrize(
        ("raw_value", "expected"),
        [(0x03, True), (0x00, False)],
    )
    def test_message_notify2_b0_out_silent(
        self,
        raw_value: int,
        expected: bool,
    ) -> None:
        """Test Message parse notify2 B0 with out_silent."""
        body = bytearray(10)
        body[0] = 0xB0  # Body type
        body[1] = 0x01  # Params count
        body[2] = CapabilityTag.out_silent & 0xFF  # Low byte 0xCD
        body[3] = CapabilityTag.out_silent >> 8  # High byte 0x00
        body[4] = 0x00  # Padding
        body[5] = 0x01  # Value length
        body[6] = raw_value

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "out_silent")
        assert response.out_silent is expected

    @pytest.mark.parametrize(
        ("raw_value", "expected"),
        [(0x01, True), (0x00, False)],
    )
    def test_message_query_b1_self_clean_active(
        self,
        raw_value: int,
        expected: bool,
    ) -> None:
        """Test Message parse query B1 reports live self-clean state."""
        # B1 body: body_type(1) + count(1) + tag(2) + 0x00 + length(1) + value(1)
        self.header[9] = 0x03
        body = bytearray(
            [
                0xB1,  # Body type
                0x01,  # Params count
                CapabilityTag.self_clean & 0xFF,
                CapabilityTag.self_clean >> 8,
                0x00,
                0x01,  # Value length
                raw_value,
                0x00,  # trailing checksum byte (stripped by MessageResponse)
            ],
        )

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "self_clean_active")
        assert response.self_clean_active is expected

    def test_message_notify2_b5_self_clean_is_capability_only(self) -> None:
        """Test that tag 0x0039 in a B5 body is not read as live state."""
        # B5 advertises self-clean support with a constant 0x01, so it must not
        # be mistaken for the running state.
        body = bytearray(
            [
                0xB5,  # Body type
                0x01,  # Params count
                CapabilityTag.self_clean & 0xFF,
                CapabilityTag.self_clean >> 8,
                0x01,  # Value length
                0x01,  # Capability: supported
                0x00,  # trailing checksum byte (stripped by MessageResponse)
            ],
        )

        response = MessageACResponse(self.header + body)
        assert not hasattr(response, "self_clean_active")

    @pytest.mark.parametrize(
        ("start", "end", "expected"),
        [
            (1, 0, True),  # supported via start byte
            (0, 2, True),  # supported via end byte
            (8, 8, True),  # ECOMaster
            (0, 0, False),  # unsupported
        ],
    )
    def test_message_query_b5_ieco_reports_support(
        self,
        start: int,
        end: int,
        expected: bool,
    ) -> None:
        """Test the B5 iECO tag advertises support from start/end bytes."""
        self.header[9] = 0x03
        body = bytearray([0xB5, 0x01])  # Body type, params count
        # iECO (0x00E3): start byte then end byte
        body += bytearray([0xE3, 0x00, 0x02, start, end])
        body += bytearray(1)  # trailing checksum byte (stripped by MessageResponse)

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "capabilities")
        assert response.capabilities == {"ieco": expected}

    def test_message_query_b5_ieco_single_byte(self) -> None:
        """Test the B5 iECO tag with only a start byte still parses."""
        self.header[9] = 0x03
        body = bytearray([0xB5, 0x01])  # Body type, params count
        body += bytearray([0xE3, 0x00, 0x01, 0x03])  # start byte only
        body += bytearray(1)  # trailing checksum byte

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "capabilities")
        assert response.capabilities == {"ieco": True}

    @pytest.mark.parametrize(
        ("switch", "number", "expected_state"),
        [(0x01, 0x03, True), (0x00, 0x02, False)],
    )
    def test_message_query_b1_ieco_state(
        self,
        switch: int,
        number: int,
        expected_state: bool,
    ) -> None:
        """Test Message parse query B1 reports live iECO state and number."""
        self.header[9] = 0x03
        body = bytearray(
            [
                0xB1,  # Body type
                0x01,  # Params count
                CapabilityTag.ieco & 0xFF,
                CapabilityTag.ieco >> 8,
                0x00,
                0x02,  # Value length
                number,  # data[0] - iECO number
                switch,  # data[1] - on/off switch
                0x00,  # trailing checksum byte (stripped by MessageResponse)
            ],
        )

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "ieco")
        assert hasattr(response, "ieco_number")
        assert response.ieco is expected_state
        assert response.ieco_number == number

    def test_message_notify2_b5_ieco_is_capability_only(self) -> None:
        """Test that tag 0x00E3 in a B5 body is not read as live state."""
        body = bytearray(
            [
                0xB5,  # Body type
                0x01,  # Params count
                CapabilityTag.ieco & 0xFF,
                CapabilityTag.ieco >> 8,
                0x02,  # Value length
                0x01,  # start byte: supported
                0x01,  # end byte
                0x00,  # trailing checksum byte (stripped by MessageResponse)
            ],
        )

        response = MessageACResponse(self.header + body)
        assert not hasattr(response, "ieco")

    def test_message_query_c0(self) -> None:
        """Test Message parse query C0."""
        self.header[9] = 0x03
        body = bytearray(24)
        body[0] = 0xC0  # Body type
        body[1] = 0b00000001  # Power on
        body[2] = 0b10101110  # Mode (5), target temperature (14), 0.5 increment
        body[3] = 0b01111111  # Fan speed
        body[7] = 0b00001111  # Swing vertical and horizontal
        body[8] = 0b01101000  # Boost mode, smart eye, power saving
        body[9] = 0b00011110  # Natural wind, dry, eco mode, aux heating
        body[10] = 0b01000111  # Sleep mode, temp Fahrenheit, boost mode (alternative)
        body[11] = 0x64  # Indoor temperature byte
        body[12] = 0x64  # Outdoor temperature byte
        body[13] = 0b00100000  # Full dust
        body[14] = 0b01110000  # Screen display
        body[15] = 0b00110010  # Decimal parts for temperature
        body[21] = 0b10000000  # Frost protect
        body[22] = 0b00000001  # Comfort mode

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "power")
        assert hasattr(response, "mode")
        assert response.mode == 5
        assert hasattr(response, "target_temperature")
        assert response.target_temperature == 30  # 14 + 16
        assert hasattr(response, "fan_speed")
        assert response.fan_speed == 127
        assert hasattr(response, "swing_vertical")
        assert hasattr(response, "swing_horizontal")
        assert hasattr(response, "boost_mode")
        assert hasattr(response, "power_saving")
        assert response.power_saving is True
        assert hasattr(response, "smart_eye")
        assert hasattr(response, "natural_wind")
        assert hasattr(response, "dry")
        assert hasattr(response, "eco_mode")
        assert hasattr(response, "aux_heating")
        assert hasattr(response, "temp_fahrenheit")
        assert hasattr(response, "sleep_mode")
        assert hasattr(response, "indoor_temperature")
        assert response.indoor_temperature == 25.2  # ((100 - 50) / 2) + 0.2
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature == 25.3  # ((100 - 50) / 2) + 0.3
        assert hasattr(response, "full_dust")
        assert hasattr(response, "screen_display")
        assert response.screen_display is False
        assert hasattr(response, "frost_protect")
        assert hasattr(response, "comfort_mode")

        body[11] = 40  # Indoor temperature byte
        body[12] = 40  # Outdoor temperature byte
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "indoor_temperature")
        assert response.indoor_temperature == -5.2  # ((40 - 50) / 2) - 0.2
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature == -5.3  # ((40 - 50) / 2) - 0.3

        body[12] = 0xFF  # Outdoor temperature byte
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature is None

    def test_message_query_c0_short_body(self) -> None:
        """Skip Message parse query C0 when the body is too short."""
        self.header[9] = 0x03
        body = bytearray(A0_A1_C0_MIN_BODY_LENGTH)
        body[0] = 0xC0  # Body type

        response = MessageACResponse(self.header + body)

        assert not hasattr(response, "power")

    @pytest.mark.parametrize(
        ("minimum", "index", "value", "attribute"),
        [
            (FROST_PROTECT_MIN_LENGTH, 21, 0x80, "frost_protect"),
            (SMART_DRY_MIN_LENGTH, 19, 0x01, "smart_dry"),
            (CONFORT_MODE_MIN_LENGTH2, 22, 0x01, "comfort_mode"),
        ],
    )
    def test_message_query_c0_tail_field_boundaries(
        self,
        minimum: int,
        index: int,
        value: int,
        attribute: str,
    ) -> None:
        """Test C0 optional fields at their parser-visible length boundaries."""
        self.header[9] = 0x03

        for visible_length, expected in (
            (minimum - 1, False),
            (minimum, True),
        ):
            body = bytearray(visible_length + 1)
            body[0] = 0xC0  # Body type
            body[index] = value

            response = MessageACResponse(self.header + body)

            assert getattr(response, attribute, False) is expected

    def test_message_query_c0_fresh_filter(self) -> None:
        """Test Message parse query C0 with fresh filter bytes."""
        self.header[9] = 0x03
        body = bytearray(31)  # stripped body length 30 >= FRESH_AIR_C0_MIN_LENGTH
        body[0] = 0xC0  # Body type
        body[13] = 0x40  # Fresh filter timeout bit
        body[24] = 0x10  # Fresh filter time total low byte
        body[25] = 0x01  # Fresh filter time total high byte
        body[26] = 0x20  # Fresh filter time use low byte
        body[27] = 0x02  # Fresh filter time use high byte

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "fresh_filter_time_total")
        assert response.fresh_filter_time_total == 0x01 * 256 + 0x10
        assert hasattr(response, "fresh_filter_time_use")
        assert response.fresh_filter_time_use == 0x02 * 256 + 0x20
        assert hasattr(response, "fresh_filter_timeout")
        assert response.fresh_filter_timeout == 1

    def test_message_query_c1_0x45(self) -> None:
        """Test Message parse query C1 0x45 indoor humidity."""
        self.header[9] = 0x03
        body = bytearray(20)
        body[0] = 0xC1  # Body type
        body[3] = 0x45  # Set the type to 0x45
        body[4] = 55  # Indoor humidity
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "indoor_humidity")
        assert response.indoor_humidity == 55

        body[4] = 0  # Indoor humidity unavailable
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "indoor_humidity")
        assert response.indoor_humidity is None

    def test_message_query_c1_unknown_method(self) -> None:
        """Test Message parse query C1 with an unknown analysis method."""
        self.header[9] = 0x03
        body = bytearray(20)
        body[0] = 0xC1  # Body type
        body[3] = 0x44  # Set the type to 0x44
        body[4] = 0x12  # Total energy consumption byte, ignored
        body[16] = 0x11  # Real-time power byte, ignored
        response = MessageACResponse(self.header + body, 5)
        assert hasattr(response, "total_energy_consumption")
        assert response.total_energy_consumption == 0.0
        assert hasattr(response, "current_energy_consumption")
        assert response.current_energy_consumption == 0.0
        assert hasattr(response, "realtime_power")
        assert response.realtime_power == 0.0

    def test_message_query_c1_method1(self) -> None:
        """Test Message parse query C1 method1."""
        self.header[9] = 0x03
        body = bytearray(20)
        body[0] = 0xC1  # Body type
        body[3] = 0x44  # Set the type to 0x44

        # Total energy consumption bytes
        body[4] = 0x12  # High nibble: 1, Low nibble: 2 (value: 12)
        body[5] = 0x34  # High nibble: 3, Low nibble: 4 (value: 34)
        body[6] = 0x56  # High nibble: 5, Low nibble: 6 (value: 56)
        body[7] = 0x78  # High nibble: 7, Low nibble: 8 (value: 78)
        expected_total_energy = float(12 * 1000000 + 34 * 10000 + 56 * 100 + 78) / 100

        # Current energy consumption bytes
        body[12] = 0x87  # High nibble: 8, Low nibble: 7 (value: 87)
        body[13] = 0x65  # High nibble: 6, Low nibble: 5 (value: 65)
        body[14] = 0x43  # High nibble: 4, Low nibble: 3 (value: 43)
        body[15] = 0x21  # High nibble: 2, Low nibble: 1 (value: 21)
        expected_current_energy = float(87 * 1000000 + 65 * 10000 + 43 * 100 + 21) / 100

        # Real-time power bytes
        body[16] = 0x11  # High nibble: 1, Low nibble: 1 (value: 11)
        body[17] = 0x22  # High nibble: 2, Low nibble: 2 (value: 22)
        body[18] = 0x33  # High nibble: 3, Low nibble: 3 (value: 33)
        expected_realtime_power = float(11 * 10000 + 22 * 100 + 33) / 10

        response = MessageACResponse(self.header + body, 1)

        assert hasattr(response, "total_energy_consumption")
        assert response.total_energy_consumption == expected_total_energy
        assert hasattr(response, "current_energy_consumption")
        assert response.current_energy_consumption == expected_current_energy
        assert hasattr(response, "realtime_power")
        assert response.realtime_power == expected_realtime_power

    def _assert_message_query_c1_method2(self, method: int) -> None:
        """Assert Message parse query C1 method2 (and 12)."""
        self.header[9] = 0x03
        body = bytearray(20)
        body[0] = 0xC1  # Body type
        body[3] = 0x44  # Set the type to 0x44

        # method 12 is like 2, but with 0.01kWh resolution instead of 0.1kWh
        energy_divisor = 10 if method == 2 else 100

        # Total energy consumption bytes
        body[4] = 0x01
        body[5] = 0x23
        body[6] = 0x45
        body[7] = 0x67
        expected_total_energy = (
            float((0x01 << 24) + (0x23 << 16) + (0x45 << 8) + 0x67) / energy_divisor
        )

        # Current energy consumption bytes
        body[12] = 0x89
        body[13] = 0xAB
        body[14] = 0xCD
        body[15] = 0xEF
        expected_current_energy = (
            float((0x89 << 24) + (0xAB << 16) + (0xCD << 8) + 0xEF) / energy_divisor
        )

        # Real-time power bytes
        body[16] = 0x12
        body[17] = 0x34
        body[18] = 0x56
        expected_realtime_power = float((0x12 << 16) + (0x34 << 8) + 0x56) / 10

        response = MessageACResponse(self.header + body, method)

        assert hasattr(response, "total_energy_consumption")
        assert response.total_energy_consumption == expected_total_energy
        assert hasattr(response, "current_energy_consumption")
        assert response.current_energy_consumption == expected_current_energy
        assert hasattr(response, "realtime_power")
        assert response.realtime_power == expected_realtime_power

    def test_message_query_c1_method2(self) -> None:
        """Test Message parse query C1 method2."""
        self._assert_message_query_c1_method2(2)

    def test_message_query_c1_method12(self) -> None:
        """Test Message parse query C1 method12."""
        self._assert_message_query_c1_method2(12)

    def test_message_query_c1_bcd_energy_binary_power(self) -> None:
        """Test C1 format with BCD energy counters and binary realtime watts."""
        self.header[9] = 0x03
        samples = [
            (
                "c12101440000005800000000000000160016b700000001a9",
                0.58,
                0.16,
                581.5,
            ),
            (
                "c12101440000005900000000000000170016a30000000105",
                0.59,
                0.17,
                579.5,
            ),
            (
                "c12101440000005a000000000000001800162b0000000187",
                0.60,
                0.18,
                567.5,
            ),
        ]

        for payload, total_kwh, current_kwh, watts in samples:
            response = MessageACResponse(
                self.header + bytearray.fromhex(payload),
                PowerFormats.BCD_ENERGY_BINARY_POWER,
            )

            assert hasattr(response, "total_energy_consumption")
            assert response.total_energy_consumption == total_kwh
            assert hasattr(response, "current_energy_consumption")
            assert response.current_energy_consumption == current_kwh
            assert hasattr(response, "realtime_power")
            assert response.realtime_power == watts

    def test_message_query_c1_method3(self) -> None:
        """Test Message parse query C1 method3."""
        self.header[9] = 0x03
        body = bytearray(20)
        body[0] = 0xC1  # Body type
        body[3] = 0x44  # Set the type to 0x44
        # Total energy consumption bytes
        body[4] = 0x12
        body[5] = 0x34
        body[6] = 0x56
        body[7] = 0x78
        expected_total_energy = (
            float(0x12 * 1000000 + 0x34 * 10000 + 0x56 * 100 + 0x78) / 100
        )

        # Current energy consumption bytes
        body[12] = 0x87
        body[13] = 0x65
        body[14] = 0x43
        body[15] = 0x21
        expected_current_energy = (
            float(0x87 * 1000000 + 0x65 * 10000 + 0x43 * 100 + 0x21) / 100
        )
        # Real-time power bytes
        body[16] = 0x11
        body[17] = 0x22
        body[18] = 0x33
        expected_realtime_power = float(0x11 * 10000 + 0x22 * 100 + 0x33) / 10
        response = MessageACResponse(self.header + body)

        assert hasattr(response, "total_energy_consumption")
        assert response.total_energy_consumption == expected_total_energy
        assert hasattr(response, "current_energy_consumption")
        assert response.current_energy_consumption == expected_current_energy
        assert hasattr(response, "realtime_power")
        assert response.realtime_power == expected_realtime_power

    def test_message_query_c1_0x40(self) -> None:
        """Test Message parse query C1 0x40."""
        self.header[9] = 0x03
        body = bytearray(20)
        body[0] = 0xC1  # Body type
        body[3] = 0x40
        response = MessageACResponse(self.header + body)
        assert not hasattr(response, "total_energy_consumption")
        assert not hasattr(response, "current_energy_consumption")
        assert not hasattr(response, "realtime_power")

    def test_message_query_c1_0x41(self) -> None:
        """Test Message parse query C1 0x41, compressor group data."""
        self.header[9] = 0x03
        body = bytearray(20)
        body[0] = 0xC1  # Body type
        body[3] = 0x41  # group 1
        body[4] = 28  # compressor frequency
        body[5] = 25  # target compressor frequency
        body[7] = 1  # compressor current
        body[8] = 232  # compressor voltage
        body[10] = 71  # T1: (71 - 30) / 2 = 20.5
        body[11] = 38  # T2: (38 - 30) / 2 = 4.0
        body[12] = 102  # T3: (102 - 50) / 2 = 26.0
        body[13] = 88  # T4: (88 - 50) / 2 = 19.0
        body[14] = 36  # TP: 36

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "compressor_frequency")
        assert response.compressor_frequency == 28
        assert hasattr(response, "target_compressor_frequency")
        assert response.target_compressor_frequency == 25
        assert hasattr(response, "compressor_current")
        assert response.compressor_current == 1
        assert hasattr(response, "compressor_voltage")
        assert response.compressor_voltage == 232
        assert hasattr(response, "indoor_ambient_temperature")
        assert response.indoor_ambient_temperature == 20.5
        assert hasattr(response, "indoor_coil_temperature")
        assert response.indoor_coil_temperature == 4.0
        assert hasattr(response, "outdoor_coil_temperature")
        assert response.outdoor_coil_temperature == 26.0
        assert hasattr(response, "outdoor_ambient_temperature")
        assert response.outdoor_ambient_temperature == 19.0
        assert hasattr(response, "discharge_pipe_temperature")
        assert response.discharge_pipe_temperature == 36

    def test_message_query_c1_0x41_short_body(self) -> None:
        """Test Message parse query C1 0x41 with a truncated body."""
        self.header[9] = 0x03
        body = bytearray(10)
        body[0] = 0xC1  # Body type
        body[3] = 0x41  # group 1

        response = MessageACResponse(self.header + body)
        assert not hasattr(response, "compressor_frequency")
        assert not hasattr(response, "discharge_pipe_temperature")

    def test_message_query_c1_0x42(self) -> None:
        """Test Message parse query C1 0x42, indoor fan group data."""
        self.header[9] = 0x03
        body = bytearray(20)
        body[0] = 0xC1  # Body type
        body[3] = 0x42  # group 2
        body[4] = 52  # target indoor fan speed: 52 * 8 = 416
        body[5] = 53  # indoor fan speed: 53 * 8 = 424
        body[8] = 0x10  # water pump running

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "target_indoor_fan_speed")
        assert response.target_indoor_fan_speed == 416
        assert hasattr(response, "indoor_fan_speed")
        assert response.indoor_fan_speed == 424
        assert hasattr(response, "water_pump_running")
        assert response.water_pump_running is True

    def test_message_query_c1_0x42_idle(self) -> None:
        """Test Message parse query C1 0x42 with fan and pump stopped."""
        self.header[9] = 0x03
        body = bytearray(20)
        body[0] = 0xC1  # Body type
        body[3] = 0x42  # group 2

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "indoor_fan_speed")
        assert response.indoor_fan_speed == 0
        assert hasattr(response, "water_pump_running")
        assert response.water_pump_running is False

    def test_message_query_c1_0x42_short_body(self) -> None:
        """Test Message parse query C1 0x42 with a truncated body."""
        self.header[9] = 0x03
        body = bytearray(9)
        body[0] = 0xC1  # Body type
        body[3] = 0x42  # group 2

        response = MessageACResponse(self.header + body)
        assert not hasattr(response, "indoor_fan_speed")
        assert not hasattr(response, "water_pump_running")

    def test_message_query_c1_0x47(self) -> None:
        """Test Message parse query C1 0x47, compressor power group data."""
        self.header[9] = 0x03
        body = bytearray(20)
        body[0] = 0xC1  # Body type
        body[3] = 0x47  # group 7
        body[10] = 13  # 13 + (1 << 8) = 269 W
        body[11] = 1

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "compressor_power")
        assert response.compressor_power == 269

    def test_message_query_c1_0x47_short_body(self) -> None:
        """Test Message parse query C1 0x47 with a truncated body."""
        self.header[9] = 0x03
        body = bytearray(10)
        body[0] = 0xC1  # Body type
        body[3] = 0x47  # group 7

        response = MessageACResponse(self.header + body)
        assert not hasattr(response, "compressor_power")

    def test_captured_c1_0x41_response(self) -> None:
        """Test a complete response captured from model 22390001 subtype 8."""
        frame = bytearray.fromhex(
            "aa29ac00000000000803c12101412b2b0403d6005446736c2600000000000000"
            "00000000000000019e8b",
        )

        response = MessageACResponse(frame)

        assert hasattr(response, "compressor_frequency")
        assert response.compressor_frequency == 43
        assert hasattr(response, "target_compressor_frequency")
        assert response.target_compressor_frequency == 43
        assert hasattr(response, "compressor_current")
        assert response.compressor_current == 3
        assert hasattr(response, "compressor_voltage")
        assert response.compressor_voltage == 214

    def test_short_c1_response_does_not_raise(self) -> None:
        """Test short C1 response ignores a missing group type."""
        self.header[9] = 0x03

        MessageACResponse(self.header + bytearray([0xC1, 0, 0]))

    @pytest.mark.parametrize("group_type", [0x40, 0x41, 0x42, 0x44, 0x45, 0x47])
    def test_recognized_short_c1_response_does_not_raise(
        self,
        group_type: int,
    ) -> None:
        """Test recognized C1 groups ignore fields missing from a short frame."""
        self.header[9] = 0x03
        body = bytearray([0xC1, 0, 0, group_type])

        MessageACResponse(self.header + body + bytearray([0]))

    def test_message_query_bb_0x20(self) -> None:
        """Test Message parse query BB 0x20."""
        self.header[9] = 0x03
        body = bytearray(100)
        body[:6] = bytearray([0xBB, 0, 0, 0, 0, 0x20])  # Set the header and data type
        body[6] = 0b00110001  # Power, dry, boost_mode
        body[7] = 0b01000000  # aux_heating
        body[8] = 0b10000000  # sleep_mode
        body[11] = 2  # Mode index for BB_AC_MODES
        body[12] = 0x3C  # Target temperature: ((60 - 30) / 2) = 15.0
        body[13] = 127  # Fan speed
        body[31] = 0b01000100  # Timer, eco_mode

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "power")
        assert hasattr(response, "dry")
        assert hasattr(response, "boost_mode")
        assert hasattr(response, "aux_heating")
        assert hasattr(response, "sleep_mode")
        assert hasattr(response, "mode")
        assert response.mode == 1
        assert hasattr(response, "target_temperature")
        assert response.target_temperature == 15.0
        assert hasattr(response, "fan_speed")
        assert response.fan_speed == 127
        assert hasattr(response, "timer")
        assert hasattr(response, "eco_mode")

        body[11] = 10  # Invalid mode index for BB_AC_MODES
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "mode")
        assert response.mode == 0

    def test_message_query_bb_0x11_fresh_air(self) -> None:
        """Test BB basic status parses independent intake and exhaust airflow."""
        self.header[9] = 0x03
        body = bytearray(56)
        body[:6] = bytearray([0xBB, 0, 0, 0, 0, 0x11])
        body[51] = 0x03
        body[52] = 60
        body[53] = 100

        response = MessageACResponse(self.header + body)

        assert hasattr(response, "bb_fresh_air_power")
        assert response.bb_fresh_air_power is True
        assert hasattr(response, "bb_fresh_air_fan_speed")
        assert response.bb_fresh_air_fan_speed == 60
        assert hasattr(response, "bb_fresh_air_exhaust_power")
        assert response.bb_fresh_air_exhaust_power is True
        assert hasattr(response, "bb_fresh_air_exhaust_speed")
        assert response.bb_fresh_air_exhaust_speed == 100

    def test_captured_bb_0x11_fresh_air_response(self) -> None:
        """Test a complete fresh-air response captured from model 23096633."""
        frame = bytearray.fromhex(
            "aa5aac00000000000803bb5000ffff1101800000000057663200000000320001"
            "2800007804523266000400000000000000000000000000000000000000413c64"
            "0000002f000001e00000400003002828003000000000000046b7ef",
        )

        response = MessageACResponse(frame)

        assert hasattr(response, "bb_fresh_air_power")
        assert response.bb_fresh_air_power is True
        assert hasattr(response, "bb_fresh_air_fan_speed")
        assert response.bb_fresh_air_fan_speed == 60
        assert hasattr(response, "bb_fresh_air_exhaust_power")
        assert response.bb_fresh_air_exhaust_power is False
        assert hasattr(response, "bb_fresh_air_exhaust_speed")
        assert response.bb_fresh_air_exhaust_speed == 100

    def test_message_query_bb_0x10(self) -> None:
        """Test Message parse query BB 0x20."""
        self.header[9] = 0x03
        body = bytearray(100)
        body[:6] = bytearray([0xBB, 0, 0, 0, 0, 0x10])  # Set the header and data type
        body[14] = 0x88  # Indoor temperature byte 2
        body[13] = 0x77  # Indoor temperature byte 1
        body[36] = 60  # Indoor humidity
        body[86] = 0x31  # sn8_flag

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "indoor_temperature")
        assert response.indoor_temperature == 349.35
        assert hasattr(response, "indoor_humidity")
        assert response.indoor_humidity == 60
        assert hasattr(response, "sn8_flag")

        body[14] = 0x78  # Indoor temperature byte 2
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "indoor_temperature")
        assert response.indoor_temperature == 308.39

    def test_message_query_bb_0x30(self) -> None:
        """Test Message parse query BB 0x30."""
        self.header[9] = 0x03
        body = bytearray(100)
        body[:6] = bytearray([0xBB, 0, 0, 0, 0, 0x30])  # Set the header and data type
        body[11] = 0x22  # Outdoor temperature byte 1
        body[12] = 0x80  # Outdoor temperature byte 2
        body[16] = 49  # Compressor target frequency
        body[17] = 47  # Compressor actual frequency

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature == 328.02
        assert hasattr(response, "target_compressor_frequency")
        assert response.target_compressor_frequency == 49
        assert hasattr(response, "compressor_frequency")
        assert response.compressor_frequency == 47

        body[12] = 0x65  # Outdoor temperature byte 2

        response = MessageACResponse(self.header + body)
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature == 258.9

    def test_captured_bb_0x30_frequency_response(self) -> None:
        """Test a complete frequency response captured from model 23096633."""
        frame = bytearray.fromhex(
            "aa6aac00000000000803bb6000ffff3000ff000000a60e8e12433131c000079b"
            "0000000000000000000000630000000000000000000000000000000000000000"
            "0000000000000000000000000000000000000000000000000000000000000000"
            "002f000000000000e5e6df",
        )

        assert len(frame) == frame[1] + 1
        assert len(frame[10:-1]) == frame[11]
        assert calculate(frame[10:-2]) == 0
        assert MessageBase.checksum(frame[1:-1]) == frame[-1]

        response = MessageACResponse(frame)

        assert hasattr(response, "target_compressor_frequency")
        assert response.target_compressor_frequency == 49
        assert hasattr(response, "compressor_frequency")
        assert response.compressor_frequency == 49

    @pytest.mark.parametrize("data_type", [0x10, 0x30])
    def test_short_bb_response_does_not_raise(
        self,
        data_type: int,
    ) -> None:
        """Test short BB responses enter parsing without reading absent fields."""
        self.header[9] = 0x03
        body = bytearray(21)
        body[:6] = bytearray([0xBB, 0, 0, 0, 0, data_type])

        response = MessageACResponse(self.header + body + bytearray([0]))

        assert response.used_subprotocol is True
        if data_type == 0x10:
            assert not hasattr(response, "indoor_humidity")
            assert not hasattr(response, "sn8_flag")

    def test_message_query_bb_unimplemented(self) -> None:
        """Test Message parse query BB unimplemented."""
        self.header[9] = 0x03
        body = bytearray(100)
        body[:6] = bytearray([0xBB, 0, 0, 0, 0, 0x12])  # Set the header and data type
        response = MessageACResponse(self.header + body)
        assert not hasattr(response, "power")

        body[5] = 0x13
        response = MessageACResponse(self.header + body)
        assert not hasattr(response, "power")

    def test_message_query_c0_anion(self) -> None:
        """Test anion parsed from C0 body (purifier bit 0x20 in byte 9)."""
        self.header[9] = 0x03
        body = bytearray(24)
        body[0] = 0xC0
        body[9] = 0x20  # purifier/anion bit set
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "anion")
        assert response.anion is True

        body[9] = 0x00
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "anion")
        assert response.anion is False

    def test_message_query_c0_pmv(self) -> None:
        """Test PMV parsed from C0 body (low nibble of byte 14)."""
        self.header[9] = 0x03
        body = bytearray(24)
        body[0] = 0xC0
        body[14] = 0x07  # PMV nibble = 7 → 7*0.5 - 3.5 = 0.0
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "pmv")
        assert response.pmv == 0.0

        body[14] = 0x00  # PMV nibble = 0 → 0*0.5 - 3.5 = -3.5
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "pmv")
        assert response.pmv == -3.5

    def test_message_b1_error_code(self) -> None:
        """Test error_code parsed from B1 response."""
        self.header[9] = 0x03
        body = bytearray(10)
        body[0] = 0xB1
        body[1] = 0x01  # 1 param
        body[2] = CapabilityTag.error_code & 0xFF
        body[3] = CapabilityTag.error_code >> 8
        body[4] = 0x00  # padding
        body[5] = 0x01  # length
        body[6] = 0x05  # error code 5
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "error_code")
        assert response.error_code == 5

    def test_message_b1_sound(self) -> None:
        """Test sound parsed from B1 response (sound tag)."""
        self.header[9] = 0x03
        body = bytearray(10)
        body[0] = 0xB1
        body[1] = 0x01
        body[2] = CapabilityTag.sound & 0xFF
        body[3] = CapabilityTag.sound >> 8
        body[4] = 0x00
        body[5] = 0x01
        body[6] = 0x01  # sound on
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "sound")
        assert response.sound is True

        body[6] = 0x00
        response = MessageACResponse(self.header + body)
        assert hasattr(response, "sound")
        assert response.sound is False

    def test_message_b5_notify2_0x7e_temperature_parse(self) -> None:
        """Test 0x7e tag parsing for the model-22013279 temperature layout."""
        self.header[9] = 0x05
        body = bytearray(62)
        body[0] = 0xB5
        body[1] = 0x01
        body[2] = 0x7E
        body[3] = 0x00
        body[4] = 0x38

        # 0x7e payload (56 bytes)
        payload = bytearray(
            [
                0xA0,
                0x1D,  # (_t[1] & 0x3F)/2 + 11.5 -> 26.0
                0x41,
                0x66,
                0x7F,
                0x7F,
                0x00,
                0x00,
                0x00,
                0x04,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x78,
                0x00,
                0x4C,
                0x00,
                0xC0,
                0x00,
                0x00,
                0x00,
                0x00,
                0x64,
                0x00,
                0x64,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x6A,
                0x08,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x05,
                0x00,
            ],
        )
        body[5 : 5 + len(payload)] = payload

        response = MessageACResponse(self.header + body, new_protocol_temperature=True)
        assert hasattr(response, "has_new_protocol_temperature")
        assert response.has_new_protocol_temperature is True
        assert hasattr(response, "target_temperature")
        assert response.target_temperature == 26.0
        assert hasattr(response, "indoor_temperature")
        assert response.indoor_temperature == 28.8
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature is None

    def test_message_b5_notify2_0x7e_temperature_parse_fallback(self) -> None:
        """Fallback to legacy byte-3 mapping when byte-1 decoding is out of range."""
        self.header[9] = 0x05
        body = bytearray(62)
        body[0] = 0xB5
        body[1] = 0x01
        body[2] = 0x7E
        body[3] = 0x00
        body[4] = 0x38

        payload = bytearray(
            [
                0xA0,
                0x7F,  # byte-1 mapping would exceed sane range (>40)
                0x41,
                0x64,  # fallback byte-3 mapping -> (100 - 50) / 2 = 25.0
                0x7F,
                0x7F,
                0x00,
                0x00,
                0x00,
                0x04,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x78,
                0x00,
                0x4C,
                0x00,
                0xC0,
                0x00,
                0x00,
                0x00,
                0x00,
                0x64,
                0x00,
                0x64,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x6A,
                0x08,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x05,
                0x00,
            ],
        )
        body[5 : 5 + len(payload)] = payload

        response = MessageACResponse(self.header + body, new_protocol_temperature=True)
        assert hasattr(response, "target_temperature")
        assert response.target_temperature == 25.0

    def test_message_b5_notify2_0x7e_temperature_parse_fallback_invalid(self) -> None:
        """Fallback to legacy byte-3 mapping when byte-1 decoding is out of range."""
        self.header[9] = 0x05
        body = bytearray(62)
        body[0] = 0xB5
        body[1] = 0x01
        body[2] = 0x7E
        body[3] = 0x00
        body[4] = 0x38

        payload = bytearray(
            [
                0xA0,
                0x7F,  # byte-1 mapping would exceed sane range (>40)
                0x41,
                0x88,  # fallback byte-3 mapping -> (136 - 50) / 2 = 43.0 (>40)
                0x7F,
                0x7F,
                0x00,
                0x00,
                0x00,
                0x04,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x78,
                0x00,
                0x4C,
                0x00,
                0xC0,
                0x00,
                0x00,
                0x00,
                0x00,
                0x64,
                0x00,
                0x64,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x6A,
                0x08,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x05,
                0x00,
            ],
        )
        body[5 : 5 + len(payload)] = payload

        response = MessageACResponse(self.header + body, new_protocol_temperature=True)
        assert not hasattr(response, "target_temperature")

    def test_message_b5_notify2_0x7e_rejects_invalid_indoor_temperature(
        self,
    ) -> None:
        """Ignore a 0x7e payload whose decoded indoor temperature is invalid."""
        self.header[9] = 0x05
        body = bytearray(62)
        body[0] = 0xB5
        body[1] = 0x01
        body[2] = 0x7E
        body[3] = 0x00
        body[4] = 0x38
        payload = bytearray(56)
        payload[1] = 0x1D  # valid 26.0 C setpoint
        payload[40] = 0x00  # decodes to the reported invalid -25.0 C
        body[5 : 5 + len(payload)] = payload

        response = MessageACResponse(self.header + body, new_protocol_temperature=True)

        assert not hasattr(response, "has_new_protocol_temperature")
        assert not hasattr(response, "target_temperature")
        assert not hasattr(response, "indoor_temperature")
        assert not hasattr(response, "outdoor_temperature")

    def test_message_b5_notify2_0x7e_temperature_too_short(self) -> None:
        """Test the 0x7e tag is ignored when shorter than the expected payload."""
        self.header[9] = 0x05
        body = bytearray(16)
        body[0] = 0xB5
        body[1] = 0x01
        body[2] = 0x7E
        body[3] = 0x00
        body[4] = 0x0A  # length 10, at/below NEW_PROTOCOL_TEMPERATURE_MIN_LENGTH
        body[5 : 5 + 10] = bytearray(10)

        response = MessageACResponse(self.header + body, new_protocol_temperature=True)
        assert not hasattr(response, "has_new_protocol_temperature")
        assert not hasattr(response, "target_temperature")
        assert not hasattr(response, "indoor_temperature")
        assert not hasattr(response, "outdoor_temperature")

    def test_message_b5_notify2_0x7e_ignored_without_temperature_gate(self) -> None:
        """Test the 0x7e tag is ignored without the model-specific gate."""
        self.header[9] = 0x05
        body = bytearray(62)
        body[0] = 0xB5
        body[1] = 0x01
        body[2] = 0x7E
        body[3] = 0x00
        body[4] = 0x38
        payload = bytearray(56)
        payload[1] = 0x1D  # decodes to a plausible 26.0 C setpoint
        payload[40] = 0x6A  # decodes to a plausible 28.8 C indoor temperature
        payload[41] = 0x08
        body[5 : 5 + len(payload)] = payload

        response = MessageACResponse(self.header + body)

        # The payload decodes to in-range temperatures, so only the subtype
        # gate keeps another model's unrelated 0x7e content out.
        assert not hasattr(response, "has_new_protocol_temperature")
        assert not hasattr(response, "target_temperature")
        assert not hasattr(response, "indoor_temperature")
        assert not hasattr(response, "outdoor_temperature")


class TestNewProtocolSetNewFeatures:
    """Test PropertiesSet for sound, self_clean and degerming."""

    def test_degerming_packed_with_prompt_tone(self) -> None:
        """Test degerming packs the 0x5a tag right after prompt_tone.

        The expected bytes match a set frame captured from a live device
        (model 22019053), echoed frame body b0 02 1a 00 01 01 5a 00 01 00.
        """
        msg = PropertiesSet(protocol_version=ProtocolVersion.V1)
        msg.prompt_tone = b"\x01"
        msg.degerming = False
        assert msg.body[:-2] == bytearray.fromhex("b0021a0001015a000100")

    def test_degerming_on_packs_one(self) -> None:
        """Test degerming on packs 0x01 as the value byte."""
        msg = PropertiesSet(protocol_version=ProtocolVersion.V1)
        msg.prompt_tone = b"\x01"
        msg.degerming = True
        assert msg.body[:-2] == bytearray.fromhex("b0021a0001015a000101")

    def test_degerming_absent_when_unset(self) -> None:
        """Test degerming is not packed when left as None."""
        msg = PropertiesSet(protocol_version=ProtocolVersion.V1)
        msg.prompt_tone = b"\x01"
        assert msg.body[:-2] == bytearray.fromhex("b0011a000101")

    @pytest.mark.parametrize(
        ("value", "expected_byte"),
        [(True, 0x01), (False, 0x00)],
    )
    def test_sound_on_off(self, value: bool, expected_byte: int) -> None:
        """Test sound set to on/off sends correct byte."""
        msg = PropertiesSet(protocol_version=ProtocolVersion.V1)
        msg.sound = value
        body = msg.body
        assert body[0] == 0xB0
        assert body[1] == 0x01
        assert body[2] == CapabilityTag.sound & 0xFF
        assert body[3] == CapabilityTag.sound >> 8
        assert body[4] == 0x01
        assert body[5] == expected_byte

    @pytest.mark.parametrize(
        ("value", "expected_byte"),
        [(True, 0x01), (False, 0x00)],
    )
    def test_self_clean_on_off(self, value: bool, expected_byte: int) -> None:
        """Test self_clean set to on/off sends correct byte."""
        msg = PropertiesSet(protocol_version=ProtocolVersion.V1)
        msg.self_clean = value
        body = msg.body
        assert body[0] == 0xB0
        assert body[1] == 0x01
        assert body[2] == CapabilityTag.self_clean & 0xFF
        assert body[3] == CapabilityTag.self_clean >> 8
        assert body[4] == 0x01
        assert body[5] == expected_byte


class TestNewProtocolSetIeco:
    """Test PropertiesSet for iECO."""

    @pytest.mark.parametrize(
        ("value", "expected_switch"),
        [(True, 0x01), (False, 0x00)],
    )
    def test_ieco_on_off(self, value: bool, expected_switch: int) -> None:
        """Test iECO set to on/off sends the frame/number/switch payload."""
        msg = PropertiesSet(protocol_version=ProtocolVersion.V1)
        msg.ieco = value
        msg.ieco_number = 3
        body = msg.body
        assert body[0] == 0xB0
        assert body[1] == 0x01  # pack count
        assert body[2] == CapabilityTag.ieco & 0xFF
        assert body[3] == CapabilityTag.ieco >> 8
        assert body[4] == 0x0D  # value length: 3 + 10 padding
        assert body[5] == 0x00  # frame
        assert body[6] == 0x03  # ieco number
        assert body[7] == expected_switch  # switch
        # remaining padding bytes are zero
        assert body[8:18] == bytearray(10)

    def test_ieco_defaults_number_to_one(self) -> None:
        """Test iECO uses gear 1 by default when no number is set."""
        msg = PropertiesSet(protocol_version=ProtocolVersion.V1)
        msg.ieco = True
        body = msg.body
        assert body[6] == 0x01

    def test_ieco_absent_when_unset(self) -> None:
        """Test iECO is not packed when left as None."""
        msg = PropertiesSet(protocol_version=ProtocolVersion.V1)
        body = msg.body
        assert body[1] == 0x00  # no params packed


class TestMessageSetAnion:
    """Test StateSet anion (purifier) bit."""

    @pytest.mark.parametrize(
        ("value", "expected_bit"),
        [(True, 0x20), (False, 0x00)],
    )
    def test_anion_bit_in_body(self, value: bool, expected_bit: int) -> None:
        """Test anion sets bit 0x20 in body byte index 8."""
        msg = StateSet(protocol_version=ProtocolVersion.V1)
        msg.anion = value
        assert msg._body[8] & 0x20 == expected_bit
