"""Test FA Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.fa import DeviceAttributes, MideaFADevice
from midealocal.devices.fa.message import MessageQuery
from midealocal.message import MessageType


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


class TestMideaFADevice:
    """Test Midea FA Device."""

    device: MideaFADevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea FA Device setup."""
        self.device = MideaFADevice(
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
            "plus_60",
            "minus_60",
            "40",
        ]
        assert self.device.oscillation_modes == [
            "off",
            "oscillation",
            "tilting",
            "curve_w",
            "curve_8",
            "reserved",
            "both",
        ]
        assert self.device.preset_modes[0] == "normal"
        assert len(self.device.preset_modes) == 13

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    def test_query_response_full_body(self) -> None:
        """Test query response with a full-length body and valid values."""
        body = bytearray(36)
        body[3] = 0x01  # child lock on
        body[4] = 0x03  # power on, mode raw 1 -> Normal
        body[5] = 0x03  # fan speed 3
        body[8] = 0x33  # oscillate on, angle 3 -> 90, mode 1 -> Oscillation
        body[9] = 0x20  # humidify on
        body[19] = 0x40  # display on
        body[25] = 0x02  # tilting angle 2 -> 60
        body[34] = 0x01  # waterions on
        new_status = self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.child_lock] is True
        assert self.device.attributes[DeviceAttributes.mode] == "normal"
        assert self.device.attributes[DeviceAttributes.fan_speed] == 3
        assert self.device.attributes[DeviceAttributes.oscillate] is True
        assert self.device.attributes[DeviceAttributes.oscillation_angle] == "90"
        assert self.device.attributes[DeviceAttributes.tilting_angle] == "60"
        assert (
            self.device.attributes[DeviceAttributes.oscillation_mode] == "oscillation"
        )
        assert self.device.attributes[DeviceAttributes.humidify] is True
        assert self.device.attributes[DeviceAttributes.waterions] is True
        assert self.device.attributes[DeviceAttributes.display_on_off] is True
        assert new_status[DeviceAttributes.mode.value] == "normal"
        assert new_status[DeviceAttributes.fan_speed.value] == 3

    def test_notify_response_out_of_range_values(self) -> None:
        """Test notify1 response with out-of-range values mapped to None."""
        body = bytearray(36)
        body[4] = 0x1F  # power on, mode raw 15 -> 14 -> out of range
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
        assert DeviceAttributes.mode.value not in new_status

    def test_power_off_without_fan_speed_field_reports_reset(self) -> None:
        """A power-off message lacking its own fan_speed field still reports it."""
        self.device._attributes[DeviceAttributes.power] = True
        self.device._attributes[DeviceAttributes.fan_speed] = 3

        class _FakePowerOnlyMessage:
            power = False

        with patch(
            "midealocal.devices.fa.MessageFAResponse",
            return_value=_FakePowerOnlyMessage(),
        ):
            new_status = self.device.process_message(b"")
        assert self.device.attributes[DeviceAttributes.fan_speed] == 0
        assert new_status[DeviceAttributes.fan_speed.value] == 0

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
            assert mock_build_send.call_args[0][0].mode == 2
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.mode.value, "invalid")
            mock_build_send.assert_not_called()

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
            assert message.mode == 0
            mock_build_send.reset_mock()

            self.device.turn_on(mode="invalid")
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].mode is None

    def test_set_customize(self) -> None:
        """Test set customize."""
        self.device.set_customize('{"speed_count": 5}')
        assert self.device.speed_count == 5

    def test_set_customize_empty_params(self) -> None:
        """Test set customize with an empty JSON object."""
        self.device.set_customize("{}")
        assert self.device.speed_count == 3

    def test_set_customize_invalid(self) -> None:
        """Test set customize with invalid JSON keeps defaults."""
        self.device.set_customize("{")
        assert self.device.speed_count == 3
