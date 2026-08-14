"""Test FC Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.fc import DeviceAttributes, MideaFCDevice
from midealocal.devices.fc.message import MessageQuery
from midealocal.message import MessageType


def _build_message(
    protocol_version: int,
    message_type: MessageType,
    body: bytearray,
) -> bytes:
    """Build a full FC response message."""
    header = bytearray(
        [0xAA] + ([0x0] * 7) + [protocol_version] + [message_type],
    )
    return bytes(header + body + bytearray([0x00]))


class TestMideaFCDevice:
    """Test Midea FC Device."""

    device: MideaFCDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea FC Device setup."""
        self.device = MideaFCDevice(
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
        assert self.device.attributes[DeviceAttributes.mode] is None
        assert self.device.attributes[DeviceAttributes.fan_speed] is None
        assert self.device.attributes[DeviceAttributes.anion] is False
        assert self.device.attributes[DeviceAttributes.standby] is False
        assert self.device.attributes[DeviceAttributes.screen_display] is None
        assert self.device.attributes[DeviceAttributes.detect_mode] is None
        assert self.device.attributes[DeviceAttributes.pm25] is None
        assert self.device.attributes[DeviceAttributes.tvoc] is None
        assert self.device.attributes[DeviceAttributes.hcho] is None
        assert self.device.attributes[DeviceAttributes.child_lock] is False
        assert self.device.attributes[DeviceAttributes.prompt_tone] is True
        assert self.device.attributes[DeviceAttributes.filter1_life] is None
        assert self.device.attributes[DeviceAttributes.filter2_life] is None

    def test_properties(self) -> None:
        """Test properties."""
        assert self.device.modes == [
            "standby",
            "auto",
            "manual",
            "sleep",
            "fast",
            "smoke",
        ]
        assert self.device.fan_speeds == ["auto", "standby", "low", "medium", "high"]
        assert self.device.screen_displays == ["bright", "dim", "off"]
        assert self.device.detect_modes == ["off", "pm_25", "methanal"]

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    def test_query_response_full_body(self) -> None:
        """Test query response with a full-length general body."""
        body = bytearray(40)
        body[0] = 0xC8
        body[1] = 0x09  # power on, detect mode enabled
        body[2] = 0x10  # mode auto
        body[3] = 39  # fan speed low
        body[8] = 0x80  # child lock on
        body[9] = 0x06  # screen display dim
        body[13] = 0x10  # pm25 low byte
        body[14] = 0x00  # pm25 high byte
        body[15] = 0x05  # tvoc
        body[19] = 0x40  # anion on
        body[23] = 88  # filter1 life
        body[24] = 77  # filter2 life
        body[29] = 0x00  # detect mode PM 2.5
        body[34] = 0x14  # standby on
        body[37] = 0x02  # hcho low byte
        body[38] = 0x00  # hcho high byte
        new_status = self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.mode] == "auto"
        assert self.device.attributes[DeviceAttributes.fan_speed] == "low"
        assert self.device.attributes[DeviceAttributes.screen_display] == "dim"
        assert self.device.attributes[DeviceAttributes.detect_mode] == "pm_25"
        assert self.device.attributes[DeviceAttributes.pm25] == 16
        assert self.device.attributes[DeviceAttributes.tvoc] == 5
        assert self.device.attributes[DeviceAttributes.hcho] == 2
        assert self.device.attributes[DeviceAttributes.anion] is True
        assert self.device.attributes[DeviceAttributes.standby] is True
        assert self.device.attributes[DeviceAttributes.child_lock] is True
        assert self.device.attributes[DeviceAttributes.filter1_life] == 88
        assert self.device.attributes[DeviceAttributes.filter2_life] == 77
        assert new_status[DeviceAttributes.mode.value] == "auto"
        assert new_status[DeviceAttributes.fan_speed.value] == "low"

    def test_query_response_invalid_values(self) -> None:
        """Test query response with values not present in the maps."""
        body = bytearray(40)
        body[0] = 0xC8
        body[1] = 0x08  # power off, detect mode enabled
        body[2] = 0x60  # unknown mode
        body[3] = 50  # unknown fan speed
        body[9] = 0x05  # unknown screen display
        body[14] = 0xFF  # pm25 invalid
        body[15] = 0xFF  # tvoc invalid
        body[29] = 0x02  # detect mode out of range
        body[38] = 0xFF  # hcho invalid
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )
        assert self.device.attributes[DeviceAttributes.power] is False
        assert self.device.attributes[DeviceAttributes.mode] is None
        assert self.device.attributes[DeviceAttributes.fan_speed] is None
        assert self.device.attributes[DeviceAttributes.screen_display] is None
        assert self.device.attributes[DeviceAttributes.detect_mode] is None
        assert self.device.attributes[DeviceAttributes.pm25] is None
        assert self.device.attributes[DeviceAttributes.tvoc] is None
        assert self.device.attributes[DeviceAttributes.hcho] is None
        assert self.device.attributes[DeviceAttributes.anion] is False
        assert self.device.attributes[DeviceAttributes.standby] is False
        assert self.device.attributes[DeviceAttributes.child_lock] is False

    def test_query_response_detect_off(self) -> None:
        """Test query response with a full-length body and detect mode off."""
        body = bytearray(40)
        body[0] = 0xC8
        body[1] = 0x01  # power on, no detect mode
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.detect_mode] == "off"

    def test_query_response_short_body(self) -> None:
        """Test query response with a short general body."""
        body = bytearray(11)
        body[0] = 0xC8
        body[1] = 0x01  # power on, no detect mode
        body[2] = 0x20  # mode Manual
        body[3] = 0x04  # fan speed Standby
        body[9] = 0x00  # screen display Bright
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.mode] == "manual"
        assert self.device.attributes[DeviceAttributes.fan_speed] == "standby"
        assert self.device.attributes[DeviceAttributes.screen_display] == "bright"
        assert self.device.attributes[DeviceAttributes.detect_mode] is None
        assert self.device.attributes[DeviceAttributes.pm25] is None
        assert self.device.attributes[DeviceAttributes.tvoc] is None
        assert self.device.attributes[DeviceAttributes.hcho] is None
        assert self.device.attributes[DeviceAttributes.anion] is False
        assert self.device.attributes[DeviceAttributes.standby] is False
        assert self.device.attributes[DeviceAttributes.child_lock] is False
        assert self.device.attributes[DeviceAttributes.filter1_life] is None
        assert self.device.attributes[DeviceAttributes.filter2_life] is None

    def test_notify_response_full_body(self) -> None:
        """Test notify1 response with a full-length notify body."""
        body = bytearray(33)
        body[0] = 0xA0
        body[1] = 0x09  # power on, detect mode enabled
        body[2] = 0x30  # mode Sleep
        body[3] = 59  # fan speed Medium
        body[9] = 0x07  # screen display Off
        body[10] = 0x30  # anion on, child lock on
        body[13] = 0x10  # pm25 low byte
        body[14] = 0x00  # pm25 high byte
        body[15] = 0x05  # tvoc
        body[22] = 0x01  # detect mode Methanal
        body[30] = 0x01  # hcho low byte
        body[31] = 0x00  # hcho high byte
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.notify1, body),
        )
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.mode] == "sleep"
        assert self.device.attributes[DeviceAttributes.fan_speed] == "medium"
        assert self.device.attributes[DeviceAttributes.screen_display] == "off"
        assert self.device.attributes[DeviceAttributes.detect_mode] == "methanal"
        assert self.device.attributes[DeviceAttributes.pm25] == 16
        assert self.device.attributes[DeviceAttributes.tvoc] == 5
        assert self.device.attributes[DeviceAttributes.hcho] == 1
        assert self.device.attributes[DeviceAttributes.anion] is True
        assert self.device.attributes[DeviceAttributes.standby] is False
        assert self.device.attributes[DeviceAttributes.child_lock] is True

    def test_notify_response_no_detect(self) -> None:
        """Test notify1 response without detect mode and invalid sensors."""
        body = bytearray(33)
        body[0] = 0xA0
        body[1] = 0x01  # power on, no detect mode
        body[14] = 0xFF  # pm25 invalid
        body[15] = 0xFF  # tvoc invalid
        body[31] = 0xFF  # hcho invalid
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.notify1, body),
        )
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.detect_mode] == "off"
        assert self.device.attributes[DeviceAttributes.pm25] is None
        assert self.device.attributes[DeviceAttributes.tvoc] is None
        assert self.device.attributes[DeviceAttributes.hcho] is None
        assert self.device.attributes[DeviceAttributes.anion] is False
        assert self.device.attributes[DeviceAttributes.child_lock] is False

    def test_notify_response_short_body(self) -> None:
        """Test notify1 response with a short notify body."""
        body = bytearray(10)
        body[0] = 0xA0
        body[1] = 0x01  # power on
        body[2] = 0x00  # mode Standby
        body[3] = 0x01  # fan speed Auto
        self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.notify1, body),
        )
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.mode] == "standby"
        assert self.device.attributes[DeviceAttributes.fan_speed] == "auto"
        assert self.device.attributes[DeviceAttributes.anion] is False
        assert self.device.attributes[DeviceAttributes.standby] is False
        assert self.device.attributes[DeviceAttributes.child_lock] is False

    def test_b0_b1_response_ignored(self) -> None:
        """Test B0 and B1 bodies are ignored."""
        body = bytearray(20)
        body[0] = 0xB0
        new_status = self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.notify1, body),
        )
        assert new_status == {}

        body[0] = 0xB1
        new_status = self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.notify1, body),
        )
        assert new_status == {}

    def test_unexpected_response(self) -> None:
        """Test unhandled message type is ignored."""
        body = bytearray(20)
        body[0] = 0xC8
        new_status = self.device.process_message(
            _build_message(ProtocolVersion.V1, MessageType.notify2, body),
        )
        assert new_status == {}

    def test_make_message_set_defaults(self) -> None:
        """Test make message set with default attributes."""
        message = self.device.make_message_set()
        assert message.power is False
        assert message.mode == 0x10
        assert message.fan_speed == 39
        assert message.screen_display == 0
        assert message.detect_mode == 0
        assert message.standby_detect == [40, 20]

    def test_make_message_set_with_attributes(self) -> None:
        """Test make message set with populated attributes."""
        self.device._attributes[DeviceAttributes.power] = True
        self.device._attributes[DeviceAttributes.mode] = "manual"
        self.device._attributes[DeviceAttributes.fan_speed] = "high"
        self.device._attributes[DeviceAttributes.screen_display] = "dim"
        self.device._attributes[DeviceAttributes.detect_mode] = "pm_25"
        self.device._attributes[DeviceAttributes.anion] = True
        self.device._attributes[DeviceAttributes.standby] = True
        self.device._attributes[DeviceAttributes.child_lock] = True
        message = self.device.make_message_set()
        assert message.power is True
        assert message.mode == 0x20
        assert message.fan_speed == 80
        assert message.screen_display == 6
        assert message.detect_mode == 1
        assert message.anion is True
        assert message.standby is True
        assert message.child_lock is True

    def test_set_attribute_prompt_tone(self) -> None:
        """Test set attribute prompt tone does not send a message."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.prompt_tone.value, False)
            mock_build_send.assert_not_called()
            assert self.device.attributes[DeviceAttributes.prompt_tone] is False

    def test_set_attribute_mode(self) -> None:
        """Test set attribute mode."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.mode.value, "sleep")
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].mode == 0x30
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.mode.value, "invalid")
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].mode == 0x10

    def test_set_attribute_fan_speed(self) -> None:
        """Test set attribute fan speed."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.fan_speed.value, "high")
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].fan_speed == 80
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.fan_speed.value, "invalid")
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].fan_speed == 39

    def test_set_attribute_screen_display(self) -> None:
        """Test set attribute screen display."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.screen_display.value, "dim")
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].screen_display == 6
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.screen_display.value, "")
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].screen_display == 7
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.screen_display.value, "invalid")
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].screen_display == 0

    def test_set_attribute_detect_mode(self) -> None:
        """Test set attribute detect mode."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.detect_mode.value, "methanal")
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].detect_mode == 2
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.detect_mode.value, "")
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].detect_mode == 0
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.detect_mode.value, "invalid")
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].detect_mode == 0

    def test_set_attribute_other(self) -> None:
        """Test set attribute for plain attributes."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].power is True
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.child_lock.value, True)
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].child_lock is True
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.anion.value, True)
            mock_build_send.assert_called_once()
            assert mock_build_send.call_args[0][0].anion is True

    def test_set_customize(self) -> None:
        """Test set customize."""
        self.device.set_customize('{"standby_detect": [50, 20]}')
        assert self.device._standby_detect == [50, 20]

    def test_set_customize_invalid_order(self) -> None:
        """Test set customize with low value above high value keeps defaults."""
        self.device.set_customize('{"standby_detect": [20, 50]}')
        assert self.device._standby_detect == [40, 20]

    def test_set_customize_wrong_length(self) -> None:
        """Test set customize with a wrong-length list keeps defaults."""
        self.device.set_customize('{"standby_detect": [50]}')
        assert self.device._standby_detect == [40, 20]

    def test_set_customize_empty_params(self) -> None:
        """Test set customize with an empty JSON object."""
        self.device.set_customize("{}")
        assert self.device._standby_detect == [40, 20]

    def test_set_customize_invalid(self) -> None:
        """Test set customize with invalid JSON keeps defaults."""
        self.device.set_customize("{")
        assert self.device._standby_detect == [40, 20]
