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
        # body_type 0x01 prepended by framework, content is [0x01]
        assert query.body == bytearray([ListTypes.X01, 0x01])


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
        for name in {
            "microwave": (0x01, 0x00),
            "eco": (0xA2, 0x00),
            "scale_clean": (0x79, 0x00),
        }:
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

    def test_set_power_not_work_mode(self) -> None:
        """Test setting power routes to notWorkModeControl (body_type 0x02)."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.power = True
        body = msg.body
        assert body[0] == ListTypes.X02
        # status_byte (power=True -> 0x11) is body[1]
        assert body[1] == 0x11

    def test_set_power_off(self) -> None:
        """Test setting power=False routes to notWorkModeControl."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.power = False
        body = msg.body
        assert body[0] == ListTypes.X02
        assert body[1] == 0x01  # BYTE_POWER_OFF

    def test_set_child_lock(self) -> None:
        """Test setting child_lock routes to notWorkModeControl."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.child_lock = True
        body = msg.body
        assert body[0] == ListTypes.X02
        # child_lock is body[2] (after status_byte)
        assert body[2] == 0x01

    def test_set_child_lock_off(self) -> None:
        """Test setting child_lock=False."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.child_lock = False
        body = msg.body
        assert body[0] == ListTypes.X02
        assert body[2] == 0x00  # BYTE_LOCK_OFF

    def test_set_furnace_light(self) -> None:
        """Test setting furnace_light."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.furnace_light = True
        body = msg.body
        assert body[0] == ListTypes.X02
        assert body[3] == 0x01

    def test_set_furnace_light_off(self) -> None:
        """Test setting furnace_light=False."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.furnace_light = False
        body = msg.body
        assert body[3] == 0x00  # BYTE_LIGHT_OFF

    def test_set_door(self) -> None:
        """Test setting door routes to notWorkModeControl."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.door = True
        body = msg.body
        assert body[0] == ListTypes.X02
        assert body[5] == 0x01  # BYTE_DOOR_OPEN

    def test_set_door_close(self) -> None:
        """Test setting door=False."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.door = False
        body = msg.body
        assert body[5] == 0x00  # BYTE_DOOR_CLOSE

    def test_set_hot_wind(self) -> None:
        """Test setting hot_wind routes to notWorkModeControl."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.hot_wind = True
        body = msg.body
        assert body[0] == ListTypes.X02
        assert body[12] == 0x01  # BYTE_HOT_WIND_ON

    def test_set_hot_wind_off(self) -> None:
        """Test setting hot_wind=False."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.hot_wind = False
        body = msg.body
        assert body[12] == 0x00  # BYTE_HOT_WIND_OFF

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

    def test_set_control_no_params_does_not_crash(self) -> None:
        """SetControl with no params set must not raise IndexError.

        Regression: body[2]=param_sum was out of range when body stayed at
        length 2 (no params appended). paramSum lives at body[1].
        """
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        # Force routing into _build_set_control without setting any *_set field.
        msg.turntable = False
        body = msg.body
        assert body[0] == ListTypes.X03
        # body[1]=0x01 header, body[2]=paramSum=0
        assert body[1] == 0x01
        assert body[2] == 0x00

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

    def test_set_control_steam_set(self) -> None:
        """Test setControl with steam_set."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.steam_set = 5
        body = msg.body
        assert body[0] == ListTypes.X03
        # content: [0x01, paramSum=1, 0x00(steam id), 5]
        assert body[1] == 0x01  # header
        assert body[2] == 0x01  # paramSum = 1
        assert body[3] == 0x00  # steam param id
        assert body[4] == 5  # steam value

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

    def test_set_control_fire_power_set(self) -> None:
        """Test setControl with fire_power_set."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.fire_power_set = "fire_power_8"
        body = msg.body
        assert body[0] == ListTypes.X03
        assert body[2] == 0x01  # paramSum = 1
        assert body[3] == 0x02  # fire_power param id
        assert body[4] == 0x08  # fire_power_8 value

    def test_set_control_temp_set(self) -> None:
        """Test setControl with temp_set."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.temp_set = 200  # 200 = 0x00C8
        body = msg.body
        assert body[0] == ListTypes.X03
        assert body[2] == 0x01  # paramSum = 1
        assert body[3] == 0x03  # temp param id
        assert body[4] == 0x00  # reserved
        assert body[5] == 0x00  # temp high
        assert body[6] == 200  # temp low

    def test_set_control_probe_temp_set(self) -> None:
        """Test setControl with probe_temp_set."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.probe_temp_set = 80  # 80 = 0x0050
        body = msg.body
        assert body[0] == ListTypes.X03
        assert body[2] == 0x01  # paramSum = 1
        assert body[3] == 0x04  # probe_temp param id
        assert body[4] == 0x00  # reserved
        assert body[5] == 0x00  # probe_temp high
        assert body[6] == 80  # probe_temp low

    def test_set_control_temp_above_set(self) -> None:
        """Test setControl with temp_above_set."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.temp_above_set = 250  # 250 = 0x00FA
        body = msg.body
        assert body[0] == ListTypes.X03
        assert body[2] == 0x01  # paramSum = 1
        assert body[3] == 0x05  # temp param id
        assert body[4] == 0x00  # sub-field 0
        assert body[5] == 0x00  # reserved
        assert body[6] == 0x00  # sub-id for above (0)
        assert body[7] == 0x00  # temp_high (250 >> 8 = 0)
        assert body[8] == 250  # temp_low

    def test_set_control_temp_underside_set(self) -> None:
        """Test setControl with temp_underside_set."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.temp_underside_set = 180
        body = msg.body
        assert body[0] == ListTypes.X03
        assert body[2] == 0x01  # paramSum = 1
        # 0x05, 0x00, 0x00, 0x01, high, low
        assert body[3] == 0x05  # same param id
        assert body[4] == 0x00
        assert body[5] == 0x00
        assert body[6] == 0x01  # sub-id for underside

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

    def test_bool_to_byte_true(self) -> None:
        """Test _bool_to_byte returns true_val for True."""
        result = MessageSet._bool_to_byte(True, 0x11, 0x01)
        assert result == 0x11

    def test_bool_to_byte_false(self) -> None:
        """Test _bool_to_byte returns false_val for False."""
        result = MessageSet._bool_to_byte(False, 0x11, 0x01)
        assert result == 0x01

    def test_bool_to_byte_none(self) -> None:
        """Test _bool_to_byte returns 0xFF for None."""
        result = MessageSet._bool_to_byte(None, 0x11, 0x01)
        assert result == 0xFF

    def test_fire_power_value_known(self) -> None:
        """Test _fire_power_value for known name."""
        assert MessageSet._fire_power_value("fire_power_5") == 5

    def test_fire_power_value_none(self) -> None:
        """Test _fire_power_value returns 0xFF for None."""
        assert MessageSet._fire_power_value(None) == 0xFF

    def test_fire_power_value_unknown(self) -> None:
        """Test _fire_power_value returns 0xFF for unknown name."""
        assert MessageSet._fire_power_value("unknown_power") == 0xFF

    def test_work_status_value_known(self) -> None:
        """Test _work_status_value for known status."""
        assert MessageSet._work_status_value("standby") == 0x02

    def test_work_status_value_none(self) -> None:
        """Test _work_status_value returns 0xFF for None."""
        assert MessageSet._work_status_value(None) == 0xFF

    def test_work_status_value_unknown(self) -> None:
        """Test _work_status_value returns 0xFF for unknown status."""
        assert MessageSet._work_status_value("invalid_status") == 0xFF

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

    def test_execute_ok(self) -> None:
        """Test execute status = ok (default)."""
        body = self._make_body()
        msg = MessageBFBody(body=body)
        assert msg.execute == "ok"

    def test_execute_status_nonsupport(self) -> None:
        """Test execute status = status_nonsupport."""
        body = self._make_body()
        body[1] = 0x01
        msg = MessageBFBody(body=body)
        assert msg.execute == "status_nonsupport"

    def test_execute_function_nonsupport(self) -> None:
        """Test execute status = function_nonsupport."""
        body = self._make_body()
        body[1] = 0x02
        msg = MessageBFBody(body=body)
        assert msg.execute == "function_nonsupport"

    def test_execute_param_range_error(self) -> None:
        """Test execute status = param_range_error."""
        body = self._make_body()
        body[1] = 0x03
        msg = MessageBFBody(body=body)
        assert msg.execute == "param_range_error"

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

    def test_totalstep_and_stepnum(self) -> None:
        """Test totalstep and stepnum parsing from byte 5."""
        body = self._make_body()
        body[5] = 0x32  # totalstep=3, stepnum=2
        msg = MessageBFBody(body=body)
        assert msg.totalstep == 3
        assert msg.stepnum == 2

    def test_totalstep_max_stepnum_zero(self) -> None:
        """Test totalstep=15 (max) and stepnum=0."""
        body = self._make_body()
        body[5] = 0xF0  # totalstep=15, stepnum=0
        msg = MessageBFBody(body=body)
        assert msg.totalstep == 15
        assert msg.stepnum == 0

    def test_probe_and_turntable_flags(self) -> None:
        """Test probe and turntable flags from byte 6."""
        body = self._make_body()
        body[6] = 0x0A  # probe(bit1)=1, turntable(bit3)=1
        msg = MessageBFBody(body=body)
        assert msg.probe is True
        assert msg.turntable is True

    def test_probe_false_turntable_false(self) -> None:
        """Test probe and turntable both False."""
        body = self._make_body()
        body[6] = 0x00
        msg = MessageBFBody(body=body)
        assert msg.probe is False
        assert msg.turntable is False

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

    def test_fire_power_known(self) -> None:
        """Test fire_power parsing with known value."""
        body = self._make_body()
        body[12] = 0x05  # fire_power_5
        msg = MessageBFBody(body=body)
        assert msg.fire_power == "fire_power_5"

    def test_fire_power_unknown(self) -> None:
        """Test fire_power parsing with unknown value."""
        body = self._make_body()
        body[12] = 0x0B  # invalid fire_power
        msg = MessageBFBody(body=body)
        assert msg.fire_power == "unknown"

    def test_fire_power_ff(self) -> None:
        """Test fire_power with 0xFF (unset)."""
        body = self._make_body()
        body[12] = 0xFF
        msg = MessageBFBody(body=body)
        assert msg.fire_power == "unknown"

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

    def test_weight(self) -> None:
        """Test weight parsing (value * 10)."""
        body = self._make_body()
        body[20] = 50  # weight = 50 * 10 = 500
        msg = MessageBFBody(body=body)
        assert msg.weight == 500
        assert msg.people_number == 50

    def test_weight_unset(self) -> None:
        """Test weight = 0xFF -> None."""
        body = self._make_body()
        body[20] = 0xFF
        msg = MessageBFBody(body=body)
        assert msg.weight is None
        assert msg.people_number is None

    def test_people_number(self) -> None:
        """Test people_number parsing (same byte as weight)."""
        body = self._make_body()
        body[20] = 4  # people_number = 4, weight = 40
        msg = MessageBFBody(body=body)
        assert msg.people_number == 4
        assert msg.weight == 40

    def test_time_remaining(self) -> None:
        """Test time_remaining computed from work_hour/minute/second."""
        body = self._make_body()
        body[22] = 1
        body[23] = 30
        body[24] = 0
        msg = MessageBFBody(body=body)
        assert msg.time_remaining == 5400  # 1h30m

    def test_time_remaining_zero(self) -> None:
        """Test time_remaining = 0 when all work time bytes are 0."""
        body = self._make_body()
        msg = MessageBFBody(body=body)
        assert msg.time_remaining == 0

    def test_time_remaining_full_hour(self) -> None:
        """Test time_remaining with only hours."""
        body = self._make_body()
        body[22] = 2  # 2 hours
        body[23] = 0
        body[24] = 0
        msg = MessageBFBody(body=body)
        assert msg.time_remaining == 7200  # 2h

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
        assert msg.power is True  # not save_power -> True

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

    def test_byte32_water_shortage(self) -> None:
        """Test water_shortage flag in byte 32."""
        body = self._make_body()
        body[32] = 0x08  # water_shortage bit
        msg = MessageBFBody(body=body)
        assert msg.water_shortage is True
        assert msg.child_lock is False
        assert msg.door is False

    def test_byte32_water_change_reminder(self) -> None:
        """Test water_change_reminder flag in byte 32."""
        body = self._make_body()
        body[32] = 0x10  # water_change bit
        msg = MessageBFBody(body=body)
        assert msg.water_change_reminder is True

    def test_byte32_error_code(self) -> None:
        """Test error_code flag in byte 32."""
        body = self._make_body()
        body[32] = 0x80  # error_code bit
        msg = MessageBFBody(body=body)
        assert msg.error_code is True

    def test_byte32_pre_heat(self) -> None:
        """Test pre_heat flag in byte 32."""
        body = self._make_body()
        body[32] = 0x20  # pre_heat bit
        msg = MessageBFBody(body=body)
        assert msg.pre_heat is True

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

    def test_byte33_high_temperature_work(self) -> None:
        """Test high_temperature_work flag."""
        body = self._make_body()
        body[33] = 0x10  # high_temperature_work bit
        msg = MessageBFBody(body=body)
        assert msg.high_temperature_work is True

    def test_byte33_high_temperature(self) -> None:
        """Test high_temperature flag."""
        body = self._make_body()
        body[33] = 0x20  # high_temperature bit
        msg = MessageBFBody(body=body)
        assert msg.high_temperature is True

    def test_byte33_probe_mode(self) -> None:
        """Test probe_mode flag."""
        body = self._make_body()
        body[33] = 0x40  # probe_mode bit
        msg = MessageBFBody(body=body)
        assert msg.probe_mode is True

    def test_byte33_all_flags(self) -> None:
        """Test all flags in byte 33."""
        body = self._make_body()
        body[33] = 0x7F  # all bits except probe_mode
        msg = MessageBFBody(body=body)
        assert msg.flip_side is True
        assert msg.reaction is True
        assert msg.furnace_light is True
        assert msg.high_temperature_lock is False  # bit3=1 -> lock off
        assert msg.high_temperature_work is True
        assert msg.high_temperature is True
        assert msg.probe_mode is True

    def test_byte34_ramadan(self) -> None:
        """Test ramadan flag from byte 34."""
        body = self._make_body()
        body[34] = 0x20  # hot_wind bit used for ramadan
        msg = MessageBFBody(body=body)
        assert msg.ramadan is True

    def test_byte34_ramadan_false(self) -> None:
        """Test ramadan False."""
        body = self._make_body()
        body[34] = 0x00
        msg = MessageBFBody(body=body)
        assert msg.ramadan is False

    def test_byte35_hot_wind(self) -> None:
        """Test hot_wind flag from byte 35."""
        body = self._make_body()
        body[35] = 0x20  # hot_wind bit
        msg = MessageBFBody(body=body)
        assert msg.hot_wind is True

    def test_byte35_hot_wind_false(self) -> None:
        """Test hot_wind False."""
        body = self._make_body()
        body[35] = 0x00
        msg = MessageBFBody(body=body)
        assert msg.hot_wind is False

    def test_cbs_version(self) -> None:
        """Test cbs_version string parsing."""
        body = self._make_body(length=60)
        body[47] = 1
        body[48] = 2
        body[49] = 3
        msg = MessageBFBody(body=body)
        assert msg.cbs_version == "V1.2.3"

    def test_cbs_version_zero(self) -> None:
        """Test cbs_version with all zeros."""
        body = self._make_body(length=60)
        msg = MessageBFBody(body=body)
        assert msg.cbs_version == "V0.0.0"

    def test_cbs_version_short_body(self) -> None:
        """Test cbs_version with body too short returns V0.0.0."""
        body = bytearray(10)  # shorter than OFFSET_CBS_VERSION_PATCH=49
        body[0] = 0x01
        msg = MessageBFBody(body=body)
        assert msg.cbs_version == "V0.0.0"

    def test_clean_scale_and_ota(self) -> None:
        """Test clean_scale and ota flags from byte 56."""
        body = self._make_body(length=60)
        body[56] = 0xC0  # clean_scale(bit6) + ota(bit7)
        msg = MessageBFBody(body=body)
        assert msg.clean_scale is True
        assert msg.ota is True

    def test_clean_scale_only(self) -> None:
        """Test clean_scale only."""
        body = self._make_body(length=60)
        body[56] = 0x40  # clean_scale bit only
        msg = MessageBFBody(body=body)
        assert msg.clean_scale is True
        assert msg.ota is False

    def test_ota_only(self) -> None:
        """Test ota only."""
        body = self._make_body(length=60)
        body[56] = 0x80  # ota bit only
        msg = MessageBFBody(body=body)
        assert msg.clean_scale is False
        assert msg.ota is True

    def test_byte58_clean_sink_ponding(self) -> None:
        """Test clean_sink_ponding flag from byte 58."""
        body = self._make_body(length=60)
        body[58] = 0x01  # clean_sink_ponding bit
        msg = MessageBFBody(body=body)
        assert msg.clean_sink_ponding is True
        assert msg.dissipate_heat is False

    def test_byte58_dissipate_heat(self) -> None:
        """Test dissipate_heat flag from byte 58."""
        body = self._make_body(length=60)
        body[58] = 0x02  # dissipate_heat bit
        msg = MessageBFBody(body=body)
        assert msg.clean_sink_ponding is False
        assert msg.dissipate_heat is True

    def test_byte58_both_flags(self) -> None:
        """Test both flags in byte 58."""
        body = self._make_body(length=60)
        body[58] = 0x03  # both bits
        msg = MessageBFBody(body=body)
        assert msg.clean_sink_ponding is True
        assert msg.dissipate_heat is True


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
        header = bytearray(
            [
                0xAA,
                0x00,
                0xBF,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x01,
                0x03,
            ],
        )
        body = bytearray(60)
        body[0] = 0x01  # body_type
        body[31] = WorkStatus.standby.value  # status=standby, power=True
        message = MessageBFResponse(bytes(header + body))
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
            bytes(_build_message(MessageType.query, body)),
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
            bytes(_build_message(MessageType.set, body)),
        )
        assert message.power is False  # type: ignore[attr-defined]

    def test_response_notify_type(self) -> None:
        """Test response with notify1 message type."""
        body = bytearray(60)
        body[0] = 0x01
        body[31] = WorkStatus.standby.value
        message = MessageBFResponse(
            bytes(_build_message(MessageType.notify1, body)),
        )
        assert message.status == "standby"  # type: ignore[attr-defined]

    def test_response_non_total_state_body_type(self) -> None:
        """Test response with non-0x01 body_type does not parse BF attributes."""
        body = bytearray(10)
        body[0] = 0x02  # not totalState
        message = MessageBFResponse(
            bytes(_build_message(MessageType.query, body)),
        )
        # Should not have BF-specific attributes
        assert not hasattr(message, "status")
