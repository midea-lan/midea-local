"""Test C1 message."""

from midealan.const import DeviceType, ProtocolVersion
from midealan.devices import device_selector
from midealan.devices.c1.message import (
    C1GeneralMessageBody,
    MessagePower,
    MessageQuery,
    MessageSetHeating,
    c1_error_code,
)
from midealan.message import ListTypes


class TestC1GeneralMessageBody:
    """Test C1 general message body."""

    def test_power_heating_temperatures(self) -> None:
        """Parse power, heating (bit2), temperatures, and mode."""
        body = bytearray(32)
        body[2] = 0x05  # power + heating/running
        body[7] = 25
        body[8] = 42
        body[10] = 50
        body[13] = 55
        body[14] = 2  # activity
        msg = C1GeneralMessageBody(body)
        assert msg.power is True
        assert msg.heating is True
        assert msg.fault is False
        assert msg.error_code == "normal"
        assert msg.standby is False
        assert msg.warm_power is False
        assert msg.return_temperature == 25.0
        assert msg.current_temperature == 42.0
        assert msg.heating_target_temperature == 55.0
        assert msg.heating_mode == "activity"

    def test_power_off(self) -> None:
        """Heating off when running bit clear."""
        body = bytearray(16)
        body[2] = 0x00
        body[7] = 18
        body[8] = 20
        body[13] = 30
        body[14] = 3
        msg = C1GeneralMessageBody(body)
        assert msg.power is False
        assert msg.heating is False
        assert msg.fault is False
        assert msg.heating_mode == "sleep"

    def test_fault_state_body_3_bit7(self) -> None:
        """2760001Z fault capture: body[3]=0x80, power on, not heating."""
        body = bytearray.fromhex(
            "010109800088131d1e0026001e1e01050f0000000000"
            "e11e231e00000000000000000000000000000000000000000000000000000000",
        )
        msg = C1GeneralMessageBody(body)
        assert msg.error_code == "E8"
        assert msg.fault is True
        assert msg.power is True
        assert msg.heating is False
        assert msg.return_temperature == 29.0
        assert msg.current_temperature == 30.0
        assert msg.heating_target_temperature == 30.0

    def test_regression_real_notify_payload(self) -> None:
        """2760001Z body: temps, running, user mode at [14]=0x01."""
        body = bytearray.fromhex(
            "010105000088131a1c0026001c2301050f8813700000"
            "e323231e00000000000000000000000000000000000000000000000000000000",
        )
        msg = C1GeneralMessageBody(body)
        assert msg.power is True
        assert msg.heating is True
        assert msg.return_temperature == 26.0  # body[7] 0x1a
        assert msg.current_temperature == 28.0  # body[8] 0x1c
        assert msg.heating_target_temperature == 35.0
        assert msg.heating_mode == "user"
        assert msg.user_mode_target_temperature == 35.0
        assert msg.activity_mode_target_temperature == 35.0
        assert msg.sleep_mode_target_temperature == 30.0

    def test_packed_aux_byte(self) -> None:
        """Lua bodyBytes[33]: pump, 3-way bath, unit type (brightness bits unused)."""
        body = bytearray(32)
        body[22] = 0x0E  # pump, 3-way bath, radiator
        msg = C1GeneralMessageBody(body)
        assert msg.pump_on is True
        assert msg.three_way_mode == "bath"
        assert msg.heating_unit_type == "radiator"

    def test_error_code_priority_f0_over_e8(self) -> None:
        """F0 (byte14 bit0) wins before E8 (byte14 bit7)."""
        body = bytearray(8)
        body[3] = 0x81
        assert c1_error_code(body) == "F0"

    def test_extra_fields_target_30_frame(self) -> None:
        """Vendor fields at target 30 °C (user capture)."""
        body = bytearray.fromhex(
            "010105000088131b1e0026001e1e01050ff1086d0000"
            "e31e231e00000000000000000000000000000000000000000000000000000000",
        )
        msg = C1GeneralMessageBody(body)
        assert msg.user_mode_target_temperature == 30.0
        assert msg.activity_mode_target_temperature == 35.0
        assert msg.sleep_mode_target_temperature == 30.0

    def test_mode_target_setpoints_per_byte_order(self) -> None:
        """Bytes 23-25: user / activity / sleep setpoints."""
        body = bytearray(32)
        body[2] = 0x05
        body[13] = 58
        body[14] = 1
        body[23] = 58
        body[24] = 35
        body[25] = 30
        msg = C1GeneralMessageBody(body)
        assert msg.user_mode_target_temperature == 58.0
        assert msg.activity_mode_target_temperature == 35.0
        assert msg.sleep_mode_target_temperature == 30.0
        assert msg.heating_target_temperature == 58.0

    def test_heating_mode_unknown(self) -> None:
        """Unknown mode byte maps to unknown."""
        body = bytearray(20)
        body[14] = 0xFF
        msg = C1GeneralMessageBody(body)
        assert msg.heating_mode == "unknown"


class TestMessageQuery:
    """Test C1 MessageQuery."""

    def test_query_body(self) -> None:
        """Query body is body_type 0x01 plus payload 0x01."""
        query = MessageQuery(protocol_version=ProtocolVersion.V3)
        assert query.body == bytearray([0x01, 0x01])


class TestMessageSetHeating:
    """Test C1 MessageSetHeating (Lua 0x14 / heating segment)."""

    def test_heating_set_body(self) -> None:
        """Sub 0x04: mode, target, last_time, gap."""
        msg = MessageSetHeating(protocol_version=ProtocolVersion.V3)
        msg.heating_mode = 2
        msg.target_temperature = 55.0
        msg.last_time = 10
        msg.gap_temperature = 3
        assert msg.body == bytearray([0x14, 0x04, 2, 55, 10, 3])


class TestMessagePower:
    """Test C1 MessagePower."""

    def test_power_on_body_type(self) -> None:
        """Power on uses body type X01."""
        mp = MessagePower(protocol_version=ProtocolVersion.V3)
        mp.power = True
        _ = mp.body
        assert mp.body_type == ListTypes.X01

    def test_power_off_body_type(self) -> None:
        """Power off uses body type X02."""
        mp = MessagePower(protocol_version=ProtocolVersion.V3)
        mp.power = False
        _ = mp.body
        assert mp.body_type == ListTypes.X02


class TestDeviceSelector:
    """Test device_selector for C1."""

    def test_device_selector_returns_appliance(self) -> None:
        """device_selector loads MideaAppliance for type 193."""
        dev = device_selector(
            name="c1",
            device_id=1,
            device_type=193,
            ip_address="192.168.1.1",
            port=6444,
            token="00" * 32,
            key="00" * 32,
            device_protocol=ProtocolVersion.V3,
            model="2760001Z",
            subtype=0,
            customize="",
        )
        assert dev is not None
        assert dev.device_type == DeviceType.C1
