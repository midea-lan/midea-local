"""Test BF Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.bf import DeviceAttributes, MideaBFDevice
from midealocal.devices.bf.message import (
    MessageQuery,
    WorkStatus,
)
from midealocal.exceptions import SocketException
from midealocal.message import ListTypes, MessageType


def _build_device() -> MideaBFDevice:
    """Build a Midea BF device."""
    return MideaBFDevice(
        name="Test BF Device",
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


def _build_message(message_type: MessageType, body: bytearray) -> bytes:
    """Build a full BF response message."""
    header = bytearray(
        [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
    )
    return bytes(header + body + bytearray([0x00]))


class TestMideaBFDevice:
    """Test Midea BF Device."""

    device: MideaBFDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea BF Device setup."""
        self.device = _build_device()

    def test_initial_attributes_all_none(self) -> None:
        """Test all initial attributes are None."""
        for attr in DeviceAttributes:
            assert self.device.attributes[attr] is None

    def test_build_query(self) -> None:
        """Test build query returns one MessageQuery."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    def test_process_message_basic(self) -> None:
        """Test process message with a basic totalState body."""
        body = bytearray(60)
        body[0] = 0x01  # body_type totalState
        body[31] = WorkStatus.standby.value
        new_status = self.device.process_message(
            _build_message(MessageType.query, body),
        )
        assert self.device.attributes[DeviceAttributes.status] == "standby"
        assert self.device.attributes[DeviceAttributes.power] is True
        assert DeviceAttributes.status.value in new_status
        assert new_status[DeviceAttributes.status.value] == "standby"

    def test_process_message_save_power(self) -> None:
        """Test process message with save_power status -> power=False."""
        body = bytearray(60)
        body[0] = 0x01
        body[31] = WorkStatus.save_power.value
        self.device.process_message(
            _build_message(MessageType.query, body),
        )
        assert self.device.attributes[DeviceAttributes.power] is False
        assert self.device.attributes[DeviceAttributes.status] == "save_power"

    def test_process_message_all_flags(self) -> None:
        """Test process message with all byte32/33 flags set."""
        body = bytearray(60)
        body[0] = 0x01
        body[31] = WorkStatus.work.value
        body[32] = 0xBF  # all byte32 flags
        body[33] = 0x7F  # all byte33 flags
        body[35] = 0x20  # hot_wind
        body[56] = 0xC0  # clean_scale + ota
        body[58] = 0x03  # clean_sink_ponding + dissipate_heat
        self.device.process_message(
            _build_message(MessageType.set, body),
        )
        assert self.device.attributes[DeviceAttributes.child_lock] is True
        assert self.device.attributes[DeviceAttributes.door] is True
        assert self.device.attributes[DeviceAttributes.tank_ejected] is True
        assert self.device.attributes[DeviceAttributes.water_shortage] is True
        assert self.device.attributes[DeviceAttributes.water_change_reminder] is True
        assert self.device.attributes[DeviceAttributes.error_code] is True
        assert self.device.attributes[DeviceAttributes.pre_heat] is True
        assert self.device.attributes[DeviceAttributes.flip_side] is True
        assert self.device.attributes[DeviceAttributes.reaction] is True
        assert self.device.attributes[DeviceAttributes.furnace_light] is True
        assert self.device.attributes[DeviceAttributes.hot_wind] is True
        assert self.device.attributes[DeviceAttributes.clean_scale] is True
        assert self.device.attributes[DeviceAttributes.ota] is True
        assert self.device.attributes[DeviceAttributes.clean_sink_ponding] is True
        assert self.device.attributes[DeviceAttributes.dissipate_heat] is True

    def test_process_message_temperatures(self) -> None:
        """Test process message with temperature values."""
        body = bytearray(60)
        body[0] = 0x01
        body[31] = WorkStatus.work.value
        body[13] = 0x00  # temp_above_high
        body[14] = 200  # temp_above_low
        body[15] = 0x00  # temp_underside_high
        body[16] = 180  # temp_underside_low
        body[25] = 0x00  # cur_temp_above_high
        body[26] = 180  # cur_temp_above_low
        self.device.process_message(
            _build_message(MessageType.query, body),
        )
        assert self.device.attributes[DeviceAttributes.temperature] == 200
        assert self.device.attributes[DeviceAttributes.temperature_above] == 200
        assert self.device.attributes[DeviceAttributes.temperature_underside] == 180
        assert self.device.attributes[DeviceAttributes.current_temperature] == 180

    def test_process_message_time_remaining(self) -> None:
        """Test process message with work time and time_remaining."""
        body = bytearray(60)
        body[0] = 0x01
        body[31] = WorkStatus.work.value
        body[22] = 1  # work_hour
        body[23] = 30  # work_minute
        body[24] = 0  # work_second
        self.device.process_message(
            _build_message(MessageType.query, body),
        )
        assert self.device.attributes[DeviceAttributes.time_remaining] == 90

    def test_process_message_work_mode(self) -> None:
        """Test process message with work_mode."""
        body = bytearray(60)
        body[0] = 0x01
        body[31] = WorkStatus.work.value
        body[7] = 0x01  # microwave high
        body[8] = 0x00  # microwave low
        self.device.process_message(
            _build_message(MessageType.query, body),
        )
        assert self.device.attributes[DeviceAttributes.work_mode] == "microwave"

    def test_process_message_fire_power(self) -> None:
        """Test process message with fire_power."""
        body = bytearray(60)
        body[0] = 0x01
        body[31] = WorkStatus.work.value
        body[12] = 0x05  # fire_power_5
        self.device.process_message(
            _build_message(MessageType.query, body),
        )
        assert self.device.attributes[DeviceAttributes.fire_power] == "fire_power_5"

    def test_process_message_steam_weight(self) -> None:
        """Test process message with steam and weight."""
        body = bytearray(60)
        body[0] = 0x01
        body[31] = WorkStatus.work.value
        body[19] = 5  # steam_quantity
        body[20] = 50  # weight/people: 50*10=500
        self.device.process_message(
            _build_message(MessageType.query, body),
        )
        assert self.device.attributes[DeviceAttributes.steam_quantity] == 5
        assert self.device.attributes[DeviceAttributes.weight] == 500
        assert self.device.attributes[DeviceAttributes.people_number] == 50

    def test_process_message_cbs_version(self) -> None:
        """Test process message with cbs_version."""
        body = bytearray(60)
        body[0] = 0x01
        body[31] = WorkStatus.work.value
        body[47] = 1
        body[48] = 2
        body[49] = 3
        self.device.process_message(
            _build_message(MessageType.query, body),
        )
        assert self.device.attributes[DeviceAttributes.cbs_version] == "V1.2.3"

    def test_process_message_maintenance_flags(self) -> None:
        """Test process message with clean_scale, ota, etc."""
        body = bytearray(60)
        body[0] = 0x01
        body[31] = WorkStatus.work.value
        body[56] = 0xC0  # clean_scale + ota
        body[58] = 0x03  # clean_sink_ponding + dissipate_heat
        self.device.process_message(
            _build_message(MessageType.query, body),
        )
        assert self.device.attributes[DeviceAttributes.clean_scale] is True
        assert self.device.attributes[DeviceAttributes.ota] is True
        assert self.device.attributes[DeviceAttributes.clean_sink_ponding] is True
        assert self.device.attributes[DeviceAttributes.dissipate_heat] is True

    def _activate_work_mode(self) -> None:
        """Process a message that puts the device into an active work_mode."""
        body = bytearray(60)
        body[0] = 0x01
        body[31] = WorkStatus.work.value
        body[7] = 0x01  # microwave high
        body[8] = 0x00  # microwave low
        self.device.process_message(_build_message(MessageType.query, body))

    @pytest.mark.parametrize(
        ("attr", "value"),
        [
            pytest.param(DeviceAttributes.power, True, id="power"),
            pytest.param(DeviceAttributes.child_lock, True, id="child_lock"),
            pytest.param(DeviceAttributes.furnace_light, True, id="furnace_light"),
            pytest.param(DeviceAttributes.hot_wind, True, id="hot_wind"),
            pytest.param(DeviceAttributes.door, True, id="door"),
            pytest.param(DeviceAttributes.work_mode, "microwave", id="work_mode"),
            pytest.param(DeviceAttributes.status, "standby", id="status"),
            pytest.param(DeviceAttributes.hour_set, 1, id="hour_set"),
            pytest.param(DeviceAttributes.minute_set, 30, id="minute_set"),
            pytest.param(DeviceAttributes.second_set, 0, id="second_set"),
        ],
    )
    def test_set_attribute_raises_socket_exception(
        self,
        attr: str,
        value: bool | str | int,
    ) -> None:
        """Test set_attribute attempts to send and raises (no socket).

        Local state is not updated since sending fails.
        """
        with pytest.raises(SocketException):
            self.device.set_attribute(attr, value)
        assert self.device.attributes[attr] is None

    @pytest.mark.parametrize(
        ("attr", "value"),
        [
            pytest.param(DeviceAttributes.fire_power, "fire_power_5", id="fire_power"),
            pytest.param(DeviceAttributes.temperature, 200, id="temperature"),
        ],
    )
    def test_set_attribute_work_mode_only_without_active_work_mode(
        self,
        attr: str,
        value: str | int,
    ) -> None:
        """Test work-mode-only attributes require an active work_mode to serialize."""
        with pytest.raises(ValueError, match="no control fields"):
            self.device.set_attribute(attr, value)
        assert self.device.attributes[attr] is None

    @pytest.mark.parametrize(
        ("attr", "value"),
        [
            pytest.param(DeviceAttributes.fire_power, "fire_power_5", id="fire_power"),
            pytest.param(DeviceAttributes.temperature, 200, id="temperature"),
        ],
    )
    def test_set_attribute_work_mode_only_with_active_work_mode(
        self,
        attr: str,
        value: str | int,
    ) -> None:
        """Test work-mode-only attributes route via make_message_set once active."""
        self._activate_work_mode()
        with pytest.raises(SocketException):
            self.device.set_attribute(attr, value)

    def test_set_attribute_hot_wind_with_active_work_mode(self) -> None:
        """Test standalone hot_wind still routes via notWorkModeControl.

        Regression test: hot_wind must not be treated as a work-mode-context
        attribute, since make_message_set() would otherwise carry the current
        work_mode and misroute a standalone hot_wind write to workModeControl.
        """
        self._activate_work_mode()
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.hot_wind, True)
            mock_build_send.assert_called_once()
            sent_message = mock_build_send.call_args[0][0]
            assert sent_message.body[0] == ListTypes.X02

    def test_set_attribute_status_invalid_type(self) -> None:
        """Test set_attribute with status as non-string logs warning and returns."""
        # This should not crash, just log a warning and return early
        self.device.set_attribute(DeviceAttributes.status, 42)
        assert self.device.attributes[DeviceAttributes.status] is None

    def test_set_attribute_unsupported_attribute(self) -> None:
        """Test set_attribute with unsupported attribute logs warning."""
        # Attributes not in _SETTABLE_ATTRS and not status should be ignored
        self.device.set_attribute(DeviceAttributes.time_remaining, 3600)
        assert self.device.attributes[DeviceAttributes.time_remaining] is None

    def test_process_message_updates_returned_dict(self) -> None:
        """Test process_message returns a dict of updated attributes."""
        body = bytearray(60)
        body[0] = 0x01
        body[31] = WorkStatus.standby.value
        new_status = self.device.process_message(
            _build_message(MessageType.query, body),
        )
        assert isinstance(new_status, dict)
        # All attributes that MessageBFBody provides should be in new_status
        assert DeviceAttributes.status.value in new_status
        assert DeviceAttributes.power.value in new_status

    def test_process_message_notify_type(self) -> None:
        """Test process_message with notify1 message type."""
        body = bytearray(60)
        body[0] = 0x01
        body[31] = WorkStatus.work.value
        self.device.process_message(
            _build_message(MessageType.notify1, body),
        )
        assert self.device.attributes[DeviceAttributes.status] == "work"

    def test_process_message_non_total_state(self) -> None:
        """Test process_message with non-totalState body_type."""
        body = bytearray(10)
        body[0] = 0x02  # not totalState (0x01)
        new_status = self.device.process_message(
            _build_message(MessageType.query, body),
        )
        # No BF-specific attributes should be parsed
        assert self.device.attributes[DeviceAttributes.status] is None
        assert DeviceAttributes.status.value not in new_status
