"""Test BF message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.bf.message import (
    FirePower,
    MessageBFBody,
    MessageBFResponse,
    MessageQuery,
    MessageSet,
    WorkStatus,
    work_mode_to_bytes,
    work_mode_to_name,
)
from midealocal.message import ListTypes, MessageType


class TestMessageQuery:
    """Test MessageQuery."""

    def test_query_body(self) -> None:
        """Test query body."""
        query = MessageQuery(protocol_version=ProtocolVersion.V1)
        # body_type 0x01 is the entire body per lua's jsonToData; no extra content byte
        assert query.body == bytearray([ListTypes.X01])


class TestWorkModeHelpers:
    """Test work mode mapping helpers."""

    def test_work_mode_to_bytes_known(self) -> None:
        """Test known work mode conversion."""
        assert work_mode_to_bytes("microwave") == (0x01, 0x00)
        assert work_mode_to_bytes("pure_steam") == (0x29, 0x00)
        assert work_mode_to_bytes("above_tube") == (0x51, 0x00)
        assert work_mode_to_bytes("eco") == (0xA2, 0x00)

    def test_work_mode_to_bytes_unknown(self) -> None:
        """Test unknown work mode returns 0xFF."""
        assert work_mode_to_bytes("nonexistent_mode") == (0xFF, 0xFF)

    def test_work_mode_to_bytes_none(self) -> None:
        """Test None mode returns 0xFF."""
        assert work_mode_to_bytes(None) == (0xFF, 0xFF)

    def test_work_mode_to_name_known(self) -> None:
        """Test known work mode reverse conversion."""
        assert work_mode_to_name(0x01, 0x00) == "microwave"
        assert work_mode_to_name(0x29, 0x00) == "pure_steam"
        assert work_mode_to_name(0x51, 0x00) == "above_tube"

    def test_work_mode_to_name_unknown(self) -> None:
        """Test unknown bytes return 'unknown'."""
        assert work_mode_to_name(0xFF, 0xFF) == "unknown"

    def test_work_mode_to_bytes_low_variant(self) -> None:
        """Test work mode with low byte variant."""
        assert work_mode_to_bytes("microwave_1") == (0x01, 0x01)
        assert work_mode_to_bytes("pure_steam_5") == (0x29, 0x05)

    def test_work_mode_roundtrip(self) -> None:
        """Test roundtrip: name -> bytes -> name."""
        for name in ("microwave", "eco", "scale_clean"):
            result = work_mode_to_name(*work_mode_to_bytes(name))
            assert result == name


class TestFirePower:
    """Test FirePower enum."""

    def test_values(self) -> None:
        """Test FirePower values."""
        assert FirePower.fire_power_0.value == 0x00
        assert FirePower.fire_power_10.value == 0x0A

    def test_all_values(self) -> None:
        """Test all FirePower enum values cover 0..10."""
        for i in range(11):
            assert FirePower(i).value == i

    def test_invalid_value(self) -> None:
        """Test invalid FirePower value raises ValueError."""
        with pytest.raises(ValueError, match=r".*"):
            FirePower(0x0B)


class TestWorkStatus:
    """Test WorkStatus enum."""

    def test_values(self) -> None:
        """Test WorkStatus values."""
        assert WorkStatus.save_power.value == 0x01
        assert WorkStatus.standby.value == 0x02
        assert WorkStatus.work.value == 0x03
        assert WorkStatus.pause.value == 0x06

    def test_all_defined_values(self) -> None:
        """Test all defined WorkStatus members."""
        assert WorkStatus.work_finish.value == 0x04
        assert WorkStatus.order.value == 0x05
        assert WorkStatus.pause_c.value == 0x07
        assert WorkStatus.self_inspection.value == 0x0A
        assert WorkStatus.wait_to_start.value == 0x10

    def test_invalid_value(self) -> None:
        """Test invalid WorkStatus value raises ValueError."""
        with pytest.raises(ValueError, match=r".*"):
            WorkStatus(0x00)


class TestMessageSet:
    """Test MessageSet."""

    def test_message_type_is_set(self) -> None:
        """Test MessageSet uses MessageType.set."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        assert msg.message_type == MessageType.set

    @pytest.mark.parametrize(
        ("attr", "value", "index", "expected"),
        [
            pytest.param("power", True, 1, 0x11, id="power_on"),
            pytest.param("power", False, 1, 0x01, id="power_off"),
            pytest.param("child_lock", True, 2, 0x01, id="child_lock_on"),
            pytest.param("child_lock", False, 2, 0x00, id="child_lock_off"),
            pytest.param("furnace_light", True, 3, 0x01, id="furnace_light_on"),
            pytest.param("furnace_light", False, 3, 0x00, id="furnace_light_off"),
            pytest.param("door", True, 5, 0x01, id="door_open"),
            pytest.param("door", False, 5, 0x00, id="door_close"),
            pytest.param("hot_wind", True, 12, 0x01, id="hot_wind_on"),
            pytest.param("hot_wind", False, 12, 0x00, id="hot_wind_off"),
        ],
    )
    def test_set_not_work_mode_bool_field(
        self,
        attr: str,
        value: bool,
        index: int,
        expected: int,
    ) -> None:
        """Test boolean notWorkModeControl fields route and encode correctly."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        setattr(msg, attr, value)
        body = msg.body
        assert body[0] == ListTypes.X02
        assert body[index] == expected

    def test_set_screen_luminance(self) -> None:
        """Test setting screen_luminance routes to notWorkModeControl."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.screen_luminance = 5
        body = msg.body
        assert body[0] == ListTypes.X02
        assert body[8] == 5  # screen_luminance byte

    def test_set_volume(self) -> None:
        """Test setting volume routes to notWorkModeControl."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.volume = 8
        body = msg.body
        assert body[0] == ListTypes.X02
        assert body[9] == 8  # volume byte

    def test_set_work_status(self) -> None:
        """Test setting work_status routes to notWorkModeControl."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.work_status = "standby"
        body = msg.body
        assert body[0] == ListTypes.X02
        assert body[1] == WorkStatus.standby.value  # 0x02

    def test_not_work_mode_all_fields(self) -> None:
        """Test notWorkModeControl with all fields set."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.power = True
        msg.child_lock = True
        msg.furnace_light = True
        msg.door = True
        msg.hot_wind = True
        msg.screen_luminance = 3
        msg.volume = 7
        body = msg.body
        assert body[0] == ListTypes.X02
        assert body[1] == 0x11  # BYTE_POWER_ON
        assert body[2] == 0x01  # BYTE_LOCK_ON
        assert body[3] == 0x01  # BYTE_LIGHT_ON
        assert body[5] == 0x01  # BYTE_DOOR_OPEN
        assert body[8] == 3  # screen_luminance
        assert body[9] == 7  # volume
        assert body[12] == 0x01  # BYTE_HOT_WIND_ON

    def test_set_work_mode_routes_to_work_mode_control(self) -> None:
        """Test setting work_mode routes to workModeControl (body_type 0x01)."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.work_mode = "microwave"
        msg.work_hour = 0
        msg.work_minute = 30
        msg.work_second = 0
        body = msg.body
        assert body[0] == ListTypes.X01

    def test_work_mode_control_full(self) -> None:
        """Test workModeControl with full parameters."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.work_mode = "microwave"
        msg.work_hour = 1
        msg.work_minute = 30
        msg.work_second = 0
        msg.fire_power = "fire_power_5"
        msg.temperature = 200  # 200 = 0x00C8
        msg.probe_temperature = 80
        msg.steam_quantity = 3
        msg.pre_heat = True
        msg.turntable = True
        msg.hot_wind = True
        body = msg.body
        assert body[0] == ListTypes.X01  # body_type
        # b5 flags: pre_heat(0x01)+probe(0x02)+turntable(0x08)+hot_wind(0x10)
        assert body[5] & 0x01 != 0  # pre_heat bit
        assert body[5] & 0x08 != 0  # turntable bit
        assert body[5] & 0x10 != 0  # hot_wind bit
        assert body[6] == 0x01  # mode high (microwave)
        assert body[7] == 0x00  # mode low
        assert body[8] == 1  # hour
        assert body[9] == 30  # minute
        assert body[10] == 0  # second
        assert body[11] == 5  # fire_power_5 value

    def test_work_mode_control_temperature_above(self) -> None:
        """Test workModeControl with separate temperature_above."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.work_mode = "above_tube"
        msg.temperature_above = 200
        msg.temperature_underside = 180
        body = msg.body
        assert body[0] == ListTypes.X01
        # temperature_above = 200 -> high=0, low=200
        assert body[12] == 0  # temp_above_high
        assert body[13] == 200  # temp_above_low
        # temperature_underside = 180 -> high=0, low=180
        assert body[14] == 0  # temp_underside_high
        assert body[15] == 180  # temp_underside_low

    def test_work_mode_control_weight(self) -> None:
        """Test workModeControl with weight."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.work_mode = "microwave"
        msg.weight = 500  # weight / 10 = 50
        body = msg.body
        assert body[19] == 50  # weight / WEIGHT_DIVISOR

    def test_work_mode_control_people_number(self) -> None:
        """Test workModeControl with people_number (no weight set)."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.work_mode = "microwave"
        msg.people_number = 4
        body = msg.body
        assert body[19] == 4  # people_number

    def test_work_mode_control_no_flags(self) -> None:
        """Test workModeControl b5=0 when no flags set."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.work_mode = "microwave"
        body = msg.body
        assert body[5] == 0  # b5 flags all zero

    def test_set_hour_set_routes_to_set_control(self) -> None:
        """Test setting hour_set routes to setControl (body_type 0x03)."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.hour_set = 1
        body = msg.body
        assert body[0] == ListTypes.X03

    def test_set_no_control_fields_raises_value_error(self) -> None:
        """MessageSet with no serializable control fields raises ValueError.

        turntable is a work-mode-only field; without work_mode it cannot be
        serialized into any control body, so accessing body raises ValueError.
        """
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.turntable = False
        with pytest.raises(ValueError, match="no control fields"):
            _ = msg.body

    def test_set_control_param_sum_at_index_one(self) -> None:
        """ParamSum must be at body[1] (content), not overwrite first param id."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.hour_set = 1
        msg.minute_set = 30
        body = msg.body
        assert body[0] == ListTypes.X03  # body_type
        # content: [0x01, paramSum, 0x01(time id), hour, minute, second, ...]
        assert body[1] == 0x01  # header
        assert body[2] == 0x01  # paramSum = 1 (time group)
        assert body[3] == 0x01  # time param id preserved (not overwritten)

    @pytest.mark.parametrize(
        ("attr", "value", "param_id", "param_value"),
        [
            pytest.param("steam_set", 5, 0x00, 5, id="steam"),
            pytest.param("fire_power_set", "fire_power_8", 0x02, 0x08, id="fire_power"),
        ],
    )
    def test_set_control_single_byte_param(
        self,
        attr: str,
        value: int | str,
        param_id: int,
        param_value: int,
    ) -> None:
        """Test setControl with a single scalar param (steam_set, fire_power_set)."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        setattr(msg, attr, value)
        body = msg.body
        assert body[0] == ListTypes.X03
        assert body[1] == 0x01  # header
        assert body[2] == 0x01  # paramSum = 1
        assert body[3] == param_id
        assert body[4] == param_value

    def test_set_control_time_group(self) -> None:
        """Test setControl with time group (hour_set + minute_set + second_set)."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.hour_set = 1
        msg.minute_set = 30
        msg.second_set = 0
        body = msg.body
        assert body[0] == ListTypes.X03
        assert body[2] == 0x01  # paramSum = 1 (time)
        assert body[3] == 0x01  # time param id
        assert body[4] == 1  # hour
        assert body[5] == 30  # minute
        assert body[6] == 0  # second

    @pytest.mark.parametrize(
        ("attr", "value", "param_id"),
        [
            pytest.param("temp_set", 200, 0x03, id="temp"),  # 200 = 0x00C8
            pytest.param("probe_temp_set", 80, 0x04, id="probe_temp"),  # 80 = 0x0050
        ],
    )
    def test_set_control_temp_param(self, attr: str, value: int, param_id: int) -> None:
        """Test setControl with a 16-bit temp param (temp_set/probe_temp_set)."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        setattr(msg, attr, value)
        body = msg.body
        assert body[0] == ListTypes.X03
        assert body[2] == 0x01  # paramSum = 1
        assert body[3] == param_id
        assert body[4] == 0x00  # reserved
        assert body[5] == (value >> 8) & 0xFF  # temp high
        assert body[6] == value & 0xFF  # temp low

    @pytest.mark.parametrize(
        ("attr", "value", "sub_id"),
        [
            pytest.param("temp_above_set", 250, 0x00, id="above"),  # 250 = 0x00FA
            pytest.param("temp_underside_set", 180, 0x01, id="underside"),
        ],
    )
    def test_set_control_temp_above_underside_set(
        self,
        attr: str,
        value: int,
        sub_id: int,
    ) -> None:
        """Test setControl with temp_above_set/temp_underside_set."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        setattr(msg, attr, value)
        body = msg.body
        assert body[0] == ListTypes.X03
        assert body[2] == 0x01  # paramSum = 1
        assert body[3] == 0x05  # temp param id (shared)
        assert body[4] == 0x00  # sub-field 0
        assert body[5] == 0x00  # reserved
        assert body[6] == sub_id  # sub-id: above=0, underside=1
        assert body[7] == (value >> 8) & 0xFF  # temp high
        assert body[8] == value & 0xFF  # temp low

    def test_set_control_multiple_params(self) -> None:
        """Test setControl with multiple param groups."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.steam_set = 3
        msg.hour_set = 1
        msg.minute_set = 30
        msg.fire_power_set = "fire_power_5"
        body = msg.body
        assert body[0] == ListTypes.X03
        assert body[2] == 0x03  # paramSum = 3 (steam + time + fire_power)

    @pytest.mark.parametrize(
        ("value", "expected"),
        [
            pytest.param(True, 0x11, id="true"),
            pytest.param(False, 0x01, id="false"),
            pytest.param(None, 0xFF, id="none"),
        ],
    )
    def test_bool_to_byte(self, value: bool | None, expected: int) -> None:
        """Test _bool_to_byte for True/False/None."""
        assert MessageSet._bool_to_byte(value, 0x11, 0x01) == expected

    @pytest.mark.parametrize(
        ("name", "expected"),
        [
            pytest.param("fire_power_5", 5, id="known"),
            pytest.param(None, 0xFF, id="none"),
            pytest.param("unknown_power", 0xFF, id="unknown"),
        ],
    )
    def test_fire_power_value(self, name: str | None, expected: int) -> None:
        """Test _fire_power_value for known/None/unknown names."""
        assert MessageSet._fire_power_value(name) == expected

    @pytest.mark.parametrize(
        ("status", "expected"),
        [
            pytest.param("standby", 0x02, id="known"),
            pytest.param(None, 0xFF, id="none"),
            pytest.param("invalid_status", 0xFF, id="unknown"),
        ],
    )
    def test_work_status_value(self, status: str | None, expected: int) -> None:
        """Test _work_status_value for known/None/unknown statuses."""
        assert MessageSet._work_status_value(status) == expected

    def test_routing_priority_work_mode_over_not_work_mode(self) -> None:
        """Test work_mode takes priority over notWorkMode fields."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.work_mode = "microwave"
        msg.power = True  # would normally route to notWorkMode
        body = msg.body
        assert body[0] == ListTypes.X01  # workModeControl wins

    def test_routing_priority_not_work_mode_over_set_control(self) -> None:
        """Test notWorkMode takes priority over setControl fields."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.power = True  # notWorkMode field
        msg.hour_set = 1  # setControl field
        body = msg.body
        assert body[0] == ListTypes.X02  # notWorkMode wins


class TestMessageBFBody:
    """Test MessageBFBody parsing."""

    def _make_body(self, length: int = 60) -> bytearray:
        """Create a minimal body with given length, body_type at index 0."""
        body = bytearray(length)
        body[0] = 0x01  # body_type
        return body

    @pytest.mark.parametrize(
        ("byte_value", "expected"),
        [
            pytest.param(0x00, "ok", id="ok_default"),
            pytest.param(0x01, "status_nonsupport", id="status_nonsupport"),
            pytest.param(0x02, "function_nonsupport", id="function_nonsupport"),
            pytest.param(0x03, "param_range_error", id="param_range_error"),
            pytest.param(0xFF, "unknown", id="unknown"),
        ],
    )
    def test_execute_status(self, byte_value: int, expected: str) -> None:
        """Test execute status parsing for all known and unknown values."""
        body = self._make_body()
        body[1] = byte_value
        msg = MessageBFBody(body=body)
        assert msg.execute == expected

    def test_cloudmenuid(self) -> None:
        """Test cloudmenuid parsing."""
        body = self._make_body()
        body[2] = 0x01
        body[3] = 0x02
        body[4] = 0x03
        msg = MessageBFBody(body=body)
        assert msg.cloudmenuid == 0x010203

    def test_cloudmenuid_zero(self) -> None:
        """Test cloudmenuid = 0 when all bytes are 0."""
        body = self._make_body()
        msg = MessageBFBody(body=body)
        assert msg.cloudmenuid == 0

    @pytest.mark.parametrize(
        ("byte_value", "totalstep", "stepnum"),
        [
            pytest.param(0x32, 3, 2, id="mid_values"),
            pytest.param(0xF0, 15, 0, id="max_totalstep_zero_stepnum"),
        ],
    )
    def test_totalstep_and_stepnum(
        self,
        byte_value: int,
        totalstep: int,
        stepnum: int,
    ) -> None:
        """Test totalstep and stepnum parsing from byte 5."""
        body = self._make_body()
        body[5] = byte_value
        msg = MessageBFBody(body=body)
        assert msg.totalstep == totalstep
        assert msg.stepnum == stepnum

    @pytest.mark.parametrize(
        ("byte_value", "expected"),
        [
            pytest.param(0x0A, True, id="probe_and_turntable_set"),  # bit1+bit3
            pytest.param(0x00, False, id="both_clear"),
        ],
    )
    def test_probe_and_turntable_flags(self, byte_value: int, expected: bool) -> None:
        """Test probe and turntable flags from byte 6."""
        body = self._make_body()
        body[6] = byte_value
        msg = MessageBFBody(body=body)
        assert msg.probe is expected
        assert msg.turntable is expected

    def test_work_mode_parsing(self) -> None:
        """Test work_mode parsing."""
        body = self._make_body()
        body[7] = 0x01
        body[8] = 0x00
        msg = MessageBFBody(body=body)
        assert msg.work_mode == "microwave"

    def test_work_mode_parsing_unknown(self) -> None:
        """Test work_mode parsing with unknown bytes."""
        body = self._make_body()
        body[7] = 0xFF
        body[8] = 0xFF
        msg = MessageBFBody(body=body)
        assert msg.work_mode == "unknown"

    def test_time_settings_default(self) -> None:
        """Test time settings (hour_set/minute_set/second_set) default to 0."""
        body = self._make_body()
        body[9] = 0xFF  # hour_set = 0xFF -> treated as 0
        body[10] = 0xFF
        body[11] = 0xFF
        msg = MessageBFBody(body=body)
        assert msg.hour_set == 0
        assert msg.minute_set == 0
        assert msg.second_set == 0

    def test_time_settings_with_values(self) -> None:
        """Test time settings with actual values."""
        body = self._make_body()
        body[9] = 2  # hour_set
        body[10] = 30  # minute_set
        body[11] = 15  # second_set
        msg = MessageBFBody(body=body)
        assert msg.hour_set == 2
        assert msg.minute_set == 30
        assert msg.second_set == 15

    @pytest.mark.parametrize(
        ("byte_value", "expected"),
        [
            pytest.param(0x05, "fire_power_5", id="known"),
            pytest.param(0x0B, "unknown", id="out_of_range"),
            pytest.param(0xFF, "unknown", id="unset"),
        ],
    )
    def test_fire_power(self, byte_value: int, expected: str) -> None:
        """Test fire_power parsing for known/out-of-range/unset values."""
        body = self._make_body()
        body[12] = byte_value
        msg = MessageBFBody(body=body)
        assert msg.fire_power == expected

    def test_temperature_above_only(self) -> None:
        """Test temperature parsing when only temperature_above is nonzero."""
        body = self._make_body()
        body[13] = 0x00  # temp_above_high
        body[14] = 200  # temp_above_low = 200
        body[15] = 0x00  # temp_underside_high
        body[16] = 0x00  # temp_underside_low
        msg = MessageBFBody(body=body)
        assert msg.temperature_above == 200
        assert msg.temperature_underside == 0
        assert msg.temperature == 200  # above != 0 -> use above

    def test_temperature_underside_only(self) -> None:
        """Test temperature when only temperature_underside is nonzero."""
        body = self._make_body()
        body[13] = 0x00
        body[14] = 0x00  # above = 0
        body[15] = 0x00
        body[16] = 180  # underside = 180
        msg = MessageBFBody(body=body)
        assert msg.temperature_above == 0
        assert msg.temperature_underside == 180
        assert msg.temperature == 180  # above=0 -> use underside

    def test_temperature_both_zero(self) -> None:
        """Test temperature when both above and underside are 0."""
        body = self._make_body()
        msg = MessageBFBody(body=body)
        assert msg.temperature == 0  # fallback to underside (also 0)

    def test_temperature_16bit(self) -> None:
        """Test temperature parsing with 16-bit value."""
        body = self._make_body()
        body[13] = 0x01  # high byte
        body[14] = 0x00  # low byte -> 256
        msg = MessageBFBody(body=body)
        assert msg.temperature_above == 256
        assert msg.temperature == 256

    def test_probe_temperature(self) -> None:
        """Test probe_temperature parsing."""
        body = self._make_body()
        body[17] = 0x00  # high
        body[18] = 80  # low
        msg = MessageBFBody(body=body)
        assert msg.probe_temperature == 80

    def test_probe_temperature_zero(self) -> None:
        """Test probe_temperature = 0."""
        body = self._make_body()
        msg = MessageBFBody(body=body)
        assert msg.probe_temperature == 0

    def test_steam_quantity(self) -> None:
        """Test steam_quantity parsing."""
        body = self._make_body()
        body[19] = 5
        msg = MessageBFBody(body=body)
        assert msg.steam_quantity == 5

    def test_steam_quantity_unset(self) -> None:
        """Test steam_quantity = 0xFF -> None."""
        body = self._make_body()
        body[19] = 0xFF
        msg = MessageBFBody(body=body)
        assert msg.steam_quantity is None

    @pytest.mark.parametrize(
        ("byte_value", "weight", "people_number"),
        [
            pytest.param(50, 500, 50, id="weight_50"),
            pytest.param(0xFF, None, None, id="unset"),
            pytest.param(4, 40, 4, id="people_number_4"),
        ],
    )
    def test_weight_and_people_number(
        self,
        byte_value: int,
        weight: int | None,
        people_number: int | None,
    ) -> None:
        """Test weight/people_number parsing (same source byte)."""
        body = self._make_body()
        body[20] = byte_value
        msg = MessageBFBody(body=body)
        assert msg.weight == weight
        assert msg.people_number == people_number

    @pytest.mark.parametrize(
        ("hour", "minute", "expected"),
        [
            pytest.param(1, 30, 90, id="1h30m"),
            pytest.param(0, 0, 0, id="zero"),
            pytest.param(2, 0, 120, id="full_hour"),
        ],
    )
    def test_time_remaining(self, hour: int, minute: int, expected: int) -> None:
        """Test time_remaining computed from work_hour/minute, in minutes."""
        body = self._make_body()
        body[22] = hour
        body[23] = minute
        body[24] = 0
        msg = MessageBFBody(body=body)
        assert msg.time_remaining == expected

    def test_current_temperatures_above(self) -> None:
        """Test current_temperature when cur_temperature_above is nonzero."""
        body = self._make_body()
        body[25] = 0x00  # cur_temp_above_high
        body[26] = 180  # cur_temp_above_low
        body[27] = 0x00  # cur_temp_underside_high
        body[28] = 150  # cur_temp_underside_low
        msg = MessageBFBody(body=body)
        assert msg.cur_temperature_above == 180
        assert msg.cur_temperature_underside == 150
        assert msg.current_temperature == 180  # above nonzero -> use above

    def test_current_temperatures_underside(self) -> None:
        """Test current_temperature when cur_temperature_above is 0."""
        body = self._make_body()
        body[25] = 0x00
        body[26] = 0x00  # cur_temp_above = 0
        body[27] = 0x00
        body[28] = 150  # cur_temp_underside = 150
        msg = MessageBFBody(body=body)
        assert msg.current_temperature == 150  # above=0 -> use underside

    def test_cur_probe_temperature(self) -> None:
        """Test cur_probe_temperature parsing."""
        body = self._make_body()
        body[29] = 0x00  # high
        body[30] = 75  # low
        msg = MessageBFBody(body=body)
        assert msg.cur_probe_temperature == 75

    def test_power_inferred_from_status(self) -> None:
        """Test power is inferred from status: save_power=False, others=True."""
        body = self._make_body()
        body[31] = WorkStatus.save_power.value
        msg = MessageBFBody(body=body)
        assert msg.power is False
        assert msg.status == "save_power"

        body[31] = WorkStatus.standby.value
        msg = MessageBFBody(body=body)
        assert msg.power is True
        assert msg.status == "standby"

    def test_status_unknown_value(self) -> None:
        """Test status parsing with invalid value returns 'unknown'."""
        body = self._make_body()
        body[31] = 0x00  # not in WorkStatus enum
        msg = MessageBFBody(body=body)
        assert msg.status == "unknown"
        assert msg.power is False  # unknown status cannot be trusted as on

    def test_status_all_valid_values(self) -> None:
        """Test all valid WorkStatus values parse correctly."""
        for name, value in {
            "save_power": 0x01,
            "standby": 0x02,
            "work": 0x03,
            "work_finish": 0x04,
            "order": 0x05,
            "pause": 0x06,
            "pause_c": 0x07,
            "self_inspection": 0x0A,
            "wait_to_start": 0x10,
        }.items():
            body = self._make_body()
            body[31] = value
            msg = MessageBFBody(body=body)
            assert msg.status == name

    def test_status_flags_byte32(self) -> None:
        """Test flags in byte 32 (child_lock, door, tank_ejected, etc)."""
        body = self._make_body()
        body[32] = 0x07  # child_lock + door + tank_ejected
        msg = MessageBFBody(body=body)
        assert msg.child_lock is True
        assert msg.door is True
        assert msg.tank_ejected is True
        assert msg.water_shortage is False
        assert msg.water_change_reminder is False
        assert msg.error_code is False

    @pytest.mark.parametrize(
        ("byte_value", "attr"),
        [
            pytest.param(0x08, "water_shortage", id="water_shortage"),
            pytest.param(0x10, "water_change_reminder", id="water_change_reminder"),
            pytest.param(0x80, "error_code", id="error_code"),
            pytest.param(0x20, "pre_heat", id="pre_heat_in_progress"),
            pytest.param(0x40, "pre_heat", id="pre_heat_end"),
        ],
    )
    def test_byte32_single_bit_flags(self, byte_value: int, attr: str) -> None:
        """Test single-bit byte32 flags, including both pre_heat source bits."""
        body = self._make_body()
        body[32] = byte_value
        msg = MessageBFBody(body=body)
        assert getattr(msg, attr) is True

    def test_byte32_all_flags(self) -> None:
        """Test all flags in byte 32 set simultaneously."""
        body = self._make_body()
        # all bits: child_lock(0x01)+door(0x02)+tank_ejected(0x04)
        # +water_shortage(0x08)+water_change(0x10)+pre_heat(0x20)+error_code(0x80)=0xBF
        body[32] = 0xBF
        msg = MessageBFBody(body=body)
        assert msg.child_lock is True
        assert msg.door is True
        assert msg.tank_ejected is True
        assert msg.water_shortage is True
        assert msg.water_change_reminder is True
        assert msg.error_code is True
        assert msg.pre_heat is True

    def test_status_flags_byte33(self) -> None:
        """Test flags in byte 33 (flip_side, reaction, furnace_light, etc)."""
        body = self._make_body()
        body[33] = 0x07  # flip_side + reaction + furnace_light
        msg = MessageBFBody(body=body)
        assert msg.flip_side is True
        assert msg.reaction is True
        assert msg.furnace_light is True

    def test_byte33_high_temperature_lock(self) -> None:
        """Test high_temperature_lock (bit3=0 means lock ON)."""
        body = self._make_body()
        body[33] = 0x00  # all bits off -> high_temp_lock bit=0 -> lock is ON
        msg = MessageBFBody(body=body)
        assert msg.high_temperature_lock is True  # bit=0 -> True

    def test_byte33_high_temperature_lock_off(self) -> None:
        """Test high_temperature_lock off (bit3=1 means lock OFF)."""
        body = self._make_body()
        body[33] = 0x08  # only high_temp_lock bit set -> lock is OFF
        msg = MessageBFBody(body=body)
        assert msg.high_temperature_lock is False  # bit=1 -> False

    @pytest.mark.parametrize(
        ("byte_value", "attr"),
        [
            pytest.param(0x10, "high_temperature_work", id="high_temperature_work"),
            pytest.param(0x20, "high_temperature", id="high_temperature"),
            pytest.param(0x40, "probe_mode", id="probe_mode"),
        ],
    )
    def test_byte33_single_bit_flags(self, byte_value: int, attr: str) -> None:
        """Test single-bit byte33 flags (high_temp_work/high_temp/probe_mode)."""
        body = self._make_body()
        body[33] = byte_value
        msg = MessageBFBody(body=body)
        assert getattr(msg, attr) is True

    def test_byte33_all_flags(self) -> None:
        """Test all flags in byte 33."""
        body = self._make_body()
        body[33] = 0x7F  # bits 0-6 set
        msg = MessageBFBody(body=body)
        assert msg.flip_side is True
        assert msg.reaction is True
        assert msg.furnace_light is True
        assert msg.high_temperature_lock is False  # bit3=1 -> lock off
        assert msg.high_temperature_work is True
        assert msg.high_temperature is True
        assert msg.probe_mode is True

    @pytest.mark.parametrize(
        ("offset", "attr", "byte_value", "expected"),
        [
            pytest.param(34, "ramadan", 0x20, True, id="ramadan_set"),
            pytest.param(34, "ramadan", 0x00, False, id="ramadan_clear"),
            pytest.param(35, "hot_wind", 0x20, True, id="hot_wind_set"),
            pytest.param(35, "hot_wind", 0x00, False, id="hot_wind_clear"),
        ],
    )
    def test_single_byte_flag(
        self,
        offset: int,
        attr: str,
        byte_value: int,
        expected: bool,
    ) -> None:
        """Test ramadan (byte 34) and hot_wind (byte 35) flag parsing."""
        body = self._make_body()
        body[offset] = byte_value
        msg = MessageBFBody(body=body)
        assert getattr(msg, attr) is expected

    @pytest.mark.parametrize(
        ("major", "minor", "patch", "expected"),
        [
            pytest.param(1, 2, 3, "V1.2.3", id="nonzero"),
            pytest.param(0, 0, 0, "V0.0.0", id="zero"),
        ],
    )
    def test_cbs_version(
        self,
        major: int,
        minor: int,
        patch: int,
        expected: str,
    ) -> None:
        """Test cbs_version string parsing."""
        body = self._make_body(length=60)
        body[47] = major
        body[48] = minor
        body[49] = patch
        msg = MessageBFBody(body=body)
        assert msg.cbs_version == expected

    def test_cbs_version_short_body(self) -> None:
        """Test cbs_version with body too short returns V0.0.0."""
        body = bytearray(10)  # shorter than OFFSET_CBS_VERSION_PATCH=49
        body[0] = 0x01
        msg = MessageBFBody(body=body)
        assert msg.cbs_version == "V0.0.0"

    @pytest.mark.parametrize(
        ("byte_value", "clean_scale", "ota"),
        [
            pytest.param(0xC0, True, True, id="both"),  # bit6+bit7
            pytest.param(0x40, True, False, id="clean_scale_only"),
            pytest.param(0x80, False, True, id="ota_only"),
        ],
    )
    def test_byte56_flags(self, byte_value: int, clean_scale: bool, ota: bool) -> None:
        """Test clean_scale and ota flags from byte 56."""
        body = self._make_body(length=60)
        body[56] = byte_value
        msg = MessageBFBody(body=body)
        assert msg.clean_scale is clean_scale
        assert msg.ota is ota

    @pytest.mark.parametrize(
        ("byte_value", "clean_sink_ponding", "dissipate_heat"),
        [
            pytest.param(0x01, True, False, id="clean_sink_ponding_only"),
            pytest.param(0x02, False, True, id="dissipate_heat_only"),
            pytest.param(0x03, True, True, id="both"),
        ],
    )
    def test_byte58_flags(
        self,
        byte_value: int,
        clean_sink_ponding: bool,
        dissipate_heat: bool,
    ) -> None:
        """Test clean_sink_ponding and dissipate_heat flags from byte 58."""
        body = self._make_body(length=60)
        body[58] = byte_value
        msg = MessageBFBody(body=body)
        assert msg.clean_sink_ponding is clean_sink_ponding
        assert msg.dissipate_heat is dissipate_heat


def _build_message(message_type: MessageType, body: bytearray) -> bytes:
    """Build a full BF response message."""
    header = bytearray(
        [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
    )
    return bytes(header + body + bytearray([0x00]))


class TestMessageBFResponse:
    """Test MessageBFResponse."""

    def test_total_state_response(self) -> None:
        """Test parsing of a totalState (body_type 0x01) response."""
        body = bytearray(60)
        body[0] = 0x01  # body_type
        body[31] = WorkStatus.standby.value  # status=standby, power=True
        message = MessageBFResponse(_build_message(MessageType.query, body))
        assert hasattr(message, "body_type")
        assert message.body_type == 0x01
        assert hasattr(message, "status")
        assert message.status == "standby"
        assert hasattr(message, "power")
        assert message.power is True

    def test_response_with_all_attributes(self) -> None:
        """Test response parsing populates all expected attributes."""
        body = bytearray(60)
        body[0] = 0x01  # body_type totalState
        body[31] = WorkStatus.work.value  # status=work
        body[32] = 0xBF  # all byte32 flags
        body[33] = 0x7F  # all byte33 flags
        body[34] = 0x20  # ramadan
        body[35] = 0x20  # hot_wind
        body[56] = 0xC0  # clean_scale + ota
        body[58] = 0x03  # clean_sink_ponding + dissipate_heat
        message = MessageBFResponse(
            _build_message(MessageType.query, body),
        )
        assert message.status == "work"  # type: ignore[attr-defined]
        assert message.power is True  # type: ignore[attr-defined]
        assert message.child_lock is True  # type: ignore[attr-defined]
        assert message.door is True  # type: ignore[attr-defined]
        assert message.tank_ejected is True  # type: ignore[attr-defined]
        assert message.ramadan is True  # type: ignore[attr-defined]
        assert message.hot_wind is True  # type: ignore[attr-defined]
        assert message.clean_scale is True  # type: ignore[attr-defined]
        assert message.ota is True  # type: ignore[attr-defined]
        assert message.clean_sink_ponding is True  # type: ignore[attr-defined]
        assert message.dissipate_heat is True  # type: ignore[attr-defined]

    def test_response_save_power(self) -> None:
        """Test response with save_power status -> power=False."""
        body = bytearray(60)
        body[0] = 0x01
        body[31] = WorkStatus.save_power.value
        message = MessageBFResponse(
            _build_message(MessageType.set, body),
        )
        assert message.power is False  # type: ignore[attr-defined]

    def test_response_notify_type(self) -> None:
        """Test response with notify1 message type."""
        body = bytearray(60)
        body[0] = 0x01
        body[31] = WorkStatus.standby.value
        message = MessageBFResponse(
            _build_message(MessageType.notify1, body),
        )
        assert message.status == "standby"  # type: ignore[attr-defined]

    def test_response_non_total_state_body_type(self) -> None:
        """Test response with non-0x01 body_type does not parse BF attributes."""
        body = bytearray(10)
        body[0] = 0x02  # not totalState
        message = MessageBFResponse(
            _build_message(MessageType.query, body),
        )
        # Should not have BF-specific attributes
        assert not hasattr(message, "status")
