"""DB_33 options captured on model 38131408 / subtype 13146."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.db import DeviceAttributes, MideaDBDevice
from midealocal.devices.db.message import MessageSet
from midealocal.exceptions import ValueWrongType
from midealocal.message import MessageType


def make_device(model: str = "38131408", subtype: int = 13146) -> MideaDBDevice:
    """Construct a device without opening a network connection."""
    return MideaDBDevice(
        name="Test",
        device_id=1,
        ip_address="192.168.1.1",
        port=6444,
        token="AA",
        key="BB",
        device_protocol=ProtocolVersion.V1,
        model=model,
        subtype=subtype,
        customize="",
    )


def response(
    *,
    dryer: int = 0,
    flags: int = 0,
    soak: int = 0,
    wash_level: int = 0,
    wash_minutes: int = 25,
    spin_level: int = 2,
    spin_minutes: int = 8,
    message_type: MessageType = MessageType.query,
) -> bytes:
    """Build a standby mixed-wash response with independent level/minute fields."""
    body = bytearray(31)
    body[0] = 0x04 if message_type == MessageType.notify1 else 0x03
    body[1:5] = bytearray([1, 1, 0, 3])
    body[6] = 0x20 | dryer
    body[9] = wash_level
    body[10] = spin_level
    body[25] = flags
    body[27] = wash_minutes
    body[28] = spin_minutes
    body[29] = soak
    header = bytearray([0xAA] + [0] * 7 + [ProtocolVersion.V1, message_type])
    return bytes(header + body + bytearray([0]))


@pytest.mark.parametrize("subtype", [0, 13146])
@pytest.mark.parametrize(
    ("code", "label"),
    [
        (0, "off"),
        (1, "auto"),
        (3, "low_temperature"),
        (4, "30"),
        (5, "60"),
        (6, "90"),
        (7, "120"),
        (11, "180"),
    ],
)
def test_dryer_panel_mapping(subtype: int, code: int, label: str) -> None:
    """All eight panel choices use their captured codes, including 180 -> 11."""
    device = make_device(subtype=subtype)
    assert device.attributes[DeviceAttributes.dryer] is None
    device.process_message(response(dryer=code))
    assert device.attributes[DeviceAttributes.dryer] == label
    before = device.attributes.copy()
    with patch.object(device, "build_send") as send:
        device.set_attribute(DeviceAttributes.dryer, label)
    send.assert_called_once()
    message = send.call_args.args[0]
    assert isinstance(message, MessageSet)
    expected = bytearray([0x02] + [0xFF] * 21)
    expected[6] = 0xF0 | code  # Leave soak_count (high nibble) unchanged.
    assert message.body == expected
    assert device.attributes == before


@pytest.mark.parametrize(
    "value", [True, False, 0, 30, 30.5, "2", "8", "150", "default"]
)
def test_invalid_dryer(value: bool | float | str) -> None:
    """Unobserved codes and invalid labels cannot become writable choices."""
    device = make_device()
    with patch.object(device, "build_send") as send, pytest.raises(ValueWrongType):
        device.set_attribute(DeviceAttributes.dryer, value)
    send.assert_not_called()


@pytest.mark.parametrize("flags", [0x00, 0x10, 0x20, 0x30, 0xCF, 0xFF])
@pytest.mark.parametrize("soak", [0, 1])
@pytest.mark.parametrize(
    "message_type", [MessageType.query, MessageType.set, MessageType.notify1]
)
def test_option_reading(flags: int, soak: int, message_type: MessageType) -> None:
    """Control soak uses response byte 29, not disinfectant/oxygen bits 6/7."""
    device = make_device()
    device.process_message(response(flags=flags, soak=soak, message_type=message_type))
    assert device.attributes[DeviceAttributes.steam_wash] is bool(flags & 0x10)
    assert device.attributes[DeviceAttributes.fast_clean_wash] is bool(flags & 0x20)
    assert device._control_options == (flags & 0x3F) | (soak << 6)


@pytest.mark.parametrize("subtype", [0, 13146])
@pytest.mark.parametrize("flags", [0x0F, 0x10, 0x20, 0x30, 0xC0, 0xFF])
@pytest.mark.parametrize("soak", [0, 1])
@pytest.mark.parametrize("value", [True, False])
@pytest.mark.parametrize(
    ("attr", "mask"),
    [(DeviceAttributes.steam_wash, 0x10), (DeviceAttributes.fast_clean_wash, 0x20)],
)
def test_switch_write_preserves_other_options(
    subtype: int,
    flags: int,
    soak: int,
    value: bool,
    attr: DeviceAttributes,
    mask: int,
) -> None:
    """Only the selected bit changes; all power/start bytes stay at 0xFF."""
    device = make_device(subtype=subtype)
    device.process_message(response(flags=flags, soak=soak))
    before = device.attributes.copy()
    with patch.object(device, "build_send") as send:
        device.set_attribute(attr, value)
    message = send.call_args.args[0]
    expected = bytearray([0x02] + [0xFF] * 21)
    expected[16] = ((flags & 0x3F) | (soak << 6)) & ~mask
    if value:
        expected[16] |= mask
    assert message.body == expected
    assert device.attributes == before
    assert device._control_options is None


@pytest.mark.parametrize(
    "attr", [DeviceAttributes.steam_wash, DeviceAttributes.fast_clean_wash]
)
@pytest.mark.parametrize("value", [0, 1, 1.0, "on", "true"])
def test_switch_requires_bool(attr: DeviceAttributes, value: float | str) -> None:
    """Numeric/string truthiness must not accidentally turn an option on."""
    device = make_device()
    device.process_message(response())
    with (
        patch.object(device, "build_send") as send,
        pytest.raises(ValueWrongType, match="Expected bool"),
    ):
        device.set_attribute(attr, value)
    send.assert_not_called()


def test_shared_options_require_response_before_next_write() -> None:
    """Do not merge with an unknown snapshot or overwrite an unconfirmed write."""
    device = make_device()
    with (
        patch.object(device, "build_send") as send,
        pytest.raises(ValueWrongType, match="Read current options"),
    ):
        device.set_attribute(DeviceAttributes.steam_wash, True)
    send.assert_not_called()
    device.process_message(response())
    with patch.object(device, "build_send"):
        device.set_attribute(DeviceAttributes.steam_wash, True)
    with (
        patch.object(device, "build_send") as send,
        pytest.raises(ValueWrongType, match="Read current options"),
    ):
        device.set_attribute(DeviceAttributes.fast_clean_wash, True)
    send.assert_not_called()
    device.process_message(response(flags=0x10))
    with patch.object(device, "build_send") as send:
        device.set_attribute(DeviceAttributes.fast_clean_wash, True)
    assert send.call_args.args[0].body[16] == 0x30


@pytest.mark.parametrize(("model", "subtype"), [("other", 13146), ("38131408", 1)])
def test_other_variants_keep_original_attributes(model: str, subtype: int) -> None:
    """Parsing new fields never enables them on an unregistered variant."""
    device = make_device(model, subtype)
    device.process_message(response(flags=0x30, dryer=11))
    for attr in (
        DeviceAttributes.dryer,
        DeviceAttributes.steam_wash,
        DeviceAttributes.fast_clean_wash,
    ):
        assert attr not in device.attributes
        with patch.object(device, "build_send") as send:
            device.set_attribute(attr, True)
        send.assert_not_called()


@pytest.mark.parametrize(
    ("level", "minutes"), [(0, 25), (1, 30), (2, 35), (3, 40), (4, 45)]
)
def test_wash_time_levels(level: int, minutes: int) -> None:
    """Level and minutes are independent attributes from captured mixed wash."""
    device = make_device()
    device.process_message(response(wash_level=level, wash_minutes=minutes))
    assert device.attributes[DeviceAttributes.wash_time] == level
    assert device.attributes[DeviceAttributes.wash_time_value] == minutes
    with patch.object(device, "build_send") as send:
        device.set_attribute(DeviceAttributes.wash_time, level)
    assert send.call_args.args[0].body[9] == level


@pytest.mark.parametrize(
    ("level", "minutes"), [(0, 6), (1, 7), (2, 8), (3, 9), (4, 10)]
)
def test_spin_time_levels(level: int, minutes: int) -> None:
    """Spin time also uses a level code rather than literal minutes."""
    device = make_device()
    device.process_message(response(spin_level=level, spin_minutes=minutes))
    assert device.attributes[DeviceAttributes.dehydration_time] == level
    assert device.attributes[DeviceAttributes.dehydration_time_value] == minutes
    with patch.object(device, "build_send") as send:
        device.set_attribute(DeviceAttributes.dehydration_time, level)
    assert send.call_args.args[0].body[10] == level


@pytest.mark.parametrize(
    "attr", [DeviceAttributes.wash_time, DeviceAttributes.dehydration_time]
)
@pytest.mark.parametrize("value", [5, 8, 25, 30, 254])
def test_mixed_wash_time_bounds(attr: DeviceAttributes, value: int) -> None:
    """The observed mixed-wash range cannot accept a minute count as a level."""
    device = make_device()
    device.process_message(response())
    with patch.object(device, "build_send") as send, pytest.raises(ValueWrongType):
        device.set_attribute(attr, value)
    send.assert_not_called()


def test_fast_clean_time_values_are_not_calculated_from_level() -> None:
    """Fast clean shortens minutes while keeping raw levels unchanged."""
    device = make_device()
    device.process_message(response(flags=0x20, wash_minutes=13, spin_minutes=4))
    assert device.attributes[DeviceAttributes.fast_clean_wash] is True
    assert device.attributes[DeviceAttributes.wash_time] == 0
    assert device.attributes[DeviceAttributes.wash_time_value] == 13
    assert device.attributes[DeviceAttributes.dehydration_time] == 2
    assert device.attributes[DeviceAttributes.dehydration_time_value] == 4


def test_program_change_invalidates_option_snapshot() -> None:
    """Program-dependent options must be read again after changing programs."""
    device = make_device()
    device.process_message(response(flags=0x10))
    with patch.object(device, "build_send"):
        device.set_attribute(DeviceAttributes.program, "cotton")
    with (
        patch.object(device, "build_send") as send,
        pytest.raises(ValueWrongType, match="Read current options"),
    ):
        device.set_attribute(DeviceAttributes.fast_clean_wash, True)
    send.assert_not_called()


@pytest.mark.parametrize(
    "attr", [DeviceAttributes.wash_time, DeviceAttributes.dehydration_time]
)
def test_mixed_wash_bounds_do_not_leak_to_other_programs(
    attr: DeviceAttributes,
) -> None:
    """Unverified programs keep their existing byte-level validation."""
    device = make_device()
    device._attributes[DeviceAttributes.program] = "cotton"
    with patch.object(device, "build_send") as send:
        device.set_attribute(attr, 254)
    send.assert_called_once()
