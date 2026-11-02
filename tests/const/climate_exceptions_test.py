"""Test per-model climate exceptions."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.ac import DeviceAttributes, MideaACDevice
from midealocal.message import MessageBase, MessageChecksum

# C1 power data captured from a 00000Q11 split unit (#997).
_Q11_ENERGY_DATA = bytearray.fromhex("00001e56 00000000 00000000 000050 0001da")


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
        pytest.param("00000Q11", _Q11_ENERGY_DATA, 77.66, 8.0, id="00000Q11"),
        pytest.param(
            "00000Q16",
            bytearray.fromhex("0000012c 00000000 00000000 0005dc"),
            3.0,
            150.0,
            id="00000Q16",
        ),
        pytest.param("test_model", _Q11_ENERGY_DATA, 24.56, 5.0, id="default"),
    ],
    indirect=["device"],
)
def test_power_analysis_method_exception(
    device: MideaACDevice,
    energy_data: bytearray,
    expected_energy: float,
    expected_power: float,
) -> None:
    """Test the power format each model decodes with (BCD by default)."""
    device.process_message(_c1_power_response(energy_data))

    assert device.attributes[DeviceAttributes.total_energy_consumption] == (
        expected_energy
    )
    assert device.attributes[DeviceAttributes.realtime_power] == expected_power


@pytest.mark.parametrize(
    ("device", "expected"),
    [
        pytest.param("00000Q18", 1.0, id="00000Q18"),
        pytest.param("test_model", 0.5, id="default"),
    ],
    indirect=["device"],
)
def test_temperature_step_exception(device: MideaACDevice, expected: float) -> None:
    """Test the setpoint step of each model (0.5 by default)."""
    assert device.temperature_step == expected
