"""Test FA Device."""

from unittest.mock import patch

import pytest

from midealan.const import ProtocolVersion
from midealan.devices.fa import DeviceAttributes, MideaFADevice
from midealan.devices.fa.message import (
    V6_DEFAULT_SWING_ANGLE,
    V6_DEFAULT_SWING_ANGLE_CODE,
    V6_INVALID_SWING_ANGLE_CODE,
    MessageCB4Set,
    MessageNewSet,
    MessageQuery,
    MessageSet,
    MessageV6Set,
)
from midealan.message import MessageType


def _build_message(
    protocol_version: int,
    message_type: MessageType,
    body: bytearray,
) -> bytes:
    """Build a full FA response message."""
    header = bytearray(
        [0xAA] + ([0x0] * 7) + [protocol_version] + [message_type],
    )
    return bytes(header + body + bytearray([0x00]))


def _make_device(model: str = "test_model") -> MideaFADevice:
    """Build an FA test device."""
    return MideaFADevice(
        name="Test Device",
        device_id=1,
        ip_address="192.168.1.1",
        port=12345,
        token="AA",
        key="BB",
        device_protocol=ProtocolVersion.V1,
        model=model,
        subtype=1,
        customize="",
    )


class TestMideaFADevice:
    """Test Midea FA Device."""

    device: MideaFADevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea FA Device setup."""
        self.device = _make_device()

    def test_initial_attributes(self) -> None:
        """Test initial attributes."""
        assert self.device.attributes[DeviceAttributes.power] is False
        assert self.device.attributes[DeviceAttributes.child_lock] is False
        assert self.device.attributes[DeviceAttributes.mode] == 0
        assert self.device.attributes[DeviceAttributes.fan_speed] == 0
        assert self.device.attributes[DeviceAttributes.oscillate] is False
        assert self.device.attributes[DeviceAttributes.oscillation_angle] is None
        assert self.device.attributes[DeviceAttributes.tilting_angle] is None
        assert self.device.attributes[DeviceAttributes.oscillation_mode] is None
        assert self.device.attributes[DeviceAttributes.humidify] is False
        assert self.device.attributes[DeviceAttributes.waterions] is False
        assert self.device.attributes[DeviceAttributes.display_on_off] is False

    def test_properties(self) -> None:
        """Test properties."""
        assert self.device.speed_count == 3
        assert self.device.oscillation_angles == [
            "off",
            "30",
            "60",
            "90",
            "120",
            "180",
            "360",
        ]
        assert self.device.tilting_angles == [
            "off",
            "30",
            "60",
            "90",
            "120",
            "180",
            "360",
            "+60",
            "-60",
            "40",
        ]
        assert self.device.oscillation_modes == [
            "off",
            "oscillation",
            "tilting",
            "curve-w",
            "curve-8",
            "reserved",
            "both",
        ]

        assert self.device.preset_modes[0] == "normal"
        assert self.device.preset_modes[-1] == "customize"
        assert len(self.device.preset_modes) == 11

    def test_new_protocol_swing_properties(self) -> None:
        """Test protocol-specific swing option lists match public state values."""
        v5_device = _make_device("560000F3")
        assert v5_device.oscillation_modes == [
            "off",
            "oscillation",
            "tilting",
            "curve-w",
            "curve-8",
            "reserved",
            "both",
            "custom",
        ]
        assert v5_device.oscillation_angles[0] == "off"
        assert v5_device.oscillation_angles[1:4] == ["5", "10", "15"]
        assert v5_device.oscillation_angles[-1] == "1275"
        assert v5_device.tilting_angles == v5_device.oscillation_angles

        v6_device = _make_device("56011CEC")
        assert v6_device.oscillation_modes == [
            "off",
            "oscillation",
            "tilting",
            "both",
            "custom",
        ]
        assert "curve-w" not in v6_device.oscillation_modes
        assert v6_device.oscillation_angles[0] == "off"
        assert v6_device.oscillation_angles[-2:] == ["1265", "default"]
        assert v6_device.tilting_angles == v6_device.oscillation_angles

    def test_mode_capabilities_follow_lua_protocols(self) -> None:
        """Test protocol-specific mode capabilities from Lua tables."""
        assert self.device.preset_modes == [
            "normal",
            "natural",
            "sleep",
            "comfort",
            "mute",
            "baby",
            "feel",
            "storm",
            "strong",
            "soft",
            "customize",
        ]

        v5_device = _make_device("560000F3")
        assert v5_device.preset_modes == [
            *self.device.preset_modes,
            "warm",
            "smart",
            "ionic",
            "ai_smart",
            "double_area",
            "purified_wind",
            "sleeping_wind",
            "purify_only",
            "self_selection",
        ]

        v5_ecology_device = _make_device("56011CB4")
        assert v5_ecology_device.preset_modes == [
            *v5_device.preset_modes,
            "ecology",
        ]

        v6_device = _make_device("56011CEC")
        assert v6_device.preset_modes == [
            "self_selection",
            "sleeping_wind",
            "ecology",
        ]

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    def test_query_response_full_body(self) -> None:
        """Test query response with a full-length body and valid values."""
        body = bytearray(36)
        body[2] = 0x04  # voice open_buzzer
        body[3] = 0x01  # child lock on
        body[4] = 0x03  # power on, mode raw 1 -> Normal
        body[5] = 0x03  # fan speed 3
        body[6] = 66  # target temperature 25
        body[7] = 50  # humidity
        body[8] = 0x33  # oscillate on, angle 3 -> 90, mode 1 -> Oscillation
        body[9] = 0x25  # humidify mode 1, anophelifuge and anion on
        body[15] = 1  # body feeling scan on
        body[16] = 4  # scene sleep
        body[19] = 0x40  # display on
        body[25] = 0x02  # tilting angle 2 -> 60
        body[34] = 0x01  # waterions on
        new_status = self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.child_lock] is True
        assert self.device.attributes[DeviceAttributes.voice] == "open_buzzer"
        assert self.device.attributes[DeviceAttributes.mode] == "normal"
        assert self.device.attributes[DeviceAttributes.fan_speed] == 3
        assert self.device.attributes[DeviceAttributes.target_temperature] == 25.0
        assert self.device.attributes[DeviceAttributes.humidity] == 50
        assert self.device.attributes[DeviceAttributes.oscillate] is True
        assert self.device.attributes[DeviceAttributes.oscillation_angle] == "90"
        assert self.device.attributes[DeviceAttributes.tilting_angle] == "60"
        assert (
            self.device.attributes[DeviceAttributes.oscillation_mode] == "oscillation"
        )
        assert self.device.attributes[DeviceAttributes.humidify] is True
        assert self.device.attributes[DeviceAttributes.humidify_mode] == "1"
        assert self.device.attributes[DeviceAttributes.anophelifuge] is True
        assert self.device.attributes[DeviceAttributes.anion] is True
        assert self.device.attributes[DeviceAttributes.body_feeling_scan] is True
        assert self.device.attributes[DeviceAttributes.scene] == "sleep"
        assert self.device.attributes[DeviceAttributes.waterions] is True
        assert self.device.attributes[DeviceAttributes.display_on_off] is True
        assert new_status[DeviceAttributes.mode.value] == "normal"
        assert new_status[DeviceAttributes.fan_speed.value] == 3

    def test_notify_response_out_of_range_values(self) -> None:
        """Test notify1 response with out-of-range values mapped to None."""
        body = bytearray(36)
        body[4] = 0x19  # power on, legacy mode raw 12 -> out of range
        body[5] = 27  # fan speed out of range -> 0
        body[8] = 0x7F  # oscillate on, angle 7 and mode 7 out of range
        body[25] = 20  # tilting angle out of range
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.notify1, body),
        )
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.mode] is None
        assert self.device.attributes[DeviceAttributes.fan_speed] == 0
        assert self.device.attributes[DeviceAttributes.oscillate] is True
        assert self.device.attributes[DeviceAttributes.oscillation_angle] is None
        assert self.device.attributes[DeviceAttributes.tilting_angle] is None
        assert self.device.attributes[DeviceAttributes.oscillation_mode] is None

    def test_set_response_power_off_short_body(self) -> None:
        """Test set response with a short body and power off."""
        body = bytearray(10)
        body[3] = 0x02  # child lock off
        body[5] = 0x05  # fan speed, ignored as power is off
        new_status = self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.set, body),
        )
        assert self.device.attributes[DeviceAttributes.power] is False
        assert self.device.attributes[DeviceAttributes.child_lock] is False
        assert self.device.attributes[DeviceAttributes.fan_speed] == 0
        assert self.device.attributes[DeviceAttributes.oscillate] is False
        assert self.device.attributes[DeviceAttributes.oscillation_angle] == "off"
        assert self.device.attributes[DeviceAttributes.tilting_angle] == "off"
        assert self.device.attributes[DeviceAttributes.oscillation_mode] == "off"
        assert self.device.attributes[DeviceAttributes.humidify] is False
        assert self.device.attributes[DeviceAttributes.waterions] is False
        assert self.device.attributes[DeviceAttributes.display_on_off] is False
        assert new_status[DeviceAttributes.mode.value] is None

    def test_unexpected_response(self) -> None:
        """Test notify2 response is not parsed."""
        body = bytearray(10)
        new_status = self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.notify2, body),
        )
        assert new_status == {}

    def test_set_attribute_oscillate(self) -> None:
        """Test set attribute oscillate."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.oscillate.value, True)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.oscillate is True
            assert message.oscillation_angle == 3
            assert message.oscillation_mode == 1
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.oscillate.value, False)
            mock_build_send.assert_not_called()

            self.device._attributes[DeviceAttributes.oscillate] = True
            self.device.set_attribute(DeviceAttributes.oscillate.value, False)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.oscillate is False

    def test_protocol_v5_oscillation_commands(self) -> None:
        """Test protocol v5 uses the model-specific set message."""
        self.device.process_message(
            _build_message(
                ProtocolVersion.V1,
                MessageType.query,
                bytearray(52),
            ),
        )
        body = bytearray(52)
        body[23] = 5
        body[51] = 0
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )

        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.oscillate.value, True)

        mock_build_send.assert_called_once()
        message = mock_build_send.call_args[0][0]
        assert isinstance(message, MessageNewSet)
        assert message.oscillate is True
        assert message.oscillation_angle == 1275
        assert message.oscillation_mode == "oscillation"
        assert message._body[22] == 5
        assert message._body[50] == 0xFF

    def test_protocol_v5_oscillation_command_branches(self) -> None:
        """Test v5 off, mode, angle, and generic command branches."""
        body = bytearray(52)
        body[8] = 0x02
        body[23] = 5
        body[51] = 12
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )

        self.device._attributes[DeviceAttributes.oscillate] = True
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.oscillate.value, False)
        message = mock_build_send.call_args[0][0]
        assert message.oscillation_mode == "oscillation"
        assert message._body[7] == 0x02
        mock_build_send.reset_mock()

        self.device._attributes[DeviceAttributes.oscillation_mode] = "oscillation"
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(
                DeviceAttributes.oscillation_mode.value,
                "tilting",
            )
        message = mock_build_send.call_args[0][0]
        assert message.oscillation_mode == "tilting"
        assert message.oscillation_angle is None
        assert message.tilting_angle == 1275
        assert message._body[7] == 0x04
        assert message._body[24] == 0xFF
        mock_build_send.reset_mock()

        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
        assert mock_build_send.call_args[0][0].power is True

        assert (
            self.device.set_new_oscillation(
                DeviceAttributes.power.value,
                True,
            )
            is None
        )
        self.device._attributes[DeviceAttributes.oscillate] = False
        assert (
            self.device.set_new_oscillation(
                DeviceAttributes.oscillate.value,
                False,
            )
            is None
        )
        assert self.device._legacy_angle_code("invalid", {}) is None
        assert (
            self.device.set_new_oscillation(
                DeviceAttributes.oscillation_mode.value,
                "invalid",
            )
            is None
        )
        self.device._attributes[DeviceAttributes.oscillation_angle] = 60
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(
                DeviceAttributes.oscillation_angle.value,
                "off",
            )
        message = mock_build_send.call_args[0][0]
        assert message.oscillation_mode == "oscillation"
        assert message.oscillation_angle == 0

    def test_process_message_skips_missing_attributes(self) -> None:
        """Test status processing tolerates a response without FA fields."""
        response = type(
            "Response",
            (),
            {
                "message_type": MessageType.query,
                "protocol_version": 0,
                "is_new_protocol": False,
            },
        )()
        with patch(
            "midealan.devices.fa.MessageFAResponse",
            return_value=response,
        ):
            assert self.device.process_message(b"") == {}

    def test_protocol_v5_status_fields(self) -> None:
        """Test protocol v5 status fields are exposed and decoded."""
        body = bytearray(52)
        body[1] = 0x12
        body[2] = 4
        body[3] = 0x01
        body[4] = 0x07
        body[5] = 3
        body[6] = 66
        body[7] = 50
        body[9] = 0x35
        body[12] = 55
        body[13] = 66
        body[15] = 1
        body[16] = 4
        body[19] = 0x40
        body[23] = 5
        body[24] = 0x40
        body[34] = 1
        body[51] = 12

        status = self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )

        assert status[DeviceAttributes.voice.value] == "open_buzzer"
        assert status[DeviceAttributes.error_code.value] == 0x12
        assert status[DeviceAttributes.target_temperature.value] == 25.0
        assert status[DeviceAttributes.humidity.value] == 50
        assert status[DeviceAttributes.humidify_mode.value] == "1"
        assert status[DeviceAttributes.scene.value] == "sleep"
        assert status[DeviceAttributes.humidify_feedback.value] == 55
        assert status[DeviceAttributes.temperature_feedback.value] == 25.0
        assert status[DeviceAttributes.oscillation_angle.value] == "60"
        assert status[DeviceAttributes.tilting_angle.value] == "off"

    def test_legacy_long_body_does_not_select_protocol_v5(self) -> None:
        """Test a legacy long body is not detected as protocol v5."""
        body = MessageSet(ProtocolVersion.V1, 0).body
        body[23] = 5
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )

        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.oscillate.value, True)

        mock_build_send.assert_called_once()
        message = mock_build_send.call_args[0][0]
        assert type(message) is MessageSet
        assert self.device.fa_protocol == 0

    def test_protocol_v5_oscillation_mode_off(self) -> None:
        """Test protocol v5 turns swing off for the Off mode."""
        body = bytearray(52)
        body[8] = 0x02
        body[23] = 5
        body[51] = 0xFF
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )

        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(
                DeviceAttributes.oscillation_mode.value,
                "off",
            )

        mock_build_send.assert_called_once()
        message = mock_build_send.call_args[0][0]
        assert isinstance(message, MessageNewSet)
        assert message.oscillate is False
        assert message.oscillation_angle == 0
        assert message.oscillation_mode == "oscillation"
        assert message._body[7] == 0x02
        assert message._body[50] == 0

    def test_protocol_v5_angle_commands_set_direction(self) -> None:
        """Test v5 angle commands include their Lua default direction."""
        body = bytearray(52)
        body[23] = 5
        body[51] = 0
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )

        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(
                DeviceAttributes.oscillation_angle.value,
                "60",
            )
        message = mock_build_send.call_args[0][0]
        assert message.oscillation_mode == "oscillation"
        assert message._body[7] == 0x02
        assert message._body[50] == 12

        mock_build_send.reset_mock()
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(
                DeviceAttributes.tilting_angle.value,
                "60",
            )
        message = mock_build_send.call_args[0][0]
        assert message.oscillation_mode == "tilting"
        assert message._body[7] == 0x04
        assert message._body[24] == 12

    def test_protocol_v6_oscillation_commands(self) -> None:
        """Test protocol v6 uses the 63-byte model-specific set message."""
        body = bytearray(63)
        body[23] = 6
        body[35] = 0x02
        body[51] = 0
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )

        assert self.device.fa_protocol == 6
        assert self.device.attributes[DeviceAttributes.oscillate] is False

        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.oscillate.value, True)

        mock_build_send.assert_called_once()
        message = mock_build_send.call_args[0][0]
        assert isinstance(message, MessageV6Set)
        assert message.oscillate is True
        assert message.oscillation_angle == V6_DEFAULT_SWING_ANGLE
        assert message.oscillation_mode == "oscillation"
        assert len(message.body) == 63
        assert message._body[22] == 6
        assert message._body[34] == 0x02
        assert message._body[50] == V6_DEFAULT_SWING_ANGLE_CODE

    def test_protocol_v6_power_command_uses_v6_body(self) -> None:
        """Test v6 power commands do not fall back to the legacy body."""
        body = bytearray(63)
        body[23] = 6
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )

        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)

        message = mock_build_send.call_args[0][0]
        assert isinstance(message, MessageV6Set)
        assert len(message.body) == 63
        assert message._body[22] == 6

    def test_protocol_short_response_keeps_detected_v6(self) -> None:
        """Test a short response does not reset a detected v6 protocol."""
        body = bytearray(63)
        body[23] = 6
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.set, bytearray(10)),
        )

        assert self.device.fa_protocol == 6
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)

        assert isinstance(mock_build_send.call_args[0][0], MessageV6Set)

    def test_protocol_v6_default_swing_response_stays_enabled(self) -> None:
        """Test the Lua default swing response remains enabled in HA."""
        body = bytearray(63)
        body[23] = 6
        body[51] = 0xFE

        status = self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )

        assert status[DeviceAttributes.oscillate.value] is True
        assert status[DeviceAttributes.oscillation_mode.value] == "oscillation"
        assert status[DeviceAttributes.oscillation_angle.value] == "default"

    def test_protocol_v6_invalid_swing_response_has_no_angle(self) -> None:
        """Test v6 invalid angle sentinels are not exposed as degrees."""
        body = bytearray(63)
        body[23] = 6
        body[25] = V6_INVALID_SWING_ANGLE_CODE
        body[35] = 0x0A
        body[51] = V6_INVALID_SWING_ANGLE_CODE

        status = self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )

        assert status[DeviceAttributes.oscillate.value] is False
        assert status[DeviceAttributes.oscillation_mode.value] == "off"
        assert status[DeviceAttributes.oscillation_angle.value] is None
        assert status[DeviceAttributes.tilting_angle.value] is None

    def test_protocol_v6_diy_swing_with_invalid_angle_is_active(self) -> None:
        """Test v6 DIY swing remains active with its 0xff angle marker."""
        body = bytearray(63)
        body[23] = 6
        body[35] = 0x01
        body[51] = V6_INVALID_SWING_ANGLE_CODE
        body[25] = V6_INVALID_SWING_ANGLE_CODE

        status = self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )

        assert status[DeviceAttributes.oscillate.value] is True
        assert status[DeviceAttributes.oscillation_mode.value] == "custom"
        assert status[DeviceAttributes.oscillation_angle.value] is None
        assert status[DeviceAttributes.tilting_angle.value] is None

    def test_protocol_v6_default_tilting_response_stays_enabled(self) -> None:
        """Test the v6 default tilting angle is decoded as active."""
        body = bytearray(63)
        body[23] = 6
        body[25] = 0xFE

        status = self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )

        assert status[DeviceAttributes.oscillate.value] is True
        assert status[DeviceAttributes.oscillation_mode.value] == "tilting"
        assert status[DeviceAttributes.tilting_angle.value] == "default"

    def test_protocol_v6_normal_angle_response_is_string_option(self) -> None:
        """Test v6 normal angles decode to values present in options."""
        body = bytearray(63)
        body[23] = 6
        body[25] = 12
        body[35] = 0x08

        status = self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )

        assert status[DeviceAttributes.oscillate.value] is True
        assert status[DeviceAttributes.oscillation_mode.value] == "tilting"
        assert status[DeviceAttributes.tilting_angle.value] == "60"
        assert (
            status[DeviceAttributes.tilting_angle.value] in self.device.tilting_angles
        )

    def test_protocol_v6_rejects_unsupported_swing_commands(self) -> None:
        """Test v6 refuses unsupported modes and unencodable angles."""
        body = bytearray(63)
        body[23] = 6
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )

        with patch.object(self.device, "build_send") as mock_build_send:
            for attr, value in (
                (DeviceAttributes.oscillation_mode.value, "curve-w"),
                (DeviceAttributes.oscillation_mode.value, "curve-8"),
                (DeviceAttributes.oscillation_mode.value, "reserved"),
                (DeviceAttributes.oscillation_angle.value, "invalid"),
                (DeviceAttributes.oscillation_angle.value, 1270),
                (DeviceAttributes.tilting_angle.value, 1270),
            ):
                self.device.set_attribute(attr, value)

        mock_build_send.assert_not_called()

    def test_protocol_v5_angle_commands_preserve_both_axes(self) -> None:
        """Test v5 angle commands keep the other active axis in both mode."""
        body = bytearray(52)
        body[23] = 5
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )
        self.device._attributes[DeviceAttributes.oscillation_mode] = "both"
        self.device._attributes[DeviceAttributes.oscillation_angle] = 60
        self.device._attributes[DeviceAttributes.tilting_angle] = 30

        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.oscillation_angle.value, 90)
        message = mock_build_send.call_args[0][0]
        assert message.oscillation_mode == "both"
        assert message.oscillation_angle == 90
        assert message.tilting_angle == 30

        mock_build_send.reset_mock()
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.tilting_angle.value, 90)
        message = mock_build_send.call_args[0][0]
        assert message.oscillation_mode == "both"
        assert message.oscillation_angle == 60
        assert message.tilting_angle == 90

        self.device._attributes[DeviceAttributes.oscillation_angle] = None
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.tilting_angle.value, 120)
        message = mock_build_send.call_args[0][0]
        assert message.oscillation_mode == "tilting"
        assert message.oscillation_angle is None

    def test_protocol_v5_mode_both_includes_active_tilting_axis(self) -> None:
        """Test v5 both mode carries or defaults active vertical angle."""
        body = bytearray(52)
        body[23] = 5
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )
        self.device._attributes[DeviceAttributes.tilting_angle] = 30

        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.oscillation_mode.value, "both")

        message = mock_build_send.call_args[0][0]
        assert message.oscillation_mode == "both"
        assert message.oscillation_angle == 1275
        assert message.tilting_angle == 30
        assert message._body[7] == 0x0C
        assert message._body[24] == 6
        assert message._body[50] == 0xFF

        self.device._attributes[DeviceAttributes.tilting_angle] = None
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.oscillation_mode.value, "both")

        message = mock_build_send.call_args[0][0]
        assert message.oscillation_mode == "both"
        assert message.oscillation_angle == 1275
        assert message.tilting_angle == 1275
        assert message._body[24] == 0xFF
        assert message._body[50] == 0xFF

    def test_protocol_v5_mode_oscillation_omits_vertical_axis(self) -> None:
        """Test v5 horizontal mode does not carry a vertical angle."""
        body = bytearray(52)
        body[23] = 5
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )
        self.device._attributes[DeviceAttributes.tilting_angle] = "60"

        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(
                DeviceAttributes.oscillation_mode.value,
                "oscillation",
            )

        message = mock_build_send.call_args[0][0]
        assert message.oscillation_mode == "oscillation"
        assert message.oscillation_angle == 1275
        assert message.tilting_angle is None
        assert message._body[7] == 0x02
        assert message._body[24] == 0
        assert message._body[50] == 0xFF

    def test_protocol_v6_mode_commands_set_active_axis_angles(self) -> None:
        """Test v6 mode commands write defaults for every active swing axis."""
        body = bytearray(63)
        body[23] = 6
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )

        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(
                DeviceAttributes.oscillation_mode.value,
                "tilting",
            )

        message = mock_build_send.call_args[0][0]
        assert message.oscillation_mode == "tilting"
        assert message.oscillation_angle is None
        assert message.tilting_angle == V6_DEFAULT_SWING_ANGLE
        assert message._body[34] == 0x08
        assert message._body[24] == V6_DEFAULT_SWING_ANGLE_CODE
        assert message._body[50] == V6_INVALID_SWING_ANGLE_CODE

        self.device._attributes[DeviceAttributes.oscillation_angle] = "60"
        self.device._attributes[DeviceAttributes.tilting_angle] = None
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.oscillation_mode.value, "both")

        message = mock_build_send.call_args[0][0]
        assert message.oscillation_mode == "both"
        assert message.oscillation_angle == "60"
        assert message.tilting_angle == V6_DEFAULT_SWING_ANGLE
        assert message._body[34] == 0x0A
        assert message._body[24] == V6_DEFAULT_SWING_ANGLE_CODE
        assert message._body[50] == 12

    def test_protocol_v5_tilting_off_without_horizontal_axis_disables_swing(
        self,
    ) -> None:
        """Test v5 vertical off disables swing when horizontal is inactive."""
        body = bytearray(52)
        body[23] = 5
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )
        self.device._attributes[DeviceAttributes.oscillation_angle] = None
        self.device._attributes[DeviceAttributes.tilting_angle] = 60

        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.tilting_angle.value, "off")

        message = mock_build_send.call_args[0][0]
        assert message.oscillate is False
        assert message.oscillation_mode == "tilting"
        assert message.tilting_angle == 0

    def test_protocol_v6_tilting_off_preserves_default_horizontal_axis(self) -> None:
        """Test vertical off keeps an active v6 default horizontal swing."""
        body = bytearray(63)
        body[23] = 6
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )
        self.device._attributes[DeviceAttributes.oscillation_angle] = "default"
        self.device._attributes[DeviceAttributes.tilting_angle] = 60

        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.tilting_angle.value, "off")

        message = mock_build_send.call_args[0][0]
        assert message.oscillate is True
        assert message.oscillation_mode == "oscillation"
        assert message.oscillation_angle == "default"
        assert message.tilting_angle == 0
        assert message._body[34] == 0x02
        assert message._body[50] == V6_DEFAULT_SWING_ANGLE_CODE
        assert message._body[24] == 0

    def test_set_attribute_oscillation_mode(self) -> None:
        """Test set attribute oscillation mode."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.oscillation_mode.value, "off")
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].oscillate is False
            mock_build_send.reset_mock()

            self.device._attributes[DeviceAttributes.oscillation_angle] = "off"
            self.device.set_attribute(
                DeviceAttributes.oscillation_mode.value,
                "oscillation",
            )
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.oscillation_mode == 1
            assert message.oscillation_angle == 3
            mock_build_send.reset_mock()

            self.device._attributes[DeviceAttributes.oscillation_angle] = "60"
            self.device.set_attribute(
                DeviceAttributes.oscillation_mode.value,
                "oscillation",
            )
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].oscillation_angle == 2
            mock_build_send.reset_mock()

            self.device._attributes[DeviceAttributes.tilting_angle] = "off"
            self.device.set_attribute(
                DeviceAttributes.oscillation_mode.value,
                "tilting",
            )
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.oscillation_mode == 2
            assert message.tilting_angle == 3
            mock_build_send.reset_mock()

            self.device._attributes[DeviceAttributes.tilting_angle] = "30"
            self.device.set_attribute(
                DeviceAttributes.oscillation_mode.value,
                "tilting",
            )
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].tilting_angle == 1
            mock_build_send.reset_mock()

            self.device._attributes[DeviceAttributes.oscillation_angle] = "off"
            self.device._attributes[DeviceAttributes.tilting_angle] = "off"
            self.device.set_attribute(DeviceAttributes.oscillation_mode.value, "both")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.oscillation_mode == 6
            assert message.oscillation_angle == 3
            assert message.tilting_angle == 3
            mock_build_send.reset_mock()

            self.device._attributes[DeviceAttributes.oscillation_angle] = "60"
            self.device._attributes[DeviceAttributes.tilting_angle] = "30"
            self.device.set_attribute(DeviceAttributes.oscillation_mode.value, "both")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.oscillation_angle == 2
            assert message.tilting_angle == 1
            mock_build_send.reset_mock()

            self.device._attributes[DeviceAttributes.oscillation_mode] = "both"
            self.device.set_attribute(DeviceAttributes.oscillation_mode.value, "")
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].oscillate is False
            mock_build_send.reset_mock()

            self.device.set_attribute(
                DeviceAttributes.oscillation_mode.value,
                "invalid",
            )
            mock_build_send.assert_not_called()

    def test_set_attribute_oscillation_angle(self) -> None:
        """Test set attribute oscillation angle."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device._attributes[DeviceAttributes.tilting_angle] = "off"
            self.device.set_attribute(DeviceAttributes.oscillation_angle.value, "off")
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].oscillate is False
            mock_build_send.reset_mock()

            self.device._attributes[DeviceAttributes.oscillation_angle] = "90"
            self.device._attributes[DeviceAttributes.tilting_angle] = "30"
            self.device.set_attribute(DeviceAttributes.oscillation_angle.value, "off")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.oscillate is True
            assert message.oscillation_mode == 2
            assert message.tilting_angle == 1
            mock_build_send.reset_mock()

            self.device._attributes[DeviceAttributes.oscillation_angle] = None
            self.device._attributes[DeviceAttributes.tilting_angle] = "off"
            self.device.set_attribute(DeviceAttributes.oscillation_angle.value, "90")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.oscillation_angle == 3
            assert message.oscillation_mode == 1
            mock_build_send.reset_mock()

            self.device._attributes[DeviceAttributes.tilting_angle] = "60"
            self.device._attributes[DeviceAttributes.oscillation_mode] = "tilting"
            self.device.set_attribute(DeviceAttributes.oscillation_angle.value, "90")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.oscillation_mode == 6
            assert message.tilting_angle == 2
            mock_build_send.reset_mock()

            self.device._attributes[DeviceAttributes.oscillation_mode] = "both"
            self.device.set_attribute(DeviceAttributes.oscillation_angle.value, "120")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.oscillation_angle == 4
            assert message.oscillation_mode is None
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.oscillation_angle.value, "45")
            mock_build_send.assert_not_called()

    def test_set_attribute_tilting_angle(self) -> None:
        """Test set attribute tilting angle."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device._attributes[DeviceAttributes.oscillation_angle] = "off"
            self.device.set_attribute(DeviceAttributes.tilting_angle.value, "off")
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].oscillate is False
            mock_build_send.reset_mock()

            self.device._attributes[DeviceAttributes.tilting_angle] = "60"
            self.device._attributes[DeviceAttributes.oscillation_angle] = "30"
            self.device.set_attribute(DeviceAttributes.tilting_angle.value, "off")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.oscillate is True
            assert message.oscillation_mode == 1
            assert message.oscillation_angle == 1
            mock_build_send.reset_mock()

            self.device._attributes[DeviceAttributes.tilting_angle] = None
            self.device._attributes[DeviceAttributes.oscillation_angle] = "off"
            self.device.set_attribute(DeviceAttributes.tilting_angle.value, "60")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.tilting_angle == 2
            assert message.oscillation_mode == 2
            mock_build_send.reset_mock()

            self.device._attributes[DeviceAttributes.oscillation_angle] = "90"
            self.device._attributes[DeviceAttributes.oscillation_mode] = "oscillation"
            self.device.set_attribute(DeviceAttributes.tilting_angle.value, "60")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.oscillation_mode == 6
            assert message.oscillation_angle == 3
            mock_build_send.reset_mock()

            self.device._attributes[DeviceAttributes.oscillation_mode] = "both"
            self.device.set_attribute(DeviceAttributes.tilting_angle.value, "40")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.tilting_angle == 9
            assert message.oscillation_mode is None
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.tilting_angle.value, "45")
            mock_build_send.assert_not_called()

    def test_set_attribute_fan_speed(self) -> None:
        """Test set attribute fan speed."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.fan_speed.value, 2)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.fan_speed == 2
            assert message.power is True
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.fan_speed.value, 0)
            mock_build_send.assert_not_called()

            self.device._attributes[DeviceAttributes.power] = True
            self.device.set_attribute(DeviceAttributes.fan_speed.value, 3)
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].fan_speed == 3

    def test_set_attribute_mode(self) -> None:
        """Test set attribute mode."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.mode.value, "sleep")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.mode == 3
            assert message.power is True
            assert message._body[3] == 0x07
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.mode.value, "ionic")
            mock_build_send.assert_not_called()
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.mode.value, "not_a_mode")
            mock_build_send.assert_not_called()
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.mode.value, "invalid")
            mock_build_send.assert_not_called()

        self.device = _make_device("560000F3")
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.mode.value, "ionic")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageNewSet)
            assert message.mode == 14
            assert message.power is True
            assert message._body[3] == 0x1D
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.mode.value, "ecology")
            mock_build_send.assert_not_called()

        self.device = _make_device("56011CB4")
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.mode.value, "ecology")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageCB4Set)
            assert message.mode == 21
            assert message.power is True
            assert message._body[3] == 0x2B
            assert len(message.body) == 54
            assert message._body[37] == 0xFF
            assert message._body[44] == 0xFF
            assert message._body[51] == 0xFF
            assert message._body[52] == 0xFF

        self.device = _make_device("56011CEC")
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.mode.value, "ecology")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageV6Set)
            assert message.mode == 21
            assert message.power is True
            assert message._body[3] == 0x2B
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.mode.value, "natural")
            mock_build_send.assert_not_called()

    def test_legacy_model_mode_override(self) -> None:
        """Test the 56000211 legacy mode byte required by the device."""
        device = _make_device("56000211")
        body = bytearray(36)
        body[4] = 0x29
        status = device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )
        assert status[DeviceAttributes.mode.value] == "comfort"
        assert status[DeviceAttributes.auto_power_off.value] is None

        with patch.object(device, "build_send") as mock_build_send:
            device.set_attribute(DeviceAttributes.mode.value, "comfort")

        message = mock_build_send.call_args[0][0]
        assert message.mode == 4
        assert message._body[3] == 0x29

        mock_build_send.reset_mock()
        with patch.object(device, "build_send") as mock_build_send:
            device.turn_on(mode="comfort")

        message = mock_build_send.call_args[0][0]
        assert message.mode == 4
        assert message._body[3] == 0x29

    def test_protocol_specific_mode_status(self) -> None:
        """Test mode 21 maps only for Lua protocols that expose Ecology."""
        body = bytearray(52)
        body[4] = 0x2B
        body[23] = 5

        self.device = _make_device("560000F3")
        status = self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )
        assert status[DeviceAttributes.mode.value] is None

        self.device = _make_device("56011CB4")
        status = self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )
        assert status[DeviceAttributes.mode.value] == "ecology"

        body[4] = 0x05
        status = self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )
        assert status[DeviceAttributes.mode.value] == "natural"

        body = bytearray(63)
        body[4] = 0x2B
        body[23] = 6
        self.device = _make_device("56011CEC")
        status = self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )
        assert status[DeviceAttributes.mode.value] == "ecology"

    def test_set_attribute_other(self) -> None:
        """Test set attribute for plain attributes."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_build_send.assert_called_once()
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.child_lock.value, True)
            mock_build_send.assert_called_once()
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.humidify.value, True)
            mock_build_send.assert_called_once()
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.waterions.value, True)
            mock_build_send.assert_called_once()
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.display_on_off.value, True)
            mock_build_send.assert_called_once()

    def test_turn_on(self) -> None:
        """Test turn on."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.turn_on()
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.power is True
            assert message.mode is None
            mock_build_send.reset_mock()

            self.device.turn_on(fan_speed=3, mode="normal")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.power is True
            assert message.fan_speed == 3
            assert message.mode == 1
            mock_build_send.reset_mock()

            self.device.turn_on(mode="not_a_mode")
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].mode is None

    def test_set_customize(self) -> None:
        """Test set customize."""
        self.device.set_customize('{"speed_count": 5}')
        assert self.device.speed_count == 5

        v6_device = _make_device("56011CEC")
        v6_device.set_customize('{"speed_count": 100}')
        assert v6_device.speed_count == 100
        v6_device.set_customize('{"speed_count": 101}')
        assert v6_device.speed_count == 3

        v5_device = _make_device("560000F3")
        v5_device.set_customize('{"speed_count": 50}')
        assert v5_device.speed_count == 3

    def test_set_customize_empty_params(self) -> None:
        """Test set customize with an empty JSON object."""
        self.device.set_customize("{}")
        assert self.device.speed_count == 3

    def test_set_customize_invalid(self) -> None:
        """Test set customize with invalid JSON keeps defaults."""
        self.device.set_customize("{")
        assert self.device.speed_count == 3
