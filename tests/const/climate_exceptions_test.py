"""Test per-model climate exceptions."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.ac import DeviceAttributes, MideaACDevice
from midealocal.message import MessageBase, MessageChecksum


@pytest.fixture
def device(request: pytest.FixtureRequest) -> MideaACDevice:
    """AC device of the parametrized model."""
    return MideaACDevice(
        name="Test Device",
        device_id=1,
        ip_address="192.168.1.1",
        port=12345,
        token="AA",
        key="BB",
        device_protocol=ProtocolVersion.V3,
        model=request.param,
        subtype=1,
    )


def _c1_power_response(energy_data: bytearray) -> bytes:
    """Wrap C1 0x44 energy data in a complete query frame.

    The data holds three 4-byte energy counters, then 3 bytes of realtime power.
    """
    body = bytearray([0xC1, 0x21, 0x01, 0x44]) + energy_data
    header = bytearray([0xAA, 0, 0xAC, 0, 0, 0, 0, 0, 1, 3])
    header[1] = len(header) + len(body)
    frame = header + body
    frame.extend(MessageBase.checksum(frame[1:], MessageChecksum.SUM))
    return bytes(frame)


@pytest.mark.parametrize(
    ("device", "energy_data", "expected_energy", "expected_power"),
    [
        # Rebuilt from a 00000Q11 split unit's readings (#997): 24.55 kWh, 4.6 W as BCD.
        pytest.param(
            "00000Q11",
            bytearray.fromhex("00001e4f 00000000 00000000 000046"),
            77.59,
            7.0,
            id="00000Q11",
        ),
        pytest.param(
            "00000Q16",
            bytearray.fromhex("0000012c 00000000 00000000 0005dc"),
            3.0,
            150.0,
            id="00000Q16",
        ),
    ],
    indirect=["device"],
)
def test_power_analysis_method_exception(
    device: MideaACDevice,
    energy_data: bytearray,
    expected_energy: float,
    expected_power: float,
) -> None:
    """Test models whose power and energy are binary decode them as binary."""
    device.process_message(_c1_power_response(energy_data))

    assert device.attributes[DeviceAttributes.total_energy_consumption] == (
        expected_energy
    )
    assert device.attributes[DeviceAttributes.realtime_power] == expected_power


@pytest.mark.parametrize(
    ("device", "expected"),
    [pytest.param("00000Q18", 1.0, id="00000Q18")],
    indirect=["device"],
)
def test_temperature_step_exception(device: MideaACDevice, expected: float) -> None:
    """Test models with a whole-degree setpoint step."""
    assert device.temperature_step == expected
