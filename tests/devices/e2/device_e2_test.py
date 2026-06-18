"""Test E2 Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.e2 import DeviceAttributes, MideaE2Device


class TestMideaE2Device:
    """Test Midea E2 Device."""

    def _device(self, customize: str = "") -> MideaE2Device:
        return MideaE2Device(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.1",
            port=6444,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model="test_model",
            subtype=1,
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

        device = self._device(customize)

        with patch(
            "midealocal.devices.e2.MessageE2Response",
            return_value=FakeMessage(),
        ):
            status = device.process_message(b"")

        assert status[DeviceAttributes.heating_power.value] == expected_power
        assert isinstance(status[DeviceAttributes.heating_power.value], int)
        assert device.attributes[DeviceAttributes.heating_power] == expected_power

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
