"""Test B8 second-generation ("v2") protocol support."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices import b8
from midealocal.devices.b8 import (
    B8WorkMode,
    DeviceAttributes,
    MideaB8Device,
)
from midealocal.devices.b8.message import MessageQuery
from midealocal.devices.b8.message_v2 import (
    B8V2ConfigType,
    B8V2FanLevel,
    B8V2TaskControl,
    B8V2WaterLevel,
    MessageB8V2Response,
    MessageV2Query,
    MessageV2SetCommand,
    MessageV2SetConfig,
)
from midealocal.message import ListTypes, MessageType

_V2_SUBTYPE = 999


def _v2_frame(
    values: dict[int, int],
    *,
    message_type: MessageType = MessageType.query,
    selector: int = 0x01,
    length: int = 52,
) -> bytes:
    """Build a synthetic B8 v2 response frame.

    ``values`` maps body-byte index (``body[0]`` == frame byte 10) to value.
    """
    header = bytearray([0xAA] + [0x0] * 7 + [ProtocolVersion.V1, message_type])
    body = bytearray(length)
    for index, value in ({0: ListTypes.AA, 1: 0x01, 2: selector} | values).items():
        if index < length:
            body[index] = value
    return bytes(header + body + bytearray([0x0]))  # trailing checksum byte


class TestMideaB8DeviceV2:
    """Test the v2 code paths of MideaB8Device."""

    device: MideaB8Device

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        self.device = MideaB8Device(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.1",
            port=12345,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model="test_model",
            subtype=_V2_SUBTYPE,
            customize="",
        )

    @pytest.fixture
    def _enable_v2(self, monkeypatch: pytest.MonkeyPatch) -> None:
        monkeypatch.setattr(b8, "_V2_SUBTYPES", frozenset({_V2_SUBTYPE}))

    def test_v2_inactive_by_default(self) -> None:
        """Without a matching subtype the device keeps the v1 protocol."""
        assert self.device._is_v2 is False
        assert isinstance(self.device.build_query()[0], MessageQuery)

    @pytest.mark.usefixtures("_enable_v2")
    def test_v2_active_for_listed_subtype(self) -> None:
        """A listed subtype switches every entry point to v2."""
        assert self.device._is_v2 is True
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageV2Query)
        assert queries[0].body == bytearray([ListTypes.AA, 0x01, 0x01])

    @pytest.mark.usefixtures("_enable_v2")
    def test_v2_work_status_response(self) -> None:
        """A v2 work-status frame updates the shared attributes."""
        frame = _v2_frame(
            {
                3: 0x05,  # work_status WORK
                5: 0x02,  # control_type AUTO
                7: 0x08,  # clean_mode AUTO
                8: 0x02,  # fan_level HIGH
                9: 12,  # area
                10: 0x02,  # water_level NORMAL
                11: 40,  # voice_volume
                12: 1,  # have_reserve_task
                13: 77,  # battery_percent
                14: 20,  # work_time
                18: 0x01,  # mop ON
                19: 1,  # carpet_switch
                34: 0x01,  # sweep_mop_mode SWEEP
                50: 0xC7,  # uv+wifi+voice+command_source+device_error
            },
        )
        self.device.process_message(frame)
        attrs = self.device.attributes
        assert attrs[DeviceAttributes.work_status] == "work"
        assert attrs[DeviceAttributes.sub_work_status] == "none"
        assert attrs[DeviceAttributes.sweep_mop_mode] == "sweep"
        assert attrs[DeviceAttributes.control_type] == "auto"
        assert attrs[DeviceAttributes.clean_mode] == "auto"
        assert attrs[DeviceAttributes.fan_level] == "high"
        assert attrs[DeviceAttributes.area] == 12
        assert attrs[DeviceAttributes.water_level] == "normal"
        assert attrs[DeviceAttributes.voice_volume] == 40
        assert attrs[DeviceAttributes.have_reserve_task] is True
        assert attrs[DeviceAttributes.battery_percent] == 77
        assert attrs[DeviceAttributes.work_time] == 20
        assert attrs[DeviceAttributes.error_type] == "no"
        assert attrs[DeviceAttributes.error_desc] == "no"
        assert attrs[DeviceAttributes.mop] == "on"
        assert attrs[DeviceAttributes.carpet_switch] is True
        assert attrs[DeviceAttributes.uv_switch] is True
        assert attrs[DeviceAttributes.wifi_switch] is True
        assert attrs[DeviceAttributes.voice_switch] is True
        assert attrs[DeviceAttributes.command_source] is True
        assert attrs[DeviceAttributes.device_error] is True

    @pytest.mark.usefixtures("_enable_v2")
    @pytest.mark.parametrize(
        ("work_status", "sub_byte", "expected"),
        [
            pytest.param(0x12, 0x03, "clean_mop", id="on_base"),
            pytest.param(0x0A, 0x31, "pause_sleeping", id="sleep"),
            pytest.param(0x0B, 0x52, "wheel_lift", id="relocate"),
            pytest.param(0x05, 0x03, "none", id="work-has-no-sub"),
            pytest.param(0x12, 0xEE, "none", id="unknown-sub-code"),
        ],
    )
    def test_v2_sub_work_status(
        self,
        work_status: int,
        sub_byte: int,
        expected: str,
    ) -> None:
        """The sub-status byte is decoded against the table for the work state."""
        self.device.process_message(_v2_frame({3: work_status, 36: sub_byte}))
        assert self.device.attributes[DeviceAttributes.sub_work_status] == expected

    @pytest.mark.usefixtures("_enable_v2")
    @pytest.mark.parametrize(
        ("error_type", "desc_byte", "expected_type", "expected_desc"),
        [
            pytest.param(
                0x01,
                0x14,
                "can_fix",
                "fix_vibration_drag_overload",
                id="fix",
            ),
            pytest.param(0x02, 0x01, "reboot", "reboot_laser_comm_fail", id="reboot"),
            pytest.param(
                0x03,
                0xCC,
                "warning",
                "warn_washer_base_station_communication_failed",
                id="warn",
            ),
            pytest.param(0x01, 0xFD, "can_fix", "no", id="unknown-fix-code"),
            pytest.param(0x00, 0x14, "no", "no", id="no-error"),
        ],
    )
    def test_v2_error_desc(
        self,
        error_type: int,
        desc_byte: int,
        expected_type: str,
        expected_desc: str,
    ) -> None:
        """The error description byte is decoded against the error-type table."""
        self.device.process_message(_v2_frame({16: error_type, 17: desc_byte}))
        assert self.device.attributes[DeviceAttributes.error_type] == expected_type
        assert self.device.attributes[DeviceAttributes.error_desc] == expected_desc

    @pytest.mark.usefixtures("_enable_v2")
    def test_v2_invalid_enum_fallbacks(self) -> None:
        """Out-of-range enum bytes fall back to defaults without dropping scalars."""
        frame = _v2_frame(
            {
                3: 0x7F,  # invalid work_status
                5: 0x7F,  # invalid control_type
                6: 0x7F,  # invalid move_direction
                7: 0x7F,  # invalid clean_mode
                8: 0x7F,  # invalid fan_level
                9: 33,  # area preserved
                10: 0x7F,  # invalid water_level
                16: 0x7F,  # invalid error_type
                18: 0x7F,  # invalid mop state
                34: 0x7F,  # invalid sweep_mop_mode
            },
        )
        self.device.process_message(frame)
        attrs = self.device.attributes
        assert attrs[DeviceAttributes.work_status] == "none"
        assert attrs[DeviceAttributes.control_type] == "none"
        assert attrs[DeviceAttributes.move_direction] == "none"
        assert attrs[DeviceAttributes.clean_mode] == "none"
        assert attrs[DeviceAttributes.fan_level] == "normal"
        assert attrs[DeviceAttributes.water_level] == "low"
        assert attrs[DeviceAttributes.error_type] == "no"
        assert attrs[DeviceAttributes.mop] == "lack_water"
        assert attrs[DeviceAttributes.sweep_mop_mode] == "sweep_and_mop"
        assert attrs[DeviceAttributes.area] == 33

    @pytest.mark.usefixtures("_enable_v2")
    @pytest.mark.parametrize(
        ("work_mode", "expected_task"),
        [
            pytest.param(B8WorkMode.CHARGE, B8V2TaskControl.CHARGE, id="charge"),
            pytest.param(B8WorkMode.WORK, B8V2TaskControl.WORK, id="work"),
            pytest.param(B8WorkMode.STOP, B8V2TaskControl.STOP, id="stop"),
            pytest.param(B8WorkMode.PAUSE, B8V2TaskControl.PAUSE, id="pause"),
        ],
    )
    def test_v2_set_work_mode(
        self,
        work_mode: B8WorkMode,
        expected_task: B8V2TaskControl,
    ) -> None:
        """v2 start/stop/charge/pause go through the task-control channel."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_work_mode(work_mode)
        mock_send.assert_called_once()
        msg = mock_send.call_args.args[0]
        assert isinstance(msg, MessageV2SetCommand)
        assert msg.task_control == expected_task
        assert msg.body == bytearray([ListTypes.AA, 0x01, 0x01, expected_task])

    @pytest.mark.usefixtures("_enable_v2")
    def test_v2_set_work_mode_unmapped(
        self,
        monkeypatch: pytest.MonkeyPatch,
    ) -> None:
        """A work mode with no v2 task-control equivalent emits nothing."""
        monkeypatch.setattr(b8, "_WORK_MODE_TO_V2_TASK", {})
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_work_mode(B8WorkMode.WORK)
        mock_send.assert_not_called()

    @pytest.mark.usefixtures("_enable_v2")
    @pytest.mark.parametrize(
        ("attr", "value", "config_type", "expected_value"),
        [
            pytest.param(
                DeviceAttributes.fan_level,
                "super",
                B8V2ConfigType.FAN,
                B8V2FanLevel.SUPER,
                id="fan",
            ),
            pytest.param(
                DeviceAttributes.water_level,
                "high",
                B8V2ConfigType.WATER,
                B8V2WaterLevel.HIGH,
                id="water",
            ),
            pytest.param(
                DeviceAttributes.voice_volume,
                40,
                B8V2ConfigType.VOICE,
                40,
                id="voice",
            ),
        ],
    )
    def test_v2_set_attribute(
        self,
        attr: DeviceAttributes,
        value: str | int,
        config_type: B8V2ConfigType,
        expected_value: int,
    ) -> None:
        """Each v2 setting is sent as its own config frame."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(attr.value, value)
        mock_send.assert_called_once()
        msg = mock_send.call_args.args[0]
        assert isinstance(msg, MessageV2SetConfig)
        assert msg.config_type == config_type
        assert msg.value == expected_value

    @pytest.mark.usefixtures("_enable_v2")
    @pytest.mark.parametrize(
        ("attr", "value"),
        [
            pytest.param(DeviceAttributes.clean_mode, "auto", id="clean_mode"),
            pytest.param(DeviceAttributes.fan_level, "invalid", id="invalid-value"),
        ],
    )
    def test_v2_set_attribute_unsupported(
        self,
        attr: DeviceAttributes,
        value: str,
    ) -> None:
        """Unsupported v2 attributes / bad values do not emit a frame."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(attr.value, value)
        mock_send.assert_not_called()


class TestMessageB8V2:
    """Test the v2 message classes directly."""

    def test_query_body(self) -> None:
        """Query body is body-type, version, selector."""
        msg = MessageV2Query(ProtocolVersion.V1)
        assert msg.body == bytearray([ListTypes.AA, 0x01, 0x01])

    def test_set_command_body(self) -> None:
        """Task-control body carries the 0x01 0x01 prefix and the code."""
        msg = MessageV2SetCommand(ProtocolVersion.V1, B8V2TaskControl.PAUSE)
        assert msg.body == bytearray([ListTypes.AA, 0x01, 0x01, 0x05])

    def test_set_config_body(self) -> None:
        """Config body carries the selector and value."""
        msg = MessageV2SetConfig(
            ProtocolVersion.V1,
            B8V2ConfigType.FAN,
            B8V2FanLevel.SUPER,
        )
        assert msg.body == bytearray([ListTypes.AA, 0x01, 0x50, 0x03])

    @pytest.mark.parametrize(
        ("message_type", "selector", "length", "expected"),
        [
            pytest.param(MessageType.query, 0x01, 52, True, id="query-work"),
            pytest.param(MessageType.notify1, 0x01, 52, True, id="notify-report"),
            pytest.param(MessageType.query, 0x50, 52, False, id="other-selector"),
            pytest.param(MessageType.set, 0x01, 52, False, id="set-not-parsed"),
            pytest.param(MessageType.query, 0x01, 2, False, id="too-short"),
        ],
    )
    def test_response_routing(
        self,
        message_type: MessageType,
        selector: int,
        length: int,
        expected: bool,
    ) -> None:
        """parse_body only accepts AA-framed work/report bodies."""
        frame = _v2_frame(
            {3: 0x05},
            message_type=message_type,
            selector=selector,
            length=length,
        )
        response = MessageB8V2Response(frame)
        assert hasattr(response, "work_status") is expected

    def test_response_ignores_non_aa_body(self) -> None:
        """A non-0xAA body type is not a v2 frame."""
        header = bytearray(
            [0xAA] + [0x0] * 7 + [ProtocolVersion.V1, MessageType.query],
        )
        body = bytearray([ListTypes.X32, 0x01, 0x01] + [0x0] * 49)
        response = MessageB8V2Response(bytes(header + body + bytearray([0x0])))
        assert hasattr(response, "work_status") is False
