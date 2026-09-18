"""Test E2 Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.e2 import (
    DeviceAttributes,
    E2SubType,
    MideaE2Device,
    OldProtocol,
)
from midealocal.devices.e2.message import (
    MessageNewProtocolSet,
    MessagePower,
    MessageQuery,
    MessageSet,
)


class TestMideaE2Device:
    """Test Midea E2 Device."""

    def _device(self, customize: str = "", subtype: int = 1) -> MideaE2Device:
        return MideaE2Device(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.1",
            port=6444,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model="test_model",
            subtype=subtype,
            customize=customize,
        )

    @pytest.mark.parametrize(
        ("customize", "expected_power"),
        [
            ("", 2000),
            ('{"heating_power_multiplier": 0.75}', 1500),
        ],
    )
    def test_process_message_applies_heating_power_multiplier(
        self,
        customize: str,
        expected_power: int,
    ) -> None:
        """E2 heating power can be calibrated while preserving the default."""

        class FakeMessage:
            heating_power = 2000
            error_code = 5
            flow_rate = 12
            bottom_temp = True

        device = self._device(customize)

        with patch(
            "midealocal.devices.e2.MessageE2Response",
            return_value=FakeMessage(),
        ):
            status = device.process_message(b"")

        assert status[DeviceAttributes.heating_power.value] == expected_power
        assert isinstance(status[DeviceAttributes.heating_power.value], int)
        assert device.attributes[DeviceAttributes.heating_power] == expected_power
        assert status[DeviceAttributes.error_code.value] == 5
        assert status[DeviceAttributes.flow_rate.value] == 12
        assert status[DeviceAttributes.bottom_temp.value]
        assert device.attributes[DeviceAttributes.error_code] == 5
        assert device.attributes[DeviceAttributes.flow_rate] == 12
        assert device.attributes[DeviceAttributes.bottom_temp]

    @pytest.mark.parametrize(
        ("customize", "subtype", "raw_value", "expected_temperature"),
        [
            pytest.param("", 1, 80, 40.0, id="half-degree-wire-halves-on-read"),
            pytest.param(
                '{"precision_halves": true}',
                1,
                40,
                40.0,
                id="precision-halves-keeps-raw-value",
            ),
            pytest.param(
                "",
                255,
                45,
                45.0,
                id="literal-subtype-keeps-raw-value",
            ),
        ],
    )
    def test_process_message_target_temperature_round_trips(
        self,
        customize: str,
        subtype: int,
        raw_value: int,
        expected_temperature: float,
    ) -> None:
        """target_temperature must halve on read exactly as it doubles on write.

        Previously the wire value was doubled on write but never halved back
        on read, so a written setpoint could never round-trip.
        """

        class FakeMessage:
            target_temperature = raw_value

        device = self._device(customize, subtype=subtype)

        with patch(
            "midealocal.devices.e2.MessageE2Response",
            return_value=FakeMessage(),
        ):
            status = device.process_message(b"")

        assert status[DeviceAttributes.target_temperature.value] == expected_temperature
        assert (
            device.attributes[DeviceAttributes.target_temperature]
            == expected_temperature
        )

    @pytest.mark.parametrize(
        "customize",
        [
            '{"heating_power_multiplier": "nan"}',
            '{"heating_power_multiplier": "inf"}',
            '{"heating_power_multiplier": "-inf"}',
        ],
    )
    def test_process_message_ignores_non_finite_heating_power_multiplier(
        self,
        customize: str,
    ) -> None:
        """Non-finite multipliers are ignored to keep published values valid."""

        class FakeMessage:
            heating_power = 2000

        device = self._device(customize)

        with patch(
            "midealocal.devices.e2.MessageE2Response",
            return_value=FakeMessage(),
        ):
            status = device.process_message(b"")

        assert status[DeviceAttributes.heating_power.value] == 2000
        assert isinstance(status[DeviceAttributes.heating_power.value], int)
        assert device.attributes[DeviceAttributes.heating_power] == 2000

    def test_default_properties(self) -> None:
        """Test default precision halves and temperature step."""
        device = self._device()
        assert device.precision_halves is False
        assert device.temperature_step == 1.0
        assert device.attributes[DeviceAttributes.temperature_max] == 75.0
        assert device.attributes[DeviceAttributes.temperature_min] == 30.0
        assert device.attributes[DeviceAttributes.error_code] == 0
        assert device.attributes[DeviceAttributes.flow_rate] == 0
        assert not device.attributes[DeviceAttributes.bottom_temp]

    def test_set_customize(self) -> None:
        """Test customize sets old protocol, step and precision halves."""
        device = self._device(
            '{"old_protocol": "false", "temperature_step": 0.5,'
            ' "precision_halves": true}',
        )
        assert device.temperature_step == 0.5
        assert device.precision_halves is True
        assert device._old_protocol == OldProtocol.false

    def test_set_customize_invalid_json(self) -> None:
        """Test invalid customize keeps the defaults."""
        device = self._device("{")
        assert device.precision_halves is False
        assert device.temperature_step == 1.0
        assert device._old_protocol == OldProtocol.auto

    @pytest.mark.parametrize(
        ("value", "subtype", "expected"),
        [
            ("true", 1, OldProtocol.true),
            ("false", 1, OldProtocol.false),
            ("auto", 1, OldProtocol.true),
            ("auto", E2SubType.T85, OldProtocol.true),
            # subtype 100 is neither <= T82 nor in [T85, T36353], so "auto"
            # resolves to OldProtocol.false.
            ("auto", 100, OldProtocol.false),
            (True, 1, OldProtocol.true),
            (False, 1, OldProtocol.false),
            (1, 1, OldProtocol.true),
            (0, 1, OldProtocol.false),
        ],
    )
    def test_normalize_old_protocol(
        self,
        value: str | bool | int,
        subtype: int,
        expected: OldProtocol,
    ) -> None:
        """Test old protocol normalization."""
        device = self._device(subtype=subtype)
        assert device._normalize_old_protocol(value) == expected

    def test_build_query(self) -> None:
        """Test build query."""
        device = self._device()
        queries = device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    def test_make_message_set(self) -> None:
        """Test make message set mirrors the current attributes."""
        device = self._device()
        device._attributes[DeviceAttributes.protection] = True
        device._attributes[DeviceAttributes.whole_tank_heating] = True
        device._attributes[DeviceAttributes.variable_heating] = True
        message = device.make_message_set()
        assert message.protection is True
        assert message.whole_tank_heating is True
        assert message.variable_heating is True
        assert message.target_temperature == 80.0

    def test_set_attribute_old_protocol_reencodes_cached_temperature(self) -> None:
        """An unrelated old-protocol attribute change must re-encode target_temperature.

        Previously ``make_message_set()`` copied the cached, already-halved
        target_temperature straight onto the wire, so setting e.g.
        ``protection`` sent half of the actual target temperature.
        """

        class FakeMessage:
            target_temperature = 80

        device = self._device()
        with patch(
            "midealocal.devices.e2.MessageE2Response",
            return_value=FakeMessage(),
        ):
            device.process_message(b"")
        assert device.attributes[DeviceAttributes.target_temperature] == 40.0

        with patch.object(device, "build_send") as mock_build_send:
            device.set_attribute(DeviceAttributes.protection.value, True)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
        assert isinstance(message, MessageSet)
        assert message.target_temperature == 80

    @pytest.mark.parametrize(
        "attr",
        [
            DeviceAttributes.heating,
            DeviceAttributes.keep_warm,
            DeviceAttributes.current_temperature,
        ],
    )
    def test_set_attribute_read_only(self, attr: DeviceAttributes) -> None:
        """Test read-only attributes do not send a message."""
        device = self._device()
        with patch.object(device, "build_send") as mock_build_send:
            device.set_attribute(attr.value, True)
            mock_build_send.assert_not_called()

    def test_set_attribute_power(self) -> None:
        """Test power sends a power message."""
        device = self._device()
        with patch.object(device, "build_send") as mock_build_send:
            device.set_attribute(DeviceAttributes.power.value, True)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
        assert isinstance(message, MessagePower)
        assert message.power is True

    def test_set_attribute_old_protocol_doubles_temperature(self) -> None:
        """Test old protocol target temperature is doubled without halves."""
        device = self._device()
        with patch.object(device, "build_send") as mock_build_send:
            device.set_attribute(DeviceAttributes.target_temperature.value, 40)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
        assert isinstance(message, MessageSet)
        assert message.target_temperature == 80

    def test_set_attribute_precision_halves_keeps_temperature(self) -> None:
        """Test precision halves keeps the raw target temperature."""
        device = self._device('{"precision_halves": true}')
        with patch.object(device, "build_send") as mock_build_send:
            device.set_attribute(DeviceAttributes.target_temperature.value, 40)
            message = mock_build_send.call_args[0][0]
        assert isinstance(message, MessageSet)
        assert message.target_temperature == 40

    def test_set_attribute_literal_temperature_for_subtype_255(
        self,
    ) -> None:
        """Subtype 255 sends literal Celsius values on the wire."""
        device = self._device(subtype=255)
        with patch.object(device, "build_send") as mock_build_send:
            device.set_attribute(DeviceAttributes.target_temperature.value, 45)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
        assert isinstance(message, MessageNewProtocolSet)
        assert message.target_temperature == 45
        assert message._body == bytearray([0x07, 45])

    def test_set_attribute_old_protocol_ignores_unsupported_attribute(
        self,
        caplog: pytest.LogCaptureFixture,
    ) -> None:
        """MessageSet cannot carry sterilization; the old protocol must warn, not no-op.

        Previously ``setattr(message, "sterilization", value)`` silently
        created an unused instance attribute on ``MessageSet`` and the
        command still went out with no observable effect.
        """
        device = self._device()
        with patch.object(device, "build_send") as mock_build_send:
            device.set_attribute(DeviceAttributes.sterilization.value, True)
            mock_build_send.assert_not_called()
        assert "sterilization" in caplog.text
        assert "old protocol" in caplog.text

    def test_set_attribute_new_protocol(self) -> None:
        """Test new protocol attributes use the new protocol set message."""
        device = self._device('{"old_protocol": "false"}')
        with patch.object(device, "build_send") as mock_build_send:
            device.set_attribute(DeviceAttributes.sterilization.value, True)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
        assert isinstance(message, MessageNewProtocolSet)
        assert message.sterilization is True

    def test_set_attribute_new_protocol_protection(self) -> None:
        """DeviceAttributes.protection must reach MessageNewProtocolSet.protection.

        Previously the message class stored this field as `protect`, so
        setattr(message, "protection", value) silently landed on a new,
        unread instance attribute instead: setting protection was a no-op.
        """
        device = self._device('{"old_protocol": "false"}')
        with patch.object(device, "build_send") as mock_build_send:
            device.set_attribute(DeviceAttributes.protection.value, True)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
        assert isinstance(message, MessageNewProtocolSet)
        assert message.protection is True
        assert message._body == bytearray([0x05, 0x01])
