"""Test CF Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.cf import DeviceAttributes, MideaCFDevice
from midealocal.devices.cf.message import MessageQuery, MessageSet
from midealocal.exceptions import ValueWrongType
from midealocal.message import MessageType


class TestMideaCFDevice:
    """Test Midea CF Device."""

    device: MideaCFDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea CF Device setup."""
        self.device = MideaCFDevice(
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
        assert self.device.attributes[DeviceAttributes.mode] == 0
        assert self.device.attributes[DeviceAttributes.target_temperature] is None
        assert self.device.attributes[DeviceAttributes.aux_heating] is False
        assert self.device.attributes[DeviceAttributes.current_temperature] == 0
        assert self.device.attributes[DeviceAttributes.max_temperature] == 55
        assert self.device.attributes[DeviceAttributes.min_temperature] == 5
        assert self.device.attributes[DeviceAttributes.defrost] is False
        assert self.device.attributes[DeviceAttributes.freeze] is False

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    @pytest.mark.parametrize(
        "message_type",
        [MessageType.query, MessageType.set],
    )
    def test_query_set_response_heat_mode(self, message_type: MessageType) -> None:
        """Test query/set response with heat mode and offset 1."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
        )
        body = bytearray(12)
        body[0] = 0x01  # Body type
        body[1] = 0x03  # power + aux_heating
        body[3] = 0x60  # defrost + freeze
        body[4] = 0x03  # mode heat
        body[5] = 45  # target temperature
        body[6] = 40  # current temperature
        body[7] = 55  # heat max temperature
        body[8] = 20  # heat min temperature
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.aux_heating] is True
        assert self.device.attributes[DeviceAttributes.defrost] is True
        assert self.device.attributes[DeviceAttributes.freeze] is True
        assert self.device.attributes[DeviceAttributes.mode] == 3
        assert self.device.attributes[DeviceAttributes.target_temperature] == 45
        assert self.device.attributes[DeviceAttributes.current_temperature] == 40
        assert self.device.attributes[DeviceAttributes.max_temperature] == 55
        assert self.device.attributes[DeviceAttributes.min_temperature] == 20

    def test_query_response_cool_mode(self) -> None:
        """Test query response with cool mode temperature range."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.query],
        )
        body = bytearray(12)
        body[0] = 0x01  # Body type
        body[4] = 0x02  # mode cool
        body[9] = 17  # cool max temperature
        body[10] = 5  # cool min temperature
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.power] is False
        assert self.device.attributes[DeviceAttributes.aux_heating] is False
        assert self.device.attributes[DeviceAttributes.defrost] is False
        assert self.device.attributes[DeviceAttributes.freeze] is False
        assert self.device.attributes[DeviceAttributes.mode] == 2
        assert self.device.attributes[DeviceAttributes.max_temperature] == 17
        assert self.device.attributes[DeviceAttributes.min_temperature] == 5

    @pytest.mark.parametrize(
        "message_type",
        [MessageType.notify1, MessageType.notify2],
    )
    def test_notify_response_auto_mode(self, message_type: MessageType) -> None:
        """Test notify response with auto mode and offset 0."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
        )
        body = bytearray(11)
        body[0] = 0x01  # Body type and power flags
        body[3] = 0x01  # mode auto
        body[4] = 30  # target temperature
        body[5] = 25  # current temperature
        body[6] = 50  # heat max temperature
        body[9] = 8  # cool min temperature
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.mode] == 1
        assert self.device.attributes[DeviceAttributes.target_temperature] == 30
        assert self.device.attributes[DeviceAttributes.current_temperature] == 25
        assert self.device.attributes[DeviceAttributes.max_temperature] == 50
        assert self.device.attributes[DeviceAttributes.min_temperature] == 8

    def test_unexpected_response(self) -> None:
        """Test query response with unexpected body type updates no attribute."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.query],
        )
        body = bytearray(12)
        body[0] = 0x02  # unexpected body type
        crc = bytearray([0x00])
        new_status = self.device.process_message(bytes(header + body + crc))
        assert new_status == {}

    def test_set_target_temperature(self) -> None:
        """Test set target temperature with and without mode."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_target_temperature(25, None)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.power is True
            assert message.mode == 0
            assert message.target_temperature == 25
            mock_build_send.reset_mock()

            self.device.set_target_temperature(30, 2, 1)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.mode == 2
            assert message.target_temperature == 30

    @pytest.mark.parametrize(
        ("attr", "value", "expected"),
        [
            (DeviceAttributes.power, True, True),
            (DeviceAttributes.mode, 2, 2),
            (DeviceAttributes.mode, "2", 2),
            (DeviceAttributes.target_temperature, 30, 30.0),
            (DeviceAttributes.aux_heating, True, True),
        ],
    )
    def test_set_attribute(
        self,
        attr: DeviceAttributes,
        value: bool | int | str,
        expected: bool | float,
    ) -> None:
        """Test set attribute sends a set message with the converted value."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(attr.value, value)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            actual = getattr(message, attr.value)
            assert actual == expected
            assert type(actual) is type(expected)

    @pytest.mark.parametrize(
        ("attr", "value"),
        [
            (DeviceAttributes.power, 5),
            (DeviceAttributes.aux_heating, 5),
            (DeviceAttributes.mode, True),
            (DeviceAttributes.target_temperature, True),
            (DeviceAttributes.mode, 2.5),
            (DeviceAttributes.target_temperature, float("inf")),
            (DeviceAttributes.target_temperature, float("nan")),
            (DeviceAttributes.mode, "abc"),
            (DeviceAttributes.target_temperature, "abc"),
            (DeviceAttributes.mode, None),
            (DeviceAttributes.target_temperature, None),
        ],
    )
    def test_set_attribute_wrong_type(
        self,
        attr: DeviceAttributes,
        value: bool | float | str | None,
    ) -> None:
        """Test set attribute with a wrong-type value raises and does not send."""
        with (
            patch.object(self.device, "build_send") as mock_build_send,
            pytest.raises(ValueWrongType),
        ):
            self.device.set_attribute(attr.value, value)  # type: ignore[arg-type]
        mock_build_send.assert_not_called()

    def test_set_attribute_unsupported(self) -> None:
        """Test set attribute with an unsupported attribute raises and does not send."""
        with (
            patch.object(self.device, "build_send") as mock_build_send,
            pytest.raises(ValueError, match="Unsupported attribute"),
        ):
            self.device.set_attribute(DeviceAttributes.current_temperature.value, 5)
        mock_build_send.assert_not_called()

    def test_hvac_modes(self) -> None:
        """Test hvac_modes lists every generic HVAC mode name."""
        assert self.device.hvac_modes == ["off", "auto", "cool", "heat"]

    @pytest.mark.parametrize(
        ("power", "mode", "expected"),
        [
            (True, 1, "auto"),
            (True, 3, "heat"),
            (False, 1, "off"),
            (True, 999, None),
            (True, 0, None),
            ("not_a_bool", 1, None),
            (True, "not_an_int", None),
        ],
    )
    def test_hvac_mode(
        self,
        power: bool | str,
        mode: int | str,
        expected: str | None,
    ) -> None:
        """Test hvac_mode across power/mode edge cases."""
        self.device._attributes[DeviceAttributes.power] = power
        self.device._attributes[DeviceAttributes.mode] = mode
        assert self.device.hvac_mode() == expected

    def test_set_hvac_mode_off_powers_off(self) -> None:
        """Test set_hvac_mode with off powers the device off."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_hvac_mode("off")
            message = mock_build_send.call_args[0][0]
            assert message.power is False

    def test_set_hvac_mode_uses_current_target_temperature(self) -> None:
        """Test set_hvac_mode carries the current target_temperature."""
        self.device._attributes[DeviceAttributes.target_temperature] = 22.0
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_hvac_mode("heat")
            message = mock_build_send.call_args[0][0]
            assert message.mode == 3
            assert message.target_temperature == 22.0

    def test_set_hvac_mode_falls_back_to_min_temperature(self) -> None:
        """Test set_hvac_mode falls back to min_temperature when unset."""
        assert self.device._attributes[DeviceAttributes.target_temperature] is None
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_hvac_mode("heat")
            message = mock_build_send.call_args[0][0]
            assert message.target_temperature == 5

    def test_set_hvac_mode_unsupported_value_raises(self) -> None:
        """Test set_hvac_mode raises for a mode not in hvac_modes."""
        with (
            patch.object(self.device, "build_send") as mock_build_send,
            pytest.raises(ValueError, match="Unsupported hvac mode"),
        ):
            self.device.set_hvac_mode("not_a_real_mode")
        mock_build_send.assert_not_called()
