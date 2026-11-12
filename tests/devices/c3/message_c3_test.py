"""Test c3 message."""

from collections.abc import Callable
from typing import TYPE_CHECKING, Any, cast
from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.c3 import DeviceAttributes as A
from midealocal.devices.c3 import MideaC3Device
from midealocal.devices.c3.message import (
    BASIC_SIZES,
    BasicTag,
    C3DeviceMode,
    C3NativeTelemetryBody,
    C3QuintupleBasicBody,
    C3QuintupleEnergyBody,
    C3SilentLevel,
    MessageC3Base,
    MessageC3Response,
    MessageQuery,
    MessageQuery2F12,
    MessageQuery2010,
    MessageQueryBasic,
    MessageQueryDisinfect,
    MessageQueryECO,
    MessageQueryHMIPara,
    MessageQueryInstall,
    MessageQuerySilence,
    MessageSet,
    MessageSet2010,
    MessageSetDisinfect,
    MessageSetECO,
    MessageSetSilent,
)
from midealocal.message import BodyParser, ListTypes, MessageBody, MessageType

if TYPE_CHECKING:
    from midealocal.base_classes.climate import MideaHVACMode


class TestMessageC3Base:
    """Test C3 Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageC3Base(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestC3MessageQuery:
    """Test C3 message query."""

    def test_query_body(self) -> None:
        """Test query body."""
        msg: MessageQuery = MessageQueryBasic(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0x1])
        assert msg.body == expected_body

        msg = MessageQueryDisinfect(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0x9])
        assert msg.body == expected_body

        msg = MessageQuerySilence(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0x5])
        assert msg.body == expected_body

        msg = MessageQueryECO(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0x7])
        assert msg.body == expected_body

        msg = MessageQueryInstall(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0x8])
        assert msg.body == expected_body

        msg = MessageQueryHMIPara(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0xA])
        assert msg.body == expected_body


class TestC3MessageSet:
    """Test C3 message set."""

    def test_set_body(self) -> None:
        """Test set body."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.zone1_power = True
        msg.zone2_power = True
        msg.dhw_power = True
        msg.mode = C3DeviceMode.COOL
        msg.zone_target_temp = [23.0, 22.0]
        msg.dhw_target_temp = 45
        msg.room_target_temp = 24.0
        msg.zone1_curve = True
        msg.zone2_curve = True
        msg.tbh = True
        msg.fast_dhw = True

        expected_body = bytearray(
            [
                msg.body_type,
                0x1 | 0x2 | 0x4,
                0x2,
                23,
                22,
                45,
                24 * 2,
                0x1 | 0x2 | 0x4 | 0x8,
            ],
        )
        assert msg.body == expected_body


class TestC3MessageSetSilent:
    """Test C3 message set silent."""

    def test_set_silent_body(self) -> None:
        """Test set silent body."""
        msg = MessageSetSilent(protocol_version=ProtocolVersion.V1)
        expected_body_off = bytearray([0x5] + [0x0] * 9)
        expected_body_silent = bytearray([0x5, 0x1] + [0x0] * 8)
        expected_body_super_silent = bytearray([0x5, 0x3] + [0x0] * 8)
        assert msg.body == expected_body_off
        msg.silent_mode = True
        assert msg.body == expected_body_off  # mode true and level unset

        msg.silent_level = C3SilentLevel.SILENT
        assert msg.body == expected_body_silent
        msg.silent_mode = False
        assert msg.body == expected_body_off  # mode false and level silent

        msg.silent_level = C3SilentLevel.SUPER_SILENT
        assert msg.body == expected_body_off  # mode false and level super silent
        msg.silent_mode = True
        assert msg.body == expected_body_super_silent


class TestC3MessageSetECO:
    """Test C3 message set ECO."""

    def test_set_eco_body(self) -> None:
        """Test set ECO body."""
        msg = MessageSetECO(protocol_version=ProtocolVersion.V1)
        expected_body_off = bytearray([0x7] + [0x0] * 6)
        expected_body_eco = bytearray([0x7, 0x1] + [0x0] * 5)

        assert msg.body == expected_body_off
        msg.eco_mode = True
        assert msg.body == expected_body_eco


class TestC3MessageSetDisinfect:
    """Test C3 message set disinfect."""

    def test_set_disinfect_body(self) -> None:
        """Test set disinfect body."""
        msg = MessageSetDisinfect(protocol_version=ProtocolVersion.V1)
        expected_body_off = bytearray([0x9] + [0x0] * 4)
        expected_body_on = bytearray([0x9, 0x1] + [0x0] * 3)

        assert msg.body == expected_body_off
        msg.disinfect = True
        assert msg.body == expected_body_on


class TestMessageC3Response:
    """Test Message C3 Response."""

    @pytest.fixture(autouse=True)
    def _setup_header(self) -> None:
        """Do setup header."""
        self.header = bytearray(
            [
                0xAA,
                0x00,
                0xC3,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x01,
                0x00,  # message type
            ],
        )

    def test_message_generic_response(self) -> None:
        """Test message generic response."""
        body = bytearray(
            [
                ListTypes.X01,
                0x01
                | 0x04
                | 0x08
                | 0x20,  # BYTE 1: zone_power1 + dhw_power + zone1_curve + tbh
                0x30,  # BYTE 2: temp_type [True, True]
                0x2 | 0x8,  # BYTE 3: silent on, eco on
                0x3,  # BYTE 4: Mode HEAT
                0x2,  # BYTE 5: Mode Auto COOL
                21,  # BYTE 6: Zone1 Target Temp
                22,  # BYTE 7: Zone2 Target Temp
                42,  # BYTE 8: DHW Target Temp
                45,  # BYTE 9: Room Target Temp * 2
                30,  # BYTE 10: zone1_heating_temp_max
                20,  # BYTE 11: zone1_heating_temp_min
                25,  # BYTE 12: zone1_cooling_temp_max
                16,  # BYTE 13: zone1_cooling_temp_min
                35,  # BYTE 14: zone2_heating_temp_max
                20,  # BYTE 15: zone2_heating_temp_min
                30,  # BYTE 16: zone2_cooling_temp_max
                18,  # BYTE 17: zone2_cooling_temp_min
                61,  # BYTE 18: room_temp_max / 2
                32,  # BYTE 19: room_temp_min / 2
                50,  # BYTE 20: dhw_temp_max
                34,  # BYTE 21: dhw_temp_min
                44,  # BYTE 22: tank_actual_temperature
                0x0,  # BYTE 23; error_code
                0x0,  # BYTE 24; tbh_control
                0x0,  # CRC
            ],
        )

        for message_type in (
            MessageType.set,
            MessageType.query,
            MessageType.notify1,
            MessageType.notify2,
        ):
            self.header[-1] = message_type
            response = MessageC3Response(bytes(self.header + body))

            assert response.body_type == ListTypes.X01
            assert hasattr(response, "zone1_power")
            assert response.zone1_power is True
            assert hasattr(response, "zone2_power")
            assert response.zone2_power is False
            assert hasattr(response, "dhw_power")
            assert response.dhw_power is True
            assert hasattr(response, "zone1_curve")
            assert response.zone1_curve is True
            assert hasattr(response, "zone2_curve")
            assert response.zone2_curve is False
            assert hasattr(response, "tbh")
            assert response.tbh is True
            assert hasattr(response, "fast_dhw")
            assert response.fast_dhw is False
            assert hasattr(response, "zone_temp_type")
            assert response.zone_temp_type == [True, True]
            assert hasattr(response, "silent_mode")
            assert response.silent_mode is True
            assert hasattr(response, "eco_mode")
            assert response.eco_mode is True
            assert hasattr(response, "mode")
            assert response.mode == C3DeviceMode.HEAT
            assert hasattr(response, "mode_auto")
            assert response.mode_auto == C3DeviceMode.COOL
            assert hasattr(response, "zone_target_temp")
            assert response.zone_target_temp == [21.0, 22.0]
            assert hasattr(response, "dhw_target_temp")
            assert response.dhw_target_temp == 42.0
            assert hasattr(response, "room_target_temp")
            assert response.room_target_temp == 22.5
            assert hasattr(response, "zone_heating_temp_max")
            assert response.zone_heating_temp_max == [30.0, 35.0]
            assert hasattr(response, "zone_heating_temp_min")
            assert response.zone_heating_temp_min == [20.0, 20.0]
            assert hasattr(response, "zone_cooling_temp_max")
            assert response.zone_cooling_temp_max == [25.0, 30.0]
            assert hasattr(response, "zone_cooling_temp_min")
            assert response.zone_cooling_temp_min == [16.0, 18.0]
            assert hasattr(response, "room_temp_max")
            assert response.room_temp_max == 30.5
            assert hasattr(response, "room_temp_min")
            assert response.room_temp_min == 16.0
            assert hasattr(response, "dhw_temp_max")
            assert response.dhw_temp_max == 50
            assert hasattr(response, "dhw_temp_min")
            assert response.dhw_temp_min == 34
            assert hasattr(response, "tank_actual_temperature")
            assert response.tank_actual_temperature == 44
            assert hasattr(response, "error_code")
            assert response.error_code == 0x0

    def test_message_notify1_x04_response(self) -> None:
        """Test message notify1 x04 response."""
        self.header[-1] = MessageType.notify1
        body = bytearray(
            [
                ListTypes.X04,
                0x01 | 0x04,  # BYTE 1: status_dhw + status_heating
                0x32,  # BYTE 2: total_energy_consumption
                0x1A,  # BYTE 3: total_energy_consumption
                0xB3,  # BYTE 4: total_energy_consumption
                0xC2,  # BYTE 5: total_energy_consumption
                21,  # BYTE 6: total_produced_energy
                22,  # BYTE 7: total_produced_energy
                42,  # BYTE 8: total_produced_energy
                45,  # BYTE 9: total_produced_energy
                30,  # BYTE 10: outdoor_temperature is  t4
                40,  # BYTE 12: zone1_temp_set
                50,  # BYTE 13: zone2_temp_set
                45,  # BYTE 14: t5s
                55,  # BYTE 15: tas
                0x0,  # CRC
            ],
        )
        response = MessageC3Response(bytes(self.header + body))
        assert response.body_type == ListTypes.X04
        assert hasattr(response, "status_tbh")
        assert response.status_tbh is False
        assert hasattr(response, "status_dhw")
        assert response.status_dhw is True
        assert hasattr(response, "status_ibh")
        assert response.status_ibh is False
        assert hasattr(response, "status_heating")
        assert response.status_heating is True
        assert hasattr(response, "total_energy_consumption")
        assert response.total_energy_consumption == 840610754
        assert hasattr(response, "total_produced_energy")
        assert response.total_produced_energy == 353774125
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature == 30
        assert hasattr(response, "zone1_temp_set")
        assert response.zone1_temp_set == 40
        assert hasattr(response, "zone2_temp_set")
        assert response.zone2_temp_set == 50
        assert hasattr(response, "t5s")
        assert response.t5s == 45
        assert hasattr(response, "tas")
        assert response.tas == 55

        body[10] = 253
        response = MessageC3Response(bytes(self.header + body))
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature == -3

    def test_message_silence_response(self) -> None:
        """Test message silence response."""
        self.header[-1] = MessageType.query
        body = bytearray(
            [
                ListTypes.X05,
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
        response = MessageC3Response(bytes(self.header + body))
        assert hasattr(response, "silent_mode")
        assert response.silent_mode is False
        assert hasattr(response, "silent_level")
        assert response.silent_level == C3SilentLevel.OFF.name

        body[1] = 0x1
        response = MessageC3Response(bytes(self.header + body))
        assert hasattr(response, "silent_mode")
        assert response.silent_mode is True
        assert hasattr(response, "silent_level")
        assert response.silent_level == C3SilentLevel.SILENT.name

        body[1] = 0x8
        response = MessageC3Response(bytes(self.header + body))
        assert hasattr(response, "silent_mode")
        assert response.silent_mode is False
        assert hasattr(response, "silent_level")
        assert response.silent_level == C3SilentLevel.OFF.name

        body[1] = 0x9
        response = MessageC3Response(bytes(self.header + body))
        assert hasattr(response, "silent_mode")
        assert response.silent_mode is True
        assert hasattr(response, "silent_level")
        assert response.silent_level == C3SilentLevel.SUPER_SILENT.name

    @pytest.mark.parametrize(
        ("body", "eco_function_state", "eco_timer_state", "eco_mode"),
        [
            pytest.param(
                bytearray([ListTypes.X07, 0x03, 0x00]),
                True,
                True,
                True,
                id="eco on, timer on",
            ),
            pytest.param(
                bytearray([ListTypes.X07, 0x00, 0x00]),
                False,
                False,
                False,
                id="eco off, timer off",
            ),
            pytest.param(
                bytearray([ListTypes.X07, 0x01, 0x00]),
                True,
                False,
                True,
                id="eco on, timer off",
            ),
            pytest.param(
                bytearray([ListTypes.X07, 0x00]),
                False,
                False,
                None,
                id="eco missing, timer missing",
            ),
        ],
    )
    def test_message_eco_response(
        self,
        body: bytearray,
        eco_function_state: bool,
        eco_timer_state: bool,
        eco_mode: bool | None,
    ) -> None:
        """Test message ECO response."""
        self.header[-1] = MessageType.query
        response = MessageC3Response(bytes(self.header + body))
        assert response.body_type == ListTypes.X07
        assert hasattr(response, "eco_function_state")
        assert response.eco_function_state is eco_function_state
        assert hasattr(response, "eco_timer_state")
        assert response.eco_timer_state is eco_timer_state
        assert getattr(response, "eco_mode", None) is eco_mode

    def test_message_unknown_body_response(self) -> None:
        """Test a query reply with an unknown body type is not parsed."""
        self.header[-1] = MessageType.query
        body = bytearray([0x99, 0x03, 0x05, 0x00])
        response = MessageC3Response(bytes(self.header + body))
        assert response.body_type == 0x99
        assert not hasattr(response, "disinfect")

    def test_message_disinfect_response(self) -> None:
        """Test message disinfect response."""
        self.header[-1] = MessageType.query
        body = bytearray(
            [
                ListTypes.X09,
                0x03,  # BYTE 1: disinfect + disinfect_run
                5,  # BYTE 2: disinfect_set_weekday
                10,  # BYTE 3: disinfect_start_hour
                30,  # BYTE 4: disinfect_start_minutes
                0x00,  # CRC
            ],
        )
        response = MessageC3Response(bytes(self.header + body))
        assert response.body_type == ListTypes.X09
        assert hasattr(response, "disinfect")
        assert response.disinfect is True
        assert hasattr(response, "disinfect_run")
        assert response.disinfect_run is True
        assert hasattr(response, "disinfect_set_weekday")
        assert response.disinfect_set_weekday == 5
        assert hasattr(response, "disinfect_start_hour")
        assert response.disinfect_start_hour == 10
        assert hasattr(response, "disinfect_start_minutes")
        assert response.disinfect_start_minutes == 30

    def test_message_unitpara_response(self) -> None:
        """Test message unit parameters response."""
        self.header[-1] = MessageType.query
        body = bytearray(88)  # body type + 86 data bytes + CRC
        body[0] = ListTypes.X10
        body[1] = 50  # comp_run_freq
        body[2] = 2  # unit_mode_run
        body[4] = 8  # fan_speed / 10
        body[6] = 9  # fg_capacity_need
        body[8] = 30  # temp_t4
        body[10] = 40  # temp_tw_in
        body[11] = 35  # temp_tw_out
        body[18] = 1  # odu_voltage high byte
        body[19] = 44  # odu_voltage low byte
        body[22] = 5  # odu_model
        body[43] = 2  # pressure_high high byte
        body[70] = 10  # total_electricity0 low byte
        body[83] = 1  # instant_power0 high byte
        body[84] = 244  # instant_power0 low byte
        response = MessageC3Response(bytes(self.header + body))
        assert response.body_type == ListTypes.X10
        assert hasattr(response, "comp_run_freq")
        assert response.comp_run_freq == 50
        assert hasattr(response, "unit_mode_run")
        assert response.unit_mode_run == 2
        assert hasattr(response, "fan_speed")
        assert response.fan_speed == 80
        assert hasattr(response, "fg_capacity_need")
        assert response.fg_capacity_need == 9
        assert hasattr(response, "temp_t4")
        assert response.temp_t4 == 30
        assert hasattr(response, "temp_tw_in")
        assert response.temp_tw_in == 40
        assert hasattr(response, "temp_tw_out")
        assert response.temp_tw_out == 35
        assert hasattr(response, "odu_voltage")
        assert response.odu_voltage == 300
        assert hasattr(response, "odu_model")
        assert response.odu_model == 5
        assert hasattr(response, "pressure_high")
        assert response.pressure_high == 512
        assert hasattr(response, "total_electricity0")
        assert response.total_electricity0 == 10
        assert hasattr(response, "instant_power0")
        assert response.instant_power0 == 500


QUERY_REPLY = bytes.fromhex(
    "aa7cc300000000000003002010ff1cffff00ffff01ff0103014a7fff00f001e000ff"
    "00000000010101000000000001000000020202022600fa00fa0032022600fa00fa0032"
    "012c00aa025800c801b100010102ff010130000000002f000000000000000000000000"
    "000001005a0000ffff001a0a1f0022ffffffff006b",
)


def device() -> MideaC3Device:
    """Create an offline controller with no real credentials or connection."""
    return MideaC3Device(
        name="Test",
        device_id=1,
        ip_address="192.0.2.1",
        port=6444,
        token="AA",
        key="BB",
        device_protocol=ProtocolVersion.V1,
        model="17100007",
        subtype=195,
    )


def frame(body: bytes, kind: MessageType = MessageType.set) -> bytes:
    """Wrap a synthetic acknowledgement without making a network connection."""
    header = bytes((0xAA, 10 + len(body), 0xC3, 0, 0, 0, 0, 0, 0, kind))
    return header + body + bytes((-sum((header + body)[1:]) & 0xFF,))


def full_status(changes: dict[int, bytes]) -> bytes:
    """Change specific vendor tags in an otherwise valid sequential reply."""
    body = bytearray(QUERY_REPLY[10:-1])
    for tag, value in changes.items():
        assert len(value) == BASIC_SIZES[tag]
        start = 10 + sum(BASIC_SIZES[:tag])
        body[start : start + len(value)] = value
    return frame(bytes(body), MessageType.query)


ENERGY_REPLY = bytes.fromhex(
    "aa9bc300000000000003002f12ff1cffff00ffff02ffffffff0258020b006b00"
    "000230000364c000030ffc0002ed380000ad0c00008e30000001f60000000000"
    "0000000000000000000000000054c400003e8000001edc00000113000002bc00"
    "0001f40000012c000000e90000157c00001068000007d000000113000054c400"
    "003e8000001edc00000113000054c400003e8000001edc0000011312",
)


EXPECTED = {
    "instant_power0": 1070,
    "instant_renew_power0": 5230,
    "current_unit_capacity": 6,
    "total_energy_consumption": 443,
    "total_produced_energy": 2224,
}


class TestC3Native17100007:
    """Native model controls, telemetry and captured protocol regressions."""

    def test_basic_query_matches_vendor_lua(self) -> None:
        """The tested UART query must remain byte-for-byte vendor compatible."""
        assert (
            MessageQuery2010().serialize().hex()
            == "aa14c300000000000003002010ffffffff00fffffc"
        )

    @pytest.mark.parametrize(
        ("values", "expected"),
        [
            (
                {BasicTag.DHW_TEMPERATURE: 48},
                "aa19c300000000000002002010ffffffff01ffff00070201e00d",
            ),
            (
                {BasicTag.DHW_TEMPERATURE: 48.5},
                "aa19c300000000000002002010ffffffff01ffff00070201e508",
            ),
            (
                {BasicTag.DHW_POWER: True},
                "aa18c300000000000002002010ffffffff01ffff00020101f4",
            ),
            (
                {BasicTag.DHW_POWER: False},
                "aa18c300000000000002002010ffffffff01ffff00020100f5",
            ),
            (
                {BasicTag.ZONE1_TEMPERATURE: 33},
                "aa19c300000000000002002010ffffffff01ffff000402014aa6",
            ),
            (
                {BasicTag.ZONE1_POWER: False},
                "aa18c300000000000002002010ffffffff01ffff00000100f7",
            ),
        ],
    )
    def test_set_matches_vendor_lua(
        self,
        values: dict[BasicTag, bool | float | int],
        expected: str,
    ) -> None:
        """Literal packets were generated independently by the recovered vendor Lua."""
        assert MessageSet2010(values).serialize().hex() == expected

    @pytest.mark.parametrize("value", [-1, float("nan"), float("inf"), 3276.7, 3276.69])
    def test_invalid_temperature(self, value: float) -> None:
        """Reject values that cannot represent a valid target."""
        with pytest.raises(ValueError, match="temperature"):
            MessageSet2010({BasicTag.DHW_TEMPERATURE: value})

    @pytest.mark.parametrize(
        "values",
        [{}, {99: True}, {BasicTag.DHW_POWER: "false"}, {BasicTag.MODE: 99}],
    )
    def test_invalid_controls(self, values: dict[Any, Any]) -> None:
        """Never silently coerce invalid controls into dangerous defaults."""
        with pytest.raises(ValueError, match=r"."):
            MessageSet2010(values)

    def test_real_query_reply(self) -> None:
        """A synchronous query now exposes the actual controller state."""
        response = MessageC3Response(QUERY_REPLY, model="17100007")
        assert response.zone1_power is True
        assert response.zone2_power is None  # ff means invalid, not false.
        assert response.dhw_power is True
        assert response.mode == 3
        assert response.dhw_target_temp == 48
        assert response.room_target_temp == 24
        assert response.tank_actual_temperature == 43.3
        assert response.outdoor_temperature == 9
        assert response.dhw_temp_min == 20
        assert response.dhw_temp_max == 60
        assert response.quintuple_arrays["zone_target_temp"] == {0: 33}

    def test_device_query_and_targets(self) -> None:
        """Translate configured zone targets and limits into HA attributes."""
        d = device()
        assert len(d.build_query()) == 3
        status = d.process_message(QUERY_REPLY)
        assert status[A.target_temperature] == [33, None]
        assert status[A.temperature_min][0] == 25
        assert status[A.temperature_max][0] == 55
        assert d.attributes[A.zone1_water_temp_mode] is True
        assert d.attributes[A.zone1_room_temp_mode] is False
        assert d._quintuple_ready is True

    def test_controls_wait_for_status(self) -> None:
        """Wait for status before selecting a temperature control field."""
        d = device()
        with pytest.raises(ValueError, match="first 0x2010"):
            d.set_attribute(A.dhw_power, True)
        with pytest.raises(ValueError, match="first 0x2010"):
            d.set_target_temperature(33, None, 0)

    @pytest.mark.parametrize(
        ("attr", "tag", "value"),
        [
            (A.zone1_power, BasicTag.ZONE1_POWER, False),
            (A.zone2_power, BasicTag.ZONE2_POWER, False),
            (A.dhw_power, BasicTag.DHW_POWER, True),
            (A.zone1_curve, BasicTag.ZONE1_CURVE, True),
            (A.zone2_curve, BasicTag.ZONE2_CURVE, False),
            (A.fast_dhw, BasicTag.FAST_DHW, True),
            (A.tbh, BasicTag.TANK_BOOSTER, False),
            (A.dhw_target_temp, BasicTag.DHW_TEMPERATURE, 48.5),
        ],
    )
    def test_attribute_routing(
        self, attr: A, tag: BasicTag, value: bool | float
    ) -> None:
        """Every supported attribute writes only its own TLV."""
        d = device()
        d.process_message(QUERY_REPLY)
        d._attributes[A.double_zone] = True
        with patch.object(d, "build_send") as send:
            d.set_attribute(attr, value)
        assert (
            send.call_args.args[0].serialize()
            == MessageSet2010({tag: value}).serialize()
        )

    def test_temperature_and_mode_routing(self) -> None:
        """Preserve half degrees and map HA auto (1) to vendor auto (5)."""
        d = device()
        d.process_message(QUERY_REPLY)
        d._attributes[A.double_zone] = True
        with patch.object(d, "build_send") as send:
            d.set_target_temperature(33.5, None, 0)
            assert (
                send.call_args.args[0].serialize()
                == MessageSet2010({BasicTag.ZONE1_TEMPERATURE: 33.5}).serialize()
            )
            d._set_mode(0, 1)
            assert (
                send.call_args.args[0].serialize()
                == MessageSet2010(
                    {BasicTag.ZONE1_POWER: True, BasicTag.MODE: 5},
                ).serialize()
            )
            d._set_mode(0, 0)
            assert (
                send.call_args.args[0].serialize()
                == MessageSet2010(
                    {BasicTag.ZONE1_POWER: False},
                ).serialize()
            )
            d.set_target_temperature(34, cast("MideaHVACMode", 3), 1)
            assert (
                send.call_args.args[0].serialize()
                == MessageSet2010(
                    {
                        BasicTag.ZONE2_TEMPERATURE: 34,
                        BasicTag.ZONE2_POWER: True,
                        BasicTag.MODE: 3,
                    },
                ).serialize()
            )
            d.set_target_temperature(34, cast("MideaHVACMode", 0), 1)
            assert (
                send.call_args.args[0].serialize()
                == MessageSet2010(
                    {BasicTag.ZONE2_TEMPERATURE: 34, BasicTag.ZONE2_POWER: False},
                ).serialize()
            )

    def test_sparse_ack_preserves_other_zone_and_refreshes_target(self) -> None:
        """A one-field reply must not reset other zones or power flags."""
        d = device()
        d.process_message(QUERY_REPLY)
        ack = frame(bytes.fromhex("002010ffffffff01ffff000402014f"))
        state = d.process_message(ack)
        assert state[A.target_temperature] == [33.5, None]
        assert d.attributes[A.dhw_target_temp] == 48
        assert d.attributes[A.dhw_power] is True

    def test_room_mode_and_cooling_limits(self) -> None:
        """Apply correct limits for cooling, auto and room-controlled zones."""
        d = device()
        d.process_message(QUERY_REPLY)
        d.process_message(frame(bytes.fromhex("002010ffffffff01ffff00030102")))
        assert d.attributes[A.temperature_max][0] == 25
        d.process_message(frame(bytes.fromhex("002010ffffffff01ffff00120101")))
        assert d.attributes[A.temperature_min][0] == 17
        assert d.attributes[A.temperature_max][0] == 30
        with patch.object(d, "build_send") as send:
            d.set_target_temperature(22.5, cast("MideaHVACMode", 1), 0)
        assert (
            send.call_args.args[0].serialize()
            == MessageSet2010(
                {
                    BasicTag.ZONE1_TEMPERATURE: 22.5,
                    BasicTag.ROOM_TEMPERATURE: 22.5,
                    BasicTag.ZONE1_POWER: True,
                    BasicTag.MODE: 5,
                },
            ).serialize()
        )

    @pytest.mark.parametrize(
        "body",
        [
            b"",
            bytes(9),
            bytes.fromhex("002010ffffffff02ffff"),
            bytes.fromhex("002010ffffffff01ffff00"),
            bytes.fromhex("002010ffffffff01ffff00070201"),
            bytes.fromhex("002010ffffffff01ffff00070101"),
        ],
    )
    def test_malformed_bodies(self, body: bytes) -> None:
        """Malformed envelopes and TLVs cannot publish partial controls."""
        response = C3QuintupleBasicBody(bytearray(body))
        assert response.quintuple_basic is False
        assert not hasattr(response, "dhw_target_temp")

    def test_unknown_tlv_and_invalid_temperature(self) -> None:
        """Skip unknown tags and unavailable probes without inventing values."""
        body = bytes.fromhex("002010ffffffff01ffff123401010007027fff000601ff")
        assert not C3QuintupleBasicBody(bytearray(body)).quintuple_basic
        body = bytes.fromhex("002010ffffffff01ffff123401010007027fff")
        response = C3QuintupleBasicBody(bytearray(body))
        assert response.quintuple_basic
        assert not hasattr(response, "dhw_target_temp")

    def test_invalid_measured_temperatures_clear_stale_readings(self) -> None:
        """Unavailable probes publish None while invalid targets remain unchanged."""
        d = device()
        d.process_message(QUERY_REPLY)
        assert d.attributes[A.tank_actual_temperature] == 43.3
        assert d.attributes[A.outdoor_temperature] == 9
        status = d.process_message(
            frame(
                bytes.fromhex(
                    "002010ffffffff01ffff0029027fff0034027fff0007027fff",
                ),
            ),
        )
        assert status[A.tank_actual_temperature] is None
        assert status[A.outdoor_temperature] is None
        assert d.attributes[A.dhw_target_temp] == 48

    @pytest.mark.parametrize(
        ("raw", "code", "description"),
        [(0, 0, "No error"), (7, 7, "Unknown code (raw=7)"), (0xFF, None, None)],
    )
    def test_quintuple_error_code_description(
        self,
        raw: int,
        code: int | None,
        description: str | None,
    ) -> None:
        """Native error codes update both the numeric and human-readable state."""
        response = C3QuintupleBasicBody(
            bytearray.fromhex(f"002010ffffffff01ffff002a01{raw:02x}"),
        )
        assert response.error_code == code
        assert response.error_code_description == description

    def test_signed_temperature(self) -> None:
        """The Lua's Temp type is signed two's-complement tenths."""
        body = bytes.fromhex("002010ffffffff01ffff003402ffce")
        assert C3QuintupleBasicBody(bytearray(body)).outdoor_temperature == -5

    @pytest.mark.parametrize(
        "operation",
        [
            lambda d: d.set_attribute("not_a_control", True),
            lambda d: d.set_attribute(A.dhw_power, "false"),
            lambda d: d.set_attribute(A.dhw_target_temp, 90),
            lambda d: d.set_target_temperature(80, None, 0),
            lambda d: d.set_target_temperature(30, None, 2),
            lambda d: d.set_target_temperature(30, cast("MideaHVACMode", 8), 0),
            lambda d: d._set_mode(2, 3),
            lambda d: d._set_mode(0, 8),
            lambda d: d._set_mode(1, 3),
            lambda d: d.set_target_temperature(34, None, 1),
            lambda d: d.set_attribute(A.zone2_power, True),
        ],
    )
    def test_rejected_controls_never_send(
        self,
        operation: Callable[[MideaC3Device], None],
    ) -> None:
        """Unsupported operations must never use the legacy whole-state command."""
        d = device()
        d.process_message(QUERY_REPLY)
        with (
            patch.object(d, "build_send") as send,
            pytest.raises(ValueError, match=r"."),
        ):
            operation(d)
        send.assert_not_called()

    def test_schema_reaches_outdoor_field(self) -> None:
        """Guard offsets across the ASCII fields before tag 52."""
        assert 10 + sum(BASIC_SIZES[:52]) == 97

    def test_unknown_reply_preserves_ready_state(self) -> None:
        """Unrelated replies do not clear known targets or readiness."""
        d = device()
        d.process_message(QUERY_REPLY)
        assert d.process_message(frame(bytes.fromhex("00ffff"))) == {}
        assert d.attributes[A.target_temperature][0] == 33

    def test_selectors_alone_cannot_enable_controls(self) -> None:
        """Mode/type TLVs must not authorize constructor temperature defaults."""
        d = device()
        d.process_message(frame(bytes.fromhex("002010ffffffff01ffff0003010300120100")))
        assert not d._quintuple_ready
        assert d.attributes[A.temperature_min][0] is None
        with (
            patch.object(d, "build_send") as send,
            pytest.raises(ValueError, match="first 0x2010"),
        ):
            d.set_target_temperature(33, None, 0)
        send.assert_not_called()

    @pytest.mark.parametrize(
        ("mode", "water_type", "limit_tag"),
        [
            (3, 0, 29),
            (3, 0, 30),
            (2, 0, 31),
            (2, 0, 32),
            (5, 0, 31),
            (3, 1, 37),
            (3, 1, 38),
        ],
    )
    def test_full_reply_clears_selected_limits(
        self,
        mode: int,
        water_type: int,
        limit_tag: int,
    ) -> None:
        """An unavailable active limit revokes readiness and clears derived bounds."""
        d = device()
        d.process_message(QUERY_REPLY)
        assert bool(d._quintuple_ready)
        d.process_message(
            full_status(
                {
                    3: bytes((mode,)),
                    18: bytes((water_type,)),
                    28: b"\x01",
                    limit_tag: b"\x7f\xff",
                },
            ),
        )
        assert not bool(d._quintuple_ready)
        bounds = [
            d.attributes[A.temperature_min][0],
            d.attributes[A.temperature_max][0],
        ]
        assert None in bounds
        with (
            patch.object(d, "build_send") as send,
            pytest.raises(ValueError, match="first 0x2010"),
        ):
            d.set_target_temperature(25, None, 0)
        send.assert_not_called()
        d.process_message(QUERY_REPLY)
        assert d._quintuple_ready

    def test_sparse_ack_preserves_omitted_limits_and_clears_explicit_sentinel(
        self,
    ) -> None:
        """An omitted zone is preserved; an explicitly unavailable limit is not."""
        d = device()
        d.process_message(QUERY_REPLY)
        second = d.attributes[A.zone_heating_temp_max][1]
        d.process_message(frame(bytes.fromhex("002010ffffffff01ffff001d020226")))
        assert d.attributes[A.zone_heating_temp_max] == [55, second]
        assert d._quintuple_ready
        d.process_message(frame(bytes.fromhex("002010ffffffff01ffff001d027fff")))
        assert d.attributes[A.zone_heating_temp_max] == [None, second]
        assert not d._quintuple_ready

    @pytest.mark.parametrize("tag", [39, 40])
    def test_unknown_dhw_limits_block_temperature_writes(self, tag: int) -> None:
        """DHW cannot reuse default or stale limits when the controller clears them."""
        d = device()
        d.process_message(QUERY_REPLY)
        d.process_message(full_status({tag: b"\x7f\xff"}))
        with (
            patch.object(d, "build_send") as send,
            pytest.raises(ValueError, match="limits"),
        ):
            d.set_attribute(A.dhw_target_temp, 49)
        send.assert_not_called()

    @pytest.mark.parametrize("tag", [3, 18])
    def test_invalid_selectors_clear_readiness(self, tag: int) -> None:
        """Unknown modes and temperature types cannot retain prior write readiness."""
        d = device()
        d.process_message(QUERY_REPLY)
        d.process_message(full_status({tag: b"\xff"}))
        assert not d._quintuple_ready
        assert d.attributes[A.temperature_min][0] is None

    def test_auto_mode_requires_reported_actual_mode(self) -> None:
        """Unavailable auto selection cannot silently select the heating defaults."""
        d = device()
        d.process_message(full_status({3: b"\x05", 28: b"\xff"}))
        assert not d._quintuple_ready

    @pytest.mark.parametrize("tag", [31, 32])
    def test_mode_change_checks_destination_limits(self, tag: int) -> None:
        """A valid current heating range does not authorize unknown cooling limits."""
        d = device()
        d.process_message(full_status({tag: b"\x7f\xff"}))
        assert d._quintuple_ready  # Heating's own limits are still valid.
        with (
            patch.object(d, "build_send") as send,
            pytest.raises(ValueError, match="limits"),
        ):
            d.set_target_temperature(20, cast("MideaHVACMode", 2), 0)
        send.assert_not_called()

    def test_mode_change_rejects_target_outside_destination_range(self) -> None:
        """Reject a 33 C heating target when cooling has a 25 C upper bound."""
        d = device()
        d.process_message(QUERY_REPLY)
        with (
            patch.object(d, "build_send") as send,
            pytest.raises(ValueError, match="limits"),
        ):
            d.set_target_temperature(33, cast("MideaHVACMode", 2), 0)
        send.assert_not_called()

    @pytest.mark.parametrize(
        ("lower", "upper"),
        [(None, 55), (25, None), (55, 25), (float("nan"), 55), (25, float("inf"))],
    )
    def test_unusable_limit_pairs(
        self, lower: float | None, upper: float | None
    ) -> None:
        """Reject missing, inverted and non-finite limits."""
        assert not device()._valid_quintuple_limits(lower, upper)

    def test_both_configured_zones_require_limits(self) -> None:
        """Readiness includes the second zone only when reported as configured."""
        d = device()
        d.process_message(full_status({17: b"\x01", 33: b"\x7f\xff"}))
        assert not d._quintuple_ready

    @pytest.mark.parametrize(
        "invalid_status",
        [
            frame(bytes.fromhex("002010ffffffff01ffff001101ff")),
            full_status({17: b"\xff"}),
        ],
    )
    def test_invalid_double_zone_revokes_zone2_controls(
        self, invalid_status: bytes
    ) -> None:
        """An explicit invalid capability must not retain stale zone-2 authorization."""
        d = device()
        d.process_message(full_status({17: b"\x01"}))
        assert d.attributes[A.double_zone] is True
        d.process_message(invalid_status)
        assert d.attributes[A.double_zone] is None
        with (
            patch.object(d, "build_send") as send,
            pytest.raises(ValueError, match="Zone 2"),
        ):
            d.set_attribute(A.zone2_power, True)
        send.assert_not_called()

    def test_energy_query_matches_vendor_lua(self) -> None:
        """The read-only query exactly matches vendor jsonToData output."""
        assert (
            MessageQuery2F12().serialize().hex()
            == "aa14c300000000000003002f12ffffffff00ffffeb"
        )

    @pytest.mark.parametrize("kind", [MessageType.query, MessageType.notify1])
    def test_real_energy_reply(self, kind: MessageType) -> None:
        """Live reply gives kW heat, watts electricity and kWh totals."""
        packet = bytearray(ENERGY_REPLY)
        packet[9] = kind
        response = MessageC3Response(bytes(packet), model="17100007")
        assert response.quintuple_energy is True
        for name, value in EXPECTED.items():
            assert getattr(response, name) == value
        d = device()
        status = d.process_message(bytes(packet))
        for name, value in EXPECTED.items():
            assert status[name] == value
            assert d.attributes[A(name)] == value
        assert d._quintuple_ready is False  # Energy is not basic control status.

    @pytest.mark.parametrize(
        ("tag", "width", "name", "expected"),
        [
            (2, 2, "current_unit_capacity", 0.35),
            (3, 2, "instant_renew_power0", 350),
            (4, 2, "instant_power0", 350),
            (6, 4, "total_produced_energy", 0.35),
            (9, 4, "total_energy_consumption", 0.35),
        ],
    )
    def test_fractional_energy_precision(
        self,
        tag: int,
        width: int,
        name: str,
        expected: float,
    ) -> None:
        """Raw 35 must yield 0.35, not reciprocal multiplication's float artifact."""
        body = bytearray.fromhex("002f12ffffffff01ffff")
        body.extend(
            tag.to_bytes(2, "big") + bytes((width,)) + (35).to_bytes(width, "big")
        )
        parsed = C3QuintupleEnergyBody(body)
        assert getattr(parsed, name) == expected

    @pytest.mark.parametrize(
        ("model", "kind"),
        [("17100003", MessageType.query), ("17100007", MessageType.set)],
    )
    def test_energy_dispatch_is_restricted(self, model: str, kind: MessageType) -> None:
        """Never reinterpret other models or control acknowledgements as energy."""
        response = MessageC3Response(frame(ENERGY_REPLY[10:-1], kind), model=model)
        assert not hasattr(response, "quintuple_energy")

    @pytest.mark.parametrize(("fill", "expected"), [(0, 0), (255, None)])
    def test_zero_and_unavailable(self, fill: int, expected: int | None) -> None:
        """Invalid counters clear the current state; genuine zeros remain numeric."""
        body = bytearray(ENERGY_REPLY[10:-1])
        body[10:] = bytes([fill]) * (len(body) - 10)
        response = C3QuintupleEnergyBody(body)
        for name in EXPECTED:
            assert getattr(response, name) == expected

    def test_sparse_energy_and_malformed_tlv(self) -> None:
        """Partial updates preserve unrelated counters; malformed TLVs are atomic."""
        d = device()
        d.process_message(ENERGY_REPLY)
        envelope = bytes.fromhex("002f12ffffffff01ffff")
        d.process_message(
            frame(envelope + bytes.fromhex("0004020000"), MessageType.notify1),
        )
        assert d.attributes[A.instant_power0] == 0
        assert d.attributes[A.total_produced_energy] == 2224
        for tail in ["00", "00040200", "00040100", "000402006b00060200"]:
            parsed = C3QuintupleEnergyBody(bytearray(envelope + bytes.fromhex(tail)))
            assert parsed.quintuple_energy is False
            assert not hasattr(parsed, "instant_power0")
        unknown = C3QuintupleEnergyBody(bytearray(envelope + bytes.fromhex("ffff0100")))
        assert unknown.quintuple_energy is False

    @pytest.mark.parametrize("length", [0, 9, 10, 48])
    def test_truncated_energy(self, length: int) -> None:
        """Short sequential blocks must not produce plausible-looking power."""
        parsed = C3QuintupleEnergyBody(bytearray(ENERGY_REPLY[10:-1][:length]))
        assert parsed.quintuple_energy is False
        assert not hasattr(parsed, "instant_power0")

    def test_minimum_energy_and_unknown_format(self) -> None:
        """A complete core block is enough; unsupported encodings are ignored."""
        body = bytearray(ENERGY_REPLY[10:-1][:49])
        assert C3QuintupleEnergyBody(body).instant_power0 == 1070
        body[7] = 2
        assert C3QuintupleEnergyBody(body).quintuple_energy is False

    def test_other_telemetry_cannot_overwrite_energy(self) -> None:
        """Do not mix legacy raw counters/capacity with the authoritative 2F12 table."""
        d = device()
        d.process_message(QUERY_REPLY)
        d.process_message(ENERGY_REPLY)
        body = bytearray.fromhex("002f10ff1cffff00ffff") + bytearray(180)
        body[60:64] = bytes.fromhex("00000051")
        status = d.process_message(frame(bytes(body), MessageType.notify1))
        for name, value in EXPECTED.items():
            assert name not in status
            assert d.attributes[A(name)] == value
        assert status[A.temp_tw_out] == 0.0

    @pytest.mark.parametrize(
        ("raw", "expected"),
        [(215, 21.5), (0x800A, -1.0), (0x7FFF, None), (0xFFFF, None)],
    )
    @pytest.mark.parametrize(
        ("offset", "name"),
        [
            (15, "outdoor_temperature"),
            (19, "temp_tw_in"),
            (21, "temp_tw_out"),
            (27, "temp_t1"),
            (29, "temp_tw2"),
            (37, "temp_ta"),
        ],
    )
    def test_native_telemetry(
        self, raw: int, expected: float | None, offset: int, name: str
    ) -> None:
        """Lua telemetry temperatures preserve tenths and clear unavailable sensors."""
        d = device()
        body = bytearray.fromhex("002f10ffffffff00ffff") + bytearray(29)
        body[offset : offset + 2] = raw.to_bytes(2, "big")
        status = d.process_message(frame(bytes(body), MessageType.query))
        assert status[name] == expected
        assert d.attributes[name] == expected

    @pytest.mark.parametrize(
        "body", ["002f10", "002f10ffffffff01ffff", "002f10ffffffff00ffff00"]
    )
    def test_partial_native_telemetry(self, body: str) -> None:
        """Unsupported/truncated telemetry must not fabricate temperature values."""
        d = device()
        assert d.process_message(frame(bytes.fromhex(body), MessageType.query)) == {}

    def test_native_telemetry_query(self) -> None:
        """The compact query uses the vendor envelope."""
        assert device().build_query()[2].body == bytes.fromhex("002f10ffffffff00ffff")

    def test_native_unported_optional_controls_are_not_advertised(self) -> None:
        """Core only creates generic entities for attributes the library exposes."""
        d = device()
        assert "silent_level" not in d.attributes
        assert "disinfect" not in d.attributes
        assert "eco_mode" not in d.attributes
        assert "silent_mode" not in d.attributes


class TestC3BodyParserRegistration:
    """Native response fields use the shared MessageBody parser interface."""

    @pytest.mark.parametrize(
        ("body_type", "body", "required"),
        [
            (C3QuintupleBasicBody, QUERY_REPLY[10:-1], "tank_actual_temperature"),
            (
                C3QuintupleBasicBody,
                bytes.fromhex("002010ffffffff01ffff00070201e5"),
                "dhw_target_temp",
            ),
            (C3QuintupleEnergyBody, ENERGY_REPLY[10:-1], "instant_power0"),
            (
                C3QuintupleEnergyBody,
                bytes.fromhex("002f12ffffffff01ffff00090400000023"),
                "total_energy_consumption",
            ),
            (
                C3NativeTelemetryBody,
                bytes.fromhex("002f10ffffffff00ffff") + bytes(29),
                "temp_t1",
            ),
        ],
    )
    def test_fields_are_registered(
        self,
        body_type: type[MessageBody],
        body: bytes,
        required: str,
    ) -> None:
        """The shared parser list populates native fields without replacing raw data."""
        response = body_type(bytearray(body))
        assert response.data == body
        assert response.parser_list
        assert all(isinstance(parser, BodyParser) for parser in response.parser_list)
        assert required in [parser.name for parser in response.parser_list]
        assert hasattr(response, required)
