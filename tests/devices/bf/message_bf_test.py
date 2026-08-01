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

