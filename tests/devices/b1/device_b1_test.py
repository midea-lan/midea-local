"""Test B1 Device."""

import pytest

from midealan.const import DeviceType, ProtocolVersion
from midealan.devices.b1 import DeviceAttributes, MideaB1Device
from midealan.devices.b1.message import (
    MessageB1Base,
    MessageQuery,
    MessageQueryX01,
)
from midealan.message import ListTypes, MessageType


class TestMideaB1Device:
    """Test Midea B1 Device."""

    device: MideaB1Device

    # Real-device X01 response captured via debug logs from a real electric
    # oven (model 711001CJ, subtype 0) answering ``MessageQueryX01`` while
    # idle with the door closed.
    X01_RESPONSE_711001CJ_HEX = (
        "010000000011000000000000000000ffff00000000000000000020ffff"
        "0000020000000000000000000000000001910300010000000000008000"
        "0021"
    )

    # Real-device X01 response captured from the same oven while running:
    # top+bottom heat (programme 0x53) at a 180C setpoint, 30 minutes left
    # on the timer, cavity at 33C on the way up.
    X01_RESPONSE_711001CJ_WORKING_HEX = (
        "010000000011005301001e000000b4ffff0000000000001e000021ffff"
        "0000030004000000000000000000000ab803000200000000000080"
        "000021"
    )

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea B1 Device setup."""
        self.device = MideaB1Device(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.1",
            port=12345,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model="test_model",
            subtype=1,
            customize="",
        )

    def test_initial_attributes(self) -> None:
        """Test initial attributes."""
        assert self.device.attributes[DeviceAttributes.door] is False
        assert self.device.attributes[DeviceAttributes.status] is None
        assert self.device.attributes[DeviceAttributes.time_remaining] is None
        assert self.device.attributes[DeviceAttributes.current_temperature] is None
        assert self.device.attributes[DeviceAttributes.tank_ejected] is False
        assert self.device.attributes[DeviceAttributes.water_change_reminder] is False
        assert self.device.attributes[DeviceAttributes.water_shortage] is False
        assert self.device.attributes[DeviceAttributes.mode] is None
        assert self.device.attributes[DeviceAttributes.target_temperature] is None

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 2
        assert isinstance(queries[0], MessageQuery)
        assert isinstance(queries[1], MessageQueryX01)

    def test_set_attribute(self) -> None:
        """Test set attribute is a no-op."""
        self.device.set_attribute(DeviceAttributes.door.value, True)
        assert self.device.attributes[DeviceAttributes.door] is False

    def test_query_response(self) -> None:
        """Test query response with valid status."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.B1] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.query])
        body = bytearray(20)
        body[1] = 0x03  # status -> Working
        body[6] = 0x01  # hours
        body[7] = 0x02  # minutes
        body[8] = 0x03  # seconds
        body[16] = 0x1E  # door + tank_ejected + water_shortage + change_reminder
        body[19] = 0x32  # current_temperature
        result = self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.door] is True
        assert self.device.attributes[DeviceAttributes.status] == "Working"
        assert self.device.attributes[DeviceAttributes.time_remaining] == 3723
        assert self.device.attributes[DeviceAttributes.current_temperature] == 50
        assert self.device.attributes[DeviceAttributes.tank_ejected] is True
        assert self.device.attributes[DeviceAttributes.water_change_reminder] is True
        assert self.device.attributes[DeviceAttributes.water_shortage] is True
        assert result[DeviceAttributes.status.value] == "Working"

    def test_notify_response_invalid_status(self) -> None:
        """Test notify1 response with unknown status and invalid times."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.B1] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.notify1])
        body = bytearray(20)
        body[1] = 0x99  # unknown status
        body[6] = 0xFF  # invalid hours
        body[7] = 0xFF  # invalid minutes
        body[8] = 0xFF  # invalid seconds
        self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.door] is False
        assert self.device.attributes[DeviceAttributes.status] is None
        assert self.device.attributes[DeviceAttributes.time_remaining] == 0
        assert self.device.attributes[DeviceAttributes.current_temperature] == 0
        assert self.device.attributes[DeviceAttributes.tank_ejected] is False
        assert self.device.attributes[DeviceAttributes.water_change_reminder] is False
        assert self.device.attributes[DeviceAttributes.water_shortage] is False

    def test_unexpected_response(self) -> None:
        """Test unexpected message type updates nothing."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.B1] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.set])
        body = bytearray(20)
        result = self.device.process_message(bytes(header + body + bytearray(1)))
        assert result == {}

    def test_x01_response_short_body_guard(self) -> None:
        """Test X01 response shorter than X01_MIN_BODY_LENGTH is ignored safely.

        Truncates the real captured X01 payload to 32 bytes (one short of
        the 33-byte minimum enforced by ``B1Message01Body``) to exercise
        the length guard's false branch: it must not raise ``IndexError``
        and must leave door/status/time_remaining/etc. unset, so no
        attributes change from their initial values.
        """
        header = bytearray(
            [0xAA, 0x00, DeviceType.B1] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.query])
        body = bytearray.fromhex(self.X01_RESPONSE_711001CJ_HEX)[:32]
        result = self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.door] is False
        assert self.device.attributes[DeviceAttributes.status] is None
        assert self.device.attributes[DeviceAttributes.time_remaining] is None
        assert self.device.attributes[DeviceAttributes.current_temperature] is None
        assert self.device.attributes[DeviceAttributes.tank_ejected] is False
        assert self.device.attributes[DeviceAttributes.water_shortage] is False
        assert self.device.attributes[DeviceAttributes.water_change_reminder] is False
        assert result == {}

    def test_x01_response_temperature_fallback(self) -> None:
        """Test X01 response falls back to the secondary temperature bytes.

        When the primary temperature reading (``body[25:27]``) is zero,
        ``B1Message01Body`` falls back to the secondary bytes
        (``body[27:29]``) instead. Builds a synthetic minimal-length X01
        body (the 33-byte guard minimum) with a zero primary reading and a
        non-zero secondary reading to exercise that fallback branch.
        """
        header = bytearray(
            [0xAA, 0x00, DeviceType.B1] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.query])
        body = bytearray(33)
        body[0] = 0x01  # X01 body type marker
        body[25] = 0x00  # primary temperature high byte
        body[26] = 0x00  # primary temperature low byte -> reads as 0
        body[27] = 0x00  # fallback temperature high byte
        body[28] = 0x14  # fallback temperature low byte -> 20
        body[31] = 0x02  # status -> Idle
        result = self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.door] is False
        assert self.device.attributes[DeviceAttributes.status] == "Idle"
        assert self.device.attributes[DeviceAttributes.time_remaining] == 0
        assert self.device.attributes[DeviceAttributes.current_temperature] == 20
        assert self.device.attributes[DeviceAttributes.tank_ejected] is False
        assert self.device.attributes[DeviceAttributes.water_shortage] is False
        assert self.device.attributes[DeviceAttributes.water_change_reminder] is False
        assert result[DeviceAttributes.status.value] == "Idle"

    def test_x01_response_real_device_sample(self) -> None:
        """Test X01 response decoding against a real subtype-zero oven capture.

        Confirms the X01 body layout matches B0's ``B0Message01Body``
        offsets (see ``B1Message01Body``) and produces sane values: door
        closed, no tank/water flags, idle status, no time remaining, and a
        plausible ~32C cavity temperature (rather than B0's known-broken
        sentinel value on devices without a temperature sensor).
        """
        header = bytearray(
            [0xAA, 0x00, DeviceType.B1] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.query])
        body = bytearray.fromhex(self.X01_RESPONSE_711001CJ_HEX)
        result = self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.door] is False
        assert self.device.attributes[DeviceAttributes.status] == "Idle"
        assert self.device.attributes[DeviceAttributes.time_remaining] == 0
        assert self.device.attributes[DeviceAttributes.current_temperature] == 32
        assert self.device.attributes[DeviceAttributes.tank_ejected] is False
        assert self.device.attributes[DeviceAttributes.water_shortage] is False
        assert self.device.attributes[DeviceAttributes.water_change_reminder] is False
        assert result[DeviceAttributes.status.value] == "Idle"
        assert self.device.attributes[DeviceAttributes.mode] is None
        assert self.device.attributes[DeviceAttributes.target_temperature] is None

    def test_x01_response_mode_and_target_temperature(self) -> None:
        """Test programme number and setpoint from a running-oven capture.

        The idle capture has both bytes at zero, which is indistinguishable
        from "not implemented", so this uses a second capture taken while
        the oven was actually cooking. Both values were driven one at a
        time on the physical appliance, with a pause after every action:
        see ``B1Message01Body`` for the full sequence.
        """
        header = bytearray(
            [0xAA, 0x00, DeviceType.B1] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.query])
        body = bytearray.fromhex(self.X01_RESPONSE_711001CJ_WORKING_HEX)
        result = self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.mode] == 0x53
        assert self.device.attributes[DeviceAttributes.target_temperature] == 180
        assert self.device.attributes[DeviceAttributes.status] == "Working"
        assert self.device.attributes[DeviceAttributes.time_remaining] == 30 * 60
        assert self.device.attributes[DeviceAttributes.current_temperature] == 33
        assert result[DeviceAttributes.mode.value] == 0x53
        assert result[DeviceAttributes.target_temperature.value] == 180


class TestMessageB1Base:
    """Test B1 Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageB1Base(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X00,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test B1 Message Query."""

    def test_query_body(self) -> None:
        """Test query body."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x00])


class TestMessageQueryX01:
    """Test B1 Message Query X01."""

    def test_query_body(self) -> None:
        """Test query body."""
        msg = MessageQueryX01(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x01])
