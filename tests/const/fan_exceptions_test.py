"""Test per-model fan exceptions."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.fa import MideaFADevice


@pytest.fixture
def device(request: pytest.FixtureRequest) -> MideaFADevice:
    """Fan device of the parametrized model."""
    return MideaFADevice(
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


@pytest.mark.parametrize(
    ("device", "expected_speed_count"),
    [
        pytest.param(
            "default",
            3,
            id="default",
        ),
        pytest.param(
            "560000AG",
            10,
            id="560000AG",
        ),
    ],
    indirect=["device"],
)
def test_speed_count(
    device: MideaFADevice,
    expected_speed_count: int,
) -> None:
    """Test the speed count for each model."""
    assert device.speed_count == expected_speed_count
