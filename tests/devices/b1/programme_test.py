"""Test B1 oven programme mapping."""

import pytest

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.devices.b1 import DeviceAttributes, MideaB1Device
from midealocal.devices.b1.message import MessageQueryX31
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


def x31_response(mode: int) -> bytes:
    """Build an X31 response with distinct mode and temperature fields."""
    header = bytearray(
        [0xAA, 0x00, DeviceType.B1] + [0x00] * 5 + [ProtocolVersion.V1],
    ) + bytearray([MessageType.query])
    body = bytearray(20)
    body[0] = 0x31
    body[1] = 0x03
    body[6] = 0x01
    body[7] = 0x02
    body[9] = mode
    body[10] = 0x01
    body[11] = 0x2C
    body[13] = 0x32
    body[18] = 0x01
    body[19] = 0x5E
    return bytes(header + body + bytearray(1))


@pytest.mark.parametrize(
    ("model", "subtype", "mode", "program"),
    [
        ("0TVN50R6", 0, 0x1, "microwave"),
        ("0TVN50R6", 0, 0x2, "brittle"),
        ("0TVN50R6", 0, 0x20, "pure_steam"),
        ("0TVN50R6", 0, 0x21, "hot_steam"),
        ("0TVN50R6", 0, 0x40, "above_tube"),
        ("0TVN50R6", 0, 0x41, "hot_wind_bake"),
        ("0TVN50R6", 0, 0x42, "underside_tube_hot_wind_bake"),
        ("0TVN50R6", 0, 0x44, "cube_baking"),
        ("0TVN50R6", 0, 0x46, "core_baking"),
        ("0TVN50R6", 0, 0x47, "total_baking"),
        ("0TVN50R6", 0, 0x49, "underside_tube"),
        ("0TVN50R6", 0, 0x4C, "double_tube"),
        ("0TVN50R6", 0, 0x4E, "revolve_bake"),
        ("0TVN50R6", 0, 0x51, "double_upside_tube_fan"),
        ("0TVN50R6", 0, 0x52, "double_tube_fan"),
        ("0TVN50R6", 0, 0x70, "fast_baking"),
        ("0TVN50R6", 0, 0x90, "fast_steam"),
        ("0TVN50R6", 0, 0xA0, "unfreeze"),
        ("0TVN50R6", 0, 0xA1, "unfreeze_t"),
        ("0TVN50R6", 0, 0xB0, "zymosis"),
        ("0TVN50R6", 0, 0xC0, "smart_clean"),
        ("0TVN50R6", 0, 0xC1, "scale_clean"),
        ("0TVN50R6", 0, 0xC2, "metal_sterilize"),
        ("0TVN50R6", 0, 0xC3, "remove_odor"),
        ("0TVN50R6", 0, 0xC4, "dry"),
        ("0TVN50R6", 0, 0xD0, "warm"),
        ("0TVN50R6", 0, 0xE0, "auto_menu"),
        ("subtype5_model", 5, 0xD0, "keep_warm"),
        ("subtype5_model", 5, 0x44, "stereo_baking"),
        ("subtype5_model", 5, 0x47, "whole_baking"),
        ("subtype5_model", 5, 0x4C, "up_down_baking"),
        ("subtype5_model", 5, 0xA1, "unfreeze"),
        ("subtype5_model", 5, 0x41, "hot_air_convection"),
        ("subtype5_model", 5, 0x4D, "power_saving"),
        ("subtype5_model", 5, 0x46, "center_baking"),
        ("subtype5_model", 5, 0x4E, "rotary_baking"),
        ("subtype5_model", 5, 0xB0, "fermentation"),
        ("subtype5_model", 5, 0xC4, "stoving"),
        ("subtype5_model", 5, 0x49, "down_baking"),
        ("subtype5_model", 5, 0xB1, "pizza"),
        ("subtype5_model", 5, 0x51, "up_infrared_fan"),
    ],
)
def test_lua_program_mapping(
    model: str,
    subtype: int,
    mode: int,
    program: str,
) -> None:
    """Map X31 programme codes using each Lua file's device scope."""
    device = make_device(model, subtype)
    updates = device.process_message(x31_response(mode))

    assert device.attributes[DeviceAttributes.mode] == mode
    assert device.attributes[DeviceAttributes.program] == program
    assert updates["program"] == program
    assert device.attributes[DeviceAttributes.time_remaining] == 62
    if model == "0TVN50R6":
        assert device.attributes[DeviceAttributes.current_temperature] == 50
        assert device.attributes[DeviceAttributes.target_temperature] == 94
    else:
        assert device.attributes[DeviceAttributes.current_temperature] == 300
        assert device.attributes[DeviceAttributes.target_temperature] == 350


@pytest.mark.parametrize(
    ("model", "subtype", "query_body"),
    [
        ("0TVN50R6", 0, bytearray([0x31, 0x00])),
        ("subtype5_model", 5, bytearray([0x31])),
    ],
)
def test_lua_query(model: str, subtype: int, query_body: bytearray) -> None:
    """Use the X31 request body documented by the applicable Lua file."""
    queries = make_device(model, subtype).build_query()

    assert len(queries) == 1
    assert isinstance(queries[0], MessageQueryX31)
    assert queries[0].body == query_body


@pytest.mark.parametrize(
    ("model", "subtype"),
    [("711001F5", 0), ("other_model", 0), ("other_model", 4)],
)
def test_x31_other_devices(model: str, subtype: int) -> None:
    """Do not infer an X31 programme for an unidentified protocol."""
    device = make_device(model, subtype)
    updates = device.process_message(x31_response(0x52))

    assert device.attributes[DeviceAttributes.program] is None
    assert "program" not in updates


@pytest.mark.parametrize(
    ("model", "subtype", "known_mode"),
    [("0TVN50R6", 0, 0x52), ("subtype5_model", 5, 0x51)],
)
def test_x31_unknown_clears_program(
    model: str,
    subtype: int,
    known_mode: int,
) -> None:
    """Clear a previously named programme when X31 reports an unknown code."""
    device = make_device(model, subtype)
    device.process_message(x31_response(known_mode))
    assert device.attributes[DeviceAttributes.program] is not None

    updates = device.process_message(x31_response(0xFF))

    assert device.attributes[DeviceAttributes.mode] == 0xFF
    assert device.attributes[DeviceAttributes.program] is None
    assert updates["program"] is None


@pytest.mark.parametrize(
    ("model", "subtype"),
    [("0TVN50R6", 0), ("subtype5_model", 5)],
)
def test_x31_short_body(model: str, subtype: int) -> None:
    """Ignore truncated X31 responses without changing device attributes."""
    response = x31_response(0x51)
    truncated = response[:-2] + response[-1:]
    device = make_device(model, subtype)

    assert device.process_message(truncated) == {}


def test_x31_model_takes_precedence() -> None:
    """Use the named model's Lua table before a generic subtype mapping."""
    device = make_device("0TVN50R6", 5)

    updates = device.process_message(x31_response(0x41))

    assert updates["program"] == "hot_wind_bake"
    assert device.build_query()[0].body == bytearray([0x31, 0x00])


@pytest.mark.parametrize(
    ("model", "subtype"),
    [("0TVN50R6", 0), ("subtype5_model", 5)],
)
def test_x01_not_named_by_x31_tables(model: str, subtype: int) -> None:
    """Keep X31 programme tables separate from the physical oven's X01 layout."""
    device = make_device(model, subtype)

    updates = device.process_message(x01_response(0x52, 1))

    assert updates["program"] is None
