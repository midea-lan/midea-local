"""Test B1 oven programme mapping."""

import pytest

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.devices.b1 import DeviceAttributes, MideaB1Device
from midealocal.message import MessageType


def make_device(model: str = "711001F5", subtype: int = 0) -> MideaB1Device:
    """Create a B1 oven for programme mapping tests."""
    return MideaB1Device(
        name="Test Oven",
        device_id=1,
        ip_address="192.168.1.1",
        port=12345,
        token="AA",
        key="BB",
        device_protocol=ProtocolVersion.V1,
        model=model,
        subtype=subtype,
        customize="",
    )


def x01_response(mode: int, variant: int) -> bytes:
    """Build an X01 response containing a mode and programme variant."""
    header = bytearray(
        [0xAA, 0x00, DeviceType.B1] + [0x00] * 5 + [ProtocolVersion.V1],
    ) + bytearray([MessageType.query])
    body = bytearray(33)
    body[0] = 0x01
    body[7] = mode
    body[8] = variant
    body[31] = 0x03
    return bytes(header + body + bytearray(1))


@pytest.mark.parametrize(
    ("mode", "variant", "program"),
    [
        (83, 1, "conventional"),
        (84, 1, "convection"),
        (95, 0, "conventional_fan"),
        (102, 0, "radiant_heat"),
        (99, 0, "double_grill_fan"),
        (103, 0, "double_grill"),
        (87, 0, "pizza"),
        (82, 1, "bottom_heat"),
        (162, 0, "eco"),
        (94, 0, "keep_warm"),
        (164, 0, "defrost"),
        (88, 0, "fermentation"),
        (83, 9, "aqua_clean"),
        (95, 1, "air_baking"),
    ],
)
def test_program_mapping(mode: int, variant: int, program: str) -> None:
    """Map each observed mode and variant to its programme name."""
    device = make_device()
    updates = device.process_message(x01_response(mode, variant))

    assert device.attributes[DeviceAttributes.mode] == mode
    assert device.attributes[DeviceAttributes.program] == program
    assert updates["program"] == program


@pytest.mark.parametrize(
    ("model", "subtype", "mode", "variant"),
    [
        ("711001F5", 0, 83, 2),
        ("711001F5", 0, 0, 0),
        ("711001CJ", 0, 83, 1),
        ("711001F5", 1, 83, 1),
    ],
)
def test_unmapped_program(
    model: str,
    subtype: int,
    mode: int,
    variant: int,
) -> None:
    """Leave unknown combinations and other device variants unnamed."""
    device = make_device(model, subtype)
    updates = device.process_message(x01_response(mode, variant))

    assert device.attributes[DeviceAttributes.mode] == mode
    assert device.attributes[DeviceAttributes.program] is None
    assert updates["program"] is None
