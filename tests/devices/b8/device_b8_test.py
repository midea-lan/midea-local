"""Test B8 Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.b8 import (
    B8CleanMode,
    B8ControlType,
    B8ErrorCanFixDescription,
    B8ErrorType,
    B8FanLevel,
    B8FunctionType,
    B8MopState,
    B8Moviment,
    B8Speed,
    B8WaterLevel,
    B8WorkStatus,
    DeviceAttributes,
    MideaB8Device,
)
from midealocal.devices.b8.message import (
    B8ErrorRebootDescription,
    B8ErrorWarningDescription,
    MessageQuery,
)
from midealocal.message import MessageType


class TestMideaB8Device:
    """Test Midea B8 Device."""

    device: MideaB8Device

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea B8 Device setup."""
        self.device = MideaB8Device(
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
        assert (
            self.device.attributes[DeviceAttributes.work_status]
            == B8WorkStatus.NONE.name.lower()
        )
        assert (
            self.device.attributes[DeviceAttributes.function_type]
            == B8FunctionType.NONE.name.lower()
        )
        assert (
            self.device.attributes[DeviceAttributes.control_type]
            == B8ControlType.NONE.name.lower()
        )
        assert (
            self.device.attributes[DeviceAttributes.move_direction]
            == B8Moviment.NONE.name.lower()
        )
        assert (
            self.device.attributes[DeviceAttributes.clean_mode]
            == B8CleanMode.NONE.name.lower()
        )
        assert (
            self.device.attributes[DeviceAttributes.fan_level]
            == B8FanLevel.OFF.name.lower()
        )
        assert self.device.attributes[DeviceAttributes.area] == 0
        assert (
            self.device.attributes[DeviceAttributes.water_level]
            == B8WaterLevel.OFF.name.lower()
        )
        assert self.device.attributes[DeviceAttributes.voice_volume] == 0
        assert (
            self.device.attributes[DeviceAttributes.mop] == B8MopState.OFF.name.lower()
        )
        assert self.device.attributes[DeviceAttributes.carpet_switch] is False
        assert (
            self.device.attributes[DeviceAttributes.speed] == B8Speed.HIGH.name.lower()
        )
        assert self.device.attributes[DeviceAttributes.have_reserve_task] is False
        assert self.device.attributes[DeviceAttributes.battery_percent] == 0
        assert self.device.attributes[DeviceAttributes.work_time] == 0
        assert self.device.attributes[DeviceAttributes.uv_switch] is False
        assert self.device.attributes[DeviceAttributes.wifi_switch] is False
        assert self.device.attributes[DeviceAttributes.voice_switch] is False
        assert self.device.attributes[DeviceAttributes.command_source] is False
        assert (
            self.device.attributes[DeviceAttributes.error_type]
            == B8ErrorType.NO.name.lower()
        )
        assert self.device.attributes[DeviceAttributes.error_desc] == "no"
        assert self.device.attributes[DeviceAttributes.device_error] is False
        assert (
            self.device.attributes[DeviceAttributes.board_communication_error] is False
        )
        assert self.device.attributes[DeviceAttributes.laser_sensor_shelter] is False
        assert self.device.attributes[DeviceAttributes.laser_sensor_error] is False

    def test_set_attribute(self) -> None:
        """Test set attribute."""
        with patch.object(self.device, "send_message_v2") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.clean_mode.value, "area")
            mock_build_send.assert_called_once()
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.fan_level.value, "normal")
            mock_build_send.assert_called_once()
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.water_level.value, "normal")
            mock_build_send.assert_called_once()
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.voice_volume.value, 10)
            mock_build_send.assert_called_once()
            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.water_level.value, "invalid")
            mock_build_send.assert_not_called()

    def test_set_work_status(self) -> None:
        """Test set work status."""
        with patch.object(self.device, "send_message_v2") as mock_build_send:
            self.device.set_work_status(B8WorkStatus.CHARGE)
            mock_build_send.assert_called_once()
            mock_build_send.reset_mock()

            self.device.set_work_status(B8WorkStatus.WORK)
            mock_build_send.assert_called_once()

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    def test_query_response(self) -> None:
        """Test query response."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.query],
        )
        body = bytearray(
            [
                0x32,
                0x1,
                B8WorkStatus.CHARGING_WITH_WIRE,
                B8FunctionType.NONE,
                B8ControlType.AUTO,
                B8Moviment.NONE,
                B8CleanMode.AUTO,
                B8FanLevel.NORMAL,
                0,
                B8WaterLevel.NORMAL,
                40,
                0,
                80,
                20,
                0xC7,
                B8ErrorType.CAN_FIX,
                B8ErrorCanFixDescription.FIX_DUST,
                B8MopState.ON,
                0x01,
                0x07,
                B8Speed.HIGH,
                0x0,  # CRC
            ],
        )
        self.device.process_message(bytes(header + body))
        assert (
            self.device.attributes[DeviceAttributes.work_status] == "charging_with_wire"
        )
        assert self.device.attributes[DeviceAttributes.function_type] == "none"
        assert self.device.attributes[DeviceAttributes.control_type] == "auto"
        assert self.device.attributes[DeviceAttributes.move_direction] == "none"
        assert self.device.attributes[DeviceAttributes.clean_mode] == "auto"
        assert self.device.attributes[DeviceAttributes.fan_level] == "normal"
        assert self.device.attributes[DeviceAttributes.area] == 0
        assert self.device.attributes[DeviceAttributes.water_level] == "normal"
        assert self.device.attributes[DeviceAttributes.voice_volume] == 40
        assert self.device.attributes[DeviceAttributes.have_reserve_task] is False
        assert self.device.attributes[DeviceAttributes.battery_percent] == 80
        assert self.device.attributes[DeviceAttributes.work_time] == 20
        assert self.device.attributes[DeviceAttributes.uv_switch] is True
        assert self.device.attributes[DeviceAttributes.wifi_switch] is True
        assert self.device.attributes[DeviceAttributes.voice_switch] is True
        assert self.device.attributes[DeviceAttributes.command_source] is True
        assert self.device.attributes[DeviceAttributes.device_error] is True
        assert self.device.attributes[DeviceAttributes.error_type] == "can_fix"
        assert self.device.attributes[DeviceAttributes.error_desc] == "fix_dust"
        assert self.device.attributes[DeviceAttributes.mop] == "on"
        assert self.device.attributes[DeviceAttributes.carpet_switch] is True
        assert self.device.attributes[DeviceAttributes.laser_sensor_error] is True
        assert self.device.attributes[DeviceAttributes.laser_sensor_shelter] is True
        assert (
            self.device.attributes[DeviceAttributes.board_communication_error] is True
        )
        assert self.device.attributes[DeviceAttributes.speed] == "high"

    def test_notify_response(self) -> None:
        """Test notify response."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.notify1],
        )
        body = bytearray(
            [
                0x42,
                B8WorkStatus.WORK,
                B8FunctionType.DUST_BOX_CLEANING,
                B8ControlType.MANUAL,
                B8Moviment.LEFT,
                B8CleanMode.PATH,
                B8FanLevel.HIGH,
                1,
                B8WaterLevel.LOW,
                90,
                1,
                40,
                15,
                0x86,
                B8ErrorType.WARNING,
                B8ErrorWarningDescription.WARN_FULL_DUST,
                B8MopState.LACK_WATER,
                0x00,
                0x06,
                B8Speed.LOW,
                0x0,  # CRC
            ],
        )
        self.device.process_message(bytes(header + body))
        assert self.device.attributes[DeviceAttributes.work_status] == "work"
        assert (
            self.device.attributes[DeviceAttributes.function_type]
            == "dust_box_cleaning"
        )
        assert self.device.attributes[DeviceAttributes.control_type] == "manual"
        assert self.device.attributes[DeviceAttributes.move_direction] == "left"
        assert self.device.attributes[DeviceAttributes.clean_mode] == "path"
        assert self.device.attributes[DeviceAttributes.fan_level] == "high"
        assert self.device.attributes[DeviceAttributes.area] == 1
        assert self.device.attributes[DeviceAttributes.water_level] == "low"
        assert self.device.attributes[DeviceAttributes.voice_volume] == 90
        assert self.device.attributes[DeviceAttributes.have_reserve_task] is True
        assert self.device.attributes[DeviceAttributes.battery_percent] == 40
        assert self.device.attributes[DeviceAttributes.work_time] == 15
        assert self.device.attributes[DeviceAttributes.uv_switch] is False
        assert self.device.attributes[DeviceAttributes.wifi_switch] is True
        assert self.device.attributes[DeviceAttributes.voice_switch] is True
        assert self.device.attributes[DeviceAttributes.command_source] is False
        assert self.device.attributes[DeviceAttributes.device_error] is True
        assert self.device.attributes[DeviceAttributes.error_type] == "warning"
        assert self.device.attributes[DeviceAttributes.error_desc] == "warn_full_dust"
        assert self.device.attributes[DeviceAttributes.mop] == "lack_water"
        assert self.device.attributes[DeviceAttributes.carpet_switch] is False
        assert self.device.attributes[DeviceAttributes.laser_sensor_error] is False
        assert self.device.attributes[DeviceAttributes.laser_sensor_shelter] is True
        assert (
            self.device.attributes[DeviceAttributes.board_communication_error] is True
        )
        assert self.device.attributes[DeviceAttributes.speed] == "low"

    def test_query_response_reboot_error(self) -> None:
        """Test query response."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.query],
        )
        body = bytearray(
            [
                0x32,
                0x1,
                B8WorkStatus.UPDATING,
                B8FunctionType.WATER_TANK_CLEANING,
                B8ControlType.NONE,
                B8Moviment.NONE,
                B8CleanMode.NONE,
                B8FanLevel.OFF,
                0,
                B8WaterLevel.OFF,
                0,
                0,
                0,
                0,
                0,
                B8ErrorType.REBOOT,
                B8ErrorRebootDescription.REBOOT_LASER_COMM_FAIL,
                B8MopState.OFF,
                0x0,
                0x0,
                B8Speed.LOW,
                0x0,  # CRC
            ],
        )
        self.device.process_message(bytes(header + body))
        assert self.device.attributes[DeviceAttributes.work_status] == "updating"
        assert (
            self.device.attributes[DeviceAttributes.function_type]
            == "water_tank_cleaning"
        )
        assert self.device.attributes[DeviceAttributes.control_type] == "none"
        assert self.device.attributes[DeviceAttributes.move_direction] == "none"
        assert self.device.attributes[DeviceAttributes.clean_mode] == "none"
        assert self.device.attributes[DeviceAttributes.fan_level] == "off"
        assert self.device.attributes[DeviceAttributes.area] == 0
        assert self.device.attributes[DeviceAttributes.water_level] == "off"
        assert self.device.attributes[DeviceAttributes.voice_volume] == 0
        assert self.device.attributes[DeviceAttributes.have_reserve_task] is False
        assert self.device.attributes[DeviceAttributes.battery_percent] == 0
        assert self.device.attributes[DeviceAttributes.work_time] == 0
        assert self.device.attributes[DeviceAttributes.uv_switch] is False
        assert self.device.attributes[DeviceAttributes.wifi_switch] is False
        assert self.device.attributes[DeviceAttributes.voice_switch] is False
        assert self.device.attributes[DeviceAttributes.command_source] is False
        assert self.device.attributes[DeviceAttributes.device_error] is False
        assert self.device.attributes[DeviceAttributes.error_type] == "reboot"
        assert (
            self.device.attributes[DeviceAttributes.error_desc]
            == "reboot_laser_comm_fail"
        )
        assert self.device.attributes[DeviceAttributes.mop] == "off"
        assert self.device.attributes[DeviceAttributes.carpet_switch] is False
        assert self.device.attributes[DeviceAttributes.laser_sensor_error] is False
        assert self.device.attributes[DeviceAttributes.laser_sensor_shelter] is False
        assert (
            self.device.attributes[DeviceAttributes.board_communication_error] is False
        )
        assert self.device.attributes[DeviceAttributes.speed] == "low"

    @pytest.mark.parametrize(
        ("error_type", "error_type_name"),
        [
            pytest.param(B8ErrorType.CAN_FIX, "can_fix", id="can_fix"),
            pytest.param(B8ErrorType.REBOOT, "reboot", id="reboot"),
            pytest.param(B8ErrorType.WARNING, "warning", id="warning"),
        ],
    )
    def test_query_response_unknown_error_desc(
        self,
        error_type: B8ErrorType,
        error_type_name: str,
    ) -> None:
        """Test query response falls back to 'no' for unknown error sub-codes."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.query],
        )
        body = bytearray(
            [
                0x32,
                0x1,
                B8WorkStatus.CHARGING_WITH_WIRE,
                B8FunctionType.NONE,
                B8ControlType.AUTO,
                B8Moviment.NONE,
                B8CleanMode.AUTO,
                B8FanLevel.NORMAL,
                0,
                B8WaterLevel.NORMAL,
                40,
                0,
                80,
                20,
                0xC7,
                error_type,
                0xFF,  # unknown sub-code
                B8MopState.ON,
                0x01,
                0x07,
                B8Speed.HIGH,
                0x0,  # CRC
            ],
        )
        self.device.process_message(bytes(header + body))
        assert self.device.attributes[DeviceAttributes.error_type] == error_type_name
        assert self.device.attributes[DeviceAttributes.error_desc] == "no"

    def test_query_response_no_error(self) -> None:
        """Test query response."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.query],
        )
        body = bytearray(
            [
                0x32,
                0x1,
                B8WorkStatus.NONE,
                B8FunctionType.NONE,
                B8ControlType.NONE,
                B8Moviment.NONE,
                B8CleanMode.NONE,
                B8FanLevel.OFF,
                0,
                B8WaterLevel.OFF,
                0,
                0,
                0,
                0,
                0,
                B8ErrorType.NO,
                B8ErrorRebootDescription.REBOOT_LASER_COMM_FAIL,
                B8MopState.OFF,
                0x0,
                0x0,
                B8Speed.LOW,
                0x0,  # CRC
            ],
        )
        self.device.process_message(bytes(header + body))
        assert self.device.attributes[DeviceAttributes.work_status] == "none"
        assert self.device.attributes[DeviceAttributes.function_type] == "none"
        assert self.device.attributes[DeviceAttributes.control_type] == "none"
        assert self.device.attributes[DeviceAttributes.move_direction] == "none"
        assert self.device.attributes[DeviceAttributes.clean_mode] == "none"
        assert self.device.attributes[DeviceAttributes.fan_level] == "off"
        assert self.device.attributes[DeviceAttributes.area] == 0
        assert self.device.attributes[DeviceAttributes.water_level] == "off"
        assert self.device.attributes[DeviceAttributes.voice_volume] == 0
        assert self.device.attributes[DeviceAttributes.have_reserve_task] is False
        assert self.device.attributes[DeviceAttributes.battery_percent] == 0
        assert self.device.attributes[DeviceAttributes.work_time] == 0
        assert self.device.attributes[DeviceAttributes.uv_switch] is False
        assert self.device.attributes[DeviceAttributes.wifi_switch] is False
        assert self.device.attributes[DeviceAttributes.voice_switch] is False
        assert self.device.attributes[DeviceAttributes.command_source] is False
        assert self.device.attributes[DeviceAttributes.device_error] is False
        assert self.device.attributes[DeviceAttributes.error_type] == "no"
        assert self.device.attributes[DeviceAttributes.error_desc] == "no"
        assert self.device.attributes[DeviceAttributes.mop] == "off"
        assert self.device.attributes[DeviceAttributes.carpet_switch] is False
        assert self.device.attributes[DeviceAttributes.laser_sensor_error] is False
        assert self.device.attributes[DeviceAttributes.laser_sensor_shelter] is False
        assert (
            self.device.attributes[DeviceAttributes.board_communication_error] is False
        )
        assert self.device.attributes[DeviceAttributes.speed] == "low"

    def test_query_response_invalid_values(self) -> None:
        """Test query response."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.query],
        )
        body = bytearray(
            [
                0x32,
                0x1,
                0x13,  # Invalid work status
                0x03,  # Invalid function type
                0x03,  # Invalid control type
                0x05,  # Invalid move direction
                0x0D,  # Invalid clean mode
                0x05,  # Invalid fan level
                0,
                0x04,  # Invalid water level
                0,
                0,
                0,
                0,
                0,
                0x04,  # Invalid error type
                0x04,  # Invalid error description
                0x03,  # Invalid mop state
                0x0,
                0x0,
                0x02,  # Invalid speed
                0x0,  # CRC
            ],
        )
        self.device.process_message(bytes(header + body))
        assert self.device.attributes[DeviceAttributes.work_status] == "none"
        assert self.device.attributes[DeviceAttributes.function_type] == "none"
        assert self.device.attributes[DeviceAttributes.control_type] == "none"
        assert self.device.attributes[DeviceAttributes.move_direction] == "none"
        assert self.device.attributes[DeviceAttributes.clean_mode] == "none"
        assert self.device.attributes[DeviceAttributes.fan_level] == "off"
        assert self.device.attributes[DeviceAttributes.area] == 0
        assert self.device.attributes[DeviceAttributes.water_level] == "off"
        assert self.device.attributes[DeviceAttributes.voice_volume] == 0
        assert self.device.attributes[DeviceAttributes.have_reserve_task] is False
        assert self.device.attributes[DeviceAttributes.battery_percent] == 0
        assert self.device.attributes[DeviceAttributes.work_time] == 0
        assert self.device.attributes[DeviceAttributes.uv_switch] is False
        assert self.device.attributes[DeviceAttributes.wifi_switch] is False
        assert self.device.attributes[DeviceAttributes.voice_switch] is False
        assert self.device.attributes[DeviceAttributes.command_source] is False
        assert self.device.attributes[DeviceAttributes.device_error] is False
        assert self.device.attributes[DeviceAttributes.error_type] == "no"
        assert self.device.attributes[DeviceAttributes.error_desc] == "no"
        assert self.device.attributes[DeviceAttributes.mop] == "lack_water"
        assert self.device.attributes[DeviceAttributes.carpet_switch] is False
        assert self.device.attributes[DeviceAttributes.laser_sensor_error] is False
        assert self.device.attributes[DeviceAttributes.laser_sensor_shelter] is False
        assert (
            self.device.attributes[DeviceAttributes.board_communication_error] is False
        )
        assert self.device.attributes[DeviceAttributes.speed] == "high"

    def test_query_response_invalid_enums_preserve_valid_fields(self) -> None:
        """Test invalid enum fallback does not discard valid scalar/flag fields."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.query],
        )
        body = bytearray(
            [
                0x32,
                0x1,
                0x13,  # Invalid work status
                0x03,  # Invalid function type
                0x03,  # Invalid control type
                0x05,  # Invalid move direction
                0x0D,  # Invalid clean mode
                0x05,  # Invalid fan level
                55,  # area
                0x04,  # Invalid water level
                65,  # voice_volume
                1,  # have_reserve_task
                77,  # battery_percent
                33,  # work_time
                0xC7,  # status flags: uv/wifi/voice/command_source/device_error
                0x04,  # Invalid error type
                0x04,  # Invalid error description
                0x03,  # Invalid mop state
                1,  # carpet_switch
                0x07,  # error flags: laser_sensor_error/shelter/board_communication
                0x02,  # Invalid speed
                0x0,  # CRC
            ],
        )
        self.device.process_message(bytes(header + body))
        assert self.device.attributes[DeviceAttributes.work_status] == "none"
        assert self.device.attributes[DeviceAttributes.function_type] == "none"
        assert self.device.attributes[DeviceAttributes.control_type] == "none"
        assert self.device.attributes[DeviceAttributes.move_direction] == "none"
        assert self.device.attributes[DeviceAttributes.clean_mode] == "none"
        assert self.device.attributes[DeviceAttributes.fan_level] == "off"
        assert self.device.attributes[DeviceAttributes.water_level] == "off"
        assert self.device.attributes[DeviceAttributes.error_type] == "no"
        assert self.device.attributes[DeviceAttributes.error_desc] == "no"
        assert self.device.attributes[DeviceAttributes.mop] == "lack_water"
        assert self.device.attributes[DeviceAttributes.speed] == "high"
        assert self.device.attributes[DeviceAttributes.area] == 55
        assert self.device.attributes[DeviceAttributes.voice_volume] == 65
        assert self.device.attributes[DeviceAttributes.have_reserve_task] is True
        assert self.device.attributes[DeviceAttributes.battery_percent] == 77
        assert self.device.attributes[DeviceAttributes.work_time] == 33
        assert self.device.attributes[DeviceAttributes.uv_switch] is True
        assert self.device.attributes[DeviceAttributes.wifi_switch] is True
        assert self.device.attributes[DeviceAttributes.voice_switch] is True
        assert self.device.attributes[DeviceAttributes.command_source] is True
        assert self.device.attributes[DeviceAttributes.device_error] is True
        assert self.device.attributes[DeviceAttributes.carpet_switch] is True
        assert self.device.attributes[DeviceAttributes.laser_sensor_error] is True
        assert self.device.attributes[DeviceAttributes.laser_sensor_shelter] is True
        assert (
            self.device.attributes[DeviceAttributes.board_communication_error] is True
        )

    def test_unexpected_response(self) -> None:
        """Test unexpected response."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.query],
        )
        body = bytearray(
            [
                0x32,
                0x2,
            ]
            + [0x0] * 20,
        )

        with patch("midealocal.message.MessageResponse.set_attr") as mock_set_attr:
            self.device.process_message(bytes(header + body))

            body = bytearray(
                [
                    0x42,
                    0x1,
                ]
                + [0x0] * 20,
            )
            self.device.process_message(bytes(header + body))
            header[-1] = MessageType.notify1
            body = bytearray([0x32] + [0x0] * 20)
            self.device.process_message(bytes(header + body))
            header[-1] = MessageType.set
            self.device.process_message(bytes(header + body))
            mock_set_attr.assert_not_called()
