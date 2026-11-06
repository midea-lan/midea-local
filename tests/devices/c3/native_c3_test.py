"""Native 17100007 regressions ported from wuwentao/midea-lan#261."""

from collections.abc import Callable
from typing import TYPE_CHECKING, Any, cast
from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.c3 import DeviceAttributes as A
from midealocal.devices.c3 import MideaC3Device
from midealocal.devices.c3.message import MessageC3Response
from midealocal.devices.c3.native import (
    BASIC_SIZES,
    BasicTag,
    C3QuintupleBasicBody,
    C3QuintupleEnergyBody,
    MessageQuery2F12,
    MessageQuery2010,
    MessageSet2010,
)
from midealocal.message import MessageType

if TYPE_CHECKING:
    from midealocal.base_classes.climate import MideaHVACMode


QUERY_REPLY = bytes.fromhex(
    "aa7cc300000000000003002010ff1cffff00ffff01ff0103014a7fff00f001e000ff"
    "00000000010101000000000001000000020202022600fa00fa0032022600fa00fa0032"
    "012c00aa025800c801b100010102ff010130000000002f000000000000000000000000"
    "000001005a0000ffff001a0a1f0022ffffffff006b",
)


def device() -> MideaC3Device:
    """Create an offline controller with no real credentials or connection."""
    return MideaC3Device(
        name="Test",
        device_id=1,
        ip_address="192.0.2.1",
        port=6444,
        token="AA",
        key="BB",
        device_protocol=ProtocolVersion.V1,
        model="17100007",
        subtype=195,
    )


def frame(body: bytes, kind: MessageType = MessageType.set) -> bytes:
    """Wrap a synthetic acknowledgement without making a network connection."""
    header = bytes((0xAA, 10 + len(body), 0xC3, 0, 0, 0, 0, 0, 0, kind))
    return header + body + bytes((-sum((header + body)[1:]) & 0xFF,))


def test_basic_query_matches_vendor_lua() -> None:
    """The tested UART query must remain byte-for-byte vendor compatible."""
    assert (
        MessageQuery2010().serialize().hex()
        == "aa14c300000000000003002010ffffffff00fffffc"
    )


@pytest.mark.parametrize(
    ("values", "expected"),
    [
        (
            {BasicTag.DHW_TEMPERATURE: 48},
            "aa19c300000000000002002010ffffffff01ffff00070201e00d",
        ),
        (
            {BasicTag.DHW_TEMPERATURE: 48.5},
            "aa19c300000000000002002010ffffffff01ffff00070201e508",
        ),
        (
            {BasicTag.DHW_POWER: True},
            "aa18c300000000000002002010ffffffff01ffff00020101f4",
        ),
        (
            {BasicTag.DHW_POWER: False},
            "aa18c300000000000002002010ffffffff01ffff00020100f5",
        ),
        (
            {BasicTag.ZONE1_TEMPERATURE: 33},
            "aa19c300000000000002002010ffffffff01ffff000402014aa6",
        ),
        (
            {BasicTag.ZONE1_POWER: False},
            "aa18c300000000000002002010ffffffff01ffff00000100f7",
        ),
    ],
)
def test_set_matches_vendor_lua(
    values: dict[BasicTag, bool | float | int],
    expected: str,
) -> None:
    """Literal packets were generated independently by the recovered vendor Lua."""
    assert MessageSet2010(values).serialize().hex() == expected


@pytest.mark.parametrize("value", [-1, float("nan"), float("inf"), 3276.7, 3276.69])
def test_invalid_temperature(value: float) -> None:
    """Reject values that cannot represent a valid target."""
    with pytest.raises(ValueError, match="temperature"):
        MessageSet2010({BasicTag.DHW_TEMPERATURE: value})


@pytest.mark.parametrize(
    "values",
    [{}, {99: True}, {BasicTag.DHW_POWER: "false"}, {BasicTag.MODE: 99}],
)
def test_invalid_controls(values: dict[Any, Any]) -> None:
    """Never silently coerce invalid controls into dangerous defaults."""
    with pytest.raises(ValueError, match=r"."):
        MessageSet2010(values)


def test_real_query_reply() -> None:
    """A synchronous query now exposes the actual controller state."""
    response = MessageC3Response(QUERY_REPLY, model="17100007")
    assert response.zone1_power is True
    assert response.zone2_power is None  # ff means invalid, not false.
    assert response.dhw_power is True
    assert response.mode == 3
    assert response.dhw_target_temp == 48
    assert response.room_target_temp == 24
    assert response.tank_actual_temperature == 43.3
    assert response.outdoor_temperature == 9
    assert response.dhw_temp_min == 20
    assert response.dhw_temp_max == 60
    assert response.quintuple_arrays["zone_target_temp"] == {0: 33}


def test_device_query_and_targets() -> None:
    """Translate water/room modes and limits into the existing HA-facing attributes."""
    d = device()
    assert len(d.build_query()) == 3
    status = d.process_message(QUERY_REPLY)
    assert status[A.target_temperature] == [33, None]
    assert status[A.temperature_min][0] == 25
    assert status[A.temperature_max][0] == 55
    assert d.attributes[A.zone1_water_temp_mode] is True
    assert d.attributes[A.zone1_room_temp_mode] is False
    assert d._quintuple_ready is True


def test_controls_wait_for_status() -> None:
    """Prevent the old default room-temperature mode from selecting the wrong field."""
    d = device()
    with pytest.raises(ValueError, match="first 0x2010"):
        d.set_attribute(A.dhw_power, True)
    with pytest.raises(ValueError, match="first 0x2010"):
        d.set_target_temperature(33, None, 0)


@pytest.mark.parametrize(
    ("attr", "tag", "value"),
    [
        (A.zone1_power, BasicTag.ZONE1_POWER, False),
        (A.zone2_power, BasicTag.ZONE2_POWER, False),
        (A.dhw_power, BasicTag.DHW_POWER, True),
        (A.zone1_curve, BasicTag.ZONE1_CURVE, True),
        (A.zone2_curve, BasicTag.ZONE2_CURVE, False),
        (A.fast_dhw, BasicTag.FAST_DHW, True),
        (A.tbh, BasicTag.TANK_BOOSTER, False),
        (A.dhw_target_temp, BasicTag.DHW_TEMPERATURE, 48.5),
    ],
)
def test_attribute_routing(attr: A, tag: BasicTag, value: bool | float) -> None:
    """Every supported attribute writes only its own TLV."""
    d = device()
    d.process_message(QUERY_REPLY)
    d._attributes[A.double_zone] = True
    with patch.object(d, "build_send") as send:
        d.set_attribute(attr, value)
    assert (
        send.call_args.args[0].serialize() == MessageSet2010({tag: value}).serialize()
    )


def test_temperature_and_mode_routing() -> None:
    """Preserve half degrees and map HA auto (1) to vendor auto (5)."""
    d = device()
    d.process_message(QUERY_REPLY)
    d._attributes[A.double_zone] = True
    with patch.object(d, "build_send") as send:
        d.set_target_temperature(33.5, None, 0)
        assert (
            send.call_args.args[0].serialize()
            == MessageSet2010({BasicTag.ZONE1_TEMPERATURE: 33.5}).serialize()
        )
        d._set_mode(0, 1)
        assert (
            send.call_args.args[0].serialize()
            == MessageSet2010(
                {BasicTag.ZONE1_POWER: True, BasicTag.MODE: 5},
            ).serialize()
        )
        d._set_mode(0, 0)
        assert (
            send.call_args.args[0].serialize()
            == MessageSet2010(
                {BasicTag.ZONE1_POWER: False},
            ).serialize()
        )
        d.set_target_temperature(34, cast("MideaHVACMode", 3), 1)
        assert (
            send.call_args.args[0].serialize()
            == MessageSet2010(
                {
                    BasicTag.ZONE2_TEMPERATURE: 34,
                    BasicTag.ZONE2_POWER: True,
                    BasicTag.MODE: 3,
                },
            ).serialize()
        )
        d.set_target_temperature(34, cast("MideaHVACMode", 0), 1)
        assert (
            send.call_args.args[0].serialize()
            == MessageSet2010(
                {BasicTag.ZONE2_TEMPERATURE: 34, BasicTag.ZONE2_POWER: False},
            ).serialize()
        )


def test_sparse_ack_preserves_other_zone_and_refreshes_target() -> None:
    """A one-field reply must not reset other zones or power flags."""
    d = device()
    d.process_message(QUERY_REPLY)
    ack = frame(bytes.fromhex("002010ffffffff01ffff000402014f"))
    state = d.process_message(ack)
    assert state[A.target_temperature] == [33.5, None]
    assert d.attributes[A.dhw_target_temp] == 48
    assert d.attributes[A.dhw_power] is True


def test_room_mode_and_cooling_limits() -> None:
    """Apply correct limits for cooling, auto and room-controlled zones."""
    d = device()
    d.process_message(QUERY_REPLY)
    d.process_message(frame(bytes.fromhex("002010ffffffff01ffff00030102")))
    assert d.attributes[A.temperature_max][0] == 25
    d.process_message(frame(bytes.fromhex("002010ffffffff01ffff00120101")))
    assert d.attributes[A.temperature_min][0] == 17
    assert d.attributes[A.temperature_max][0] == 30
    with patch.object(d, "build_send") as send:
        d.set_target_temperature(22.5, cast("MideaHVACMode", 1), 0)
    assert (
        send.call_args.args[0].serialize()
        == MessageSet2010(
            {
                BasicTag.ZONE1_TEMPERATURE: 22.5,
                BasicTag.ROOM_TEMPERATURE: 22.5,
                BasicTag.ZONE1_POWER: True,
                BasicTag.MODE: 5,
            },
        ).serialize()
    )


@pytest.mark.parametrize(
    "body",
    [
        b"",
        bytes(9),
        bytes.fromhex("002010ffffffff02ffff"),
        bytes.fromhex("002010ffffffff01ffff00"),
        bytes.fromhex("002010ffffffff01ffff00070201"),
        bytes.fromhex("002010ffffffff01ffff00070101"),
    ],
)
def test_malformed_bodies(body: bytes) -> None:
    """Malformed envelopes and TLVs cannot publish partial controls."""
    response = C3QuintupleBasicBody(bytearray(body))
    assert response.quintuple_basic is False
    assert not hasattr(response, "dhw_target_temp")


def test_unknown_tlv_and_invalid_temperature() -> None:
    """Skip unknown tags and unavailable probes without inventing values."""
    body = bytes.fromhex("002010ffffffff01ffff123401010007027fff000601ff")
    assert not C3QuintupleBasicBody(bytearray(body)).quintuple_basic
    body = bytes.fromhex("002010ffffffff01ffff123401010007027fff")
    response = C3QuintupleBasicBody(bytearray(body))
    assert response.quintuple_basic
    assert not hasattr(response, "dhw_target_temp")


def test_invalid_measured_temperatures_clear_stale_readings() -> None:
    """Unavailable probes publish None while invalid targets remain unchanged."""
    d = device()
    d.process_message(QUERY_REPLY)
    assert d.attributes[A.tank_actual_temperature] == 43.3
    assert d.attributes[A.outdoor_temperature] == 9
    status = d.process_message(
        frame(
            bytes.fromhex(
                "002010ffffffff01ffff0029027fff0034027fff0007027fff",
            ),
        ),
    )
    assert status[A.tank_actual_temperature] is None
    assert status[A.outdoor_temperature] is None
    assert d.attributes[A.dhw_target_temp] == 48


@pytest.mark.parametrize(
    ("raw", "code", "description"),
    [(0, 0, "No error"), (7, 7, "Unknown code (raw=7)"), (0xFF, None, None)],
)
def test_quintuple_error_code_description(
    raw: int,
    code: int | None,
    description: str | None,
) -> None:
    """Native error codes update both the numeric and human-readable state."""
    response = C3QuintupleBasicBody(
        bytearray.fromhex(f"002010ffffffff01ffff002a01{raw:02x}"),
    )
    assert response.error_code == code
    assert response.error_code_description == description


def test_signed_temperature() -> None:
    """The Lua's Temp type is signed two's-complement tenths."""
    body = bytes.fromhex("002010ffffffff01ffff003402ffce")
    assert C3QuintupleBasicBody(bytearray(body)).outdoor_temperature == -5


@pytest.mark.parametrize(
    "operation",
    [
        lambda d: d.set_attribute("not_a_control", True),
        lambda d: d.set_attribute(A.dhw_power, "false"),
        lambda d: d.set_attribute(A.dhw_target_temp, 90),
        lambda d: d.set_target_temperature(80, None, 0),
        lambda d: d.set_target_temperature(30, None, 2),
        lambda d: d.set_target_temperature(30, cast("MideaHVACMode", 8), 0),
        lambda d: d._set_mode(2, 3),
        lambda d: d._set_mode(0, 8),
        lambda d: d._set_mode(1, 3),
        lambda d: d.set_target_temperature(34, None, 1),
        lambda d: d.set_attribute(A.zone2_power, True),
    ],
)
def test_rejected_controls_never_send(
    operation: Callable[[MideaC3Device], None],
) -> None:
    """Unsupported operations must never use the legacy whole-state command."""
    d = device()
    d.process_message(QUERY_REPLY)
    with patch.object(d, "build_send") as send, pytest.raises(ValueError, match=r"."):
        operation(d)
    send.assert_not_called()


def test_schema_reaches_outdoor_field() -> None:
    """Guard offsets across the ASCII fields before tag 52."""
    assert 10 + sum(BASIC_SIZES[:52]) == 97


def test_unknown_reply_preserves_ready_state() -> None:
    """Unrelated replies do not clear known targets or readiness."""
    d = device()
    d.process_message(QUERY_REPLY)
    assert d.process_message(frame(bytes.fromhex("00ffff"))) == {}
    assert d.attributes[A.target_temperature][0] == 33


def full_status(changes: dict[int, bytes]) -> bytes:
    """Change specific vendor tags in an otherwise valid sequential reply."""
    body = bytearray(QUERY_REPLY[10:-1])
    for tag, value in changes.items():
        assert len(value) == BASIC_SIZES[tag]
        start = 10 + sum(BASIC_SIZES[:tag])
        body[start : start + len(value)] = value
    return frame(bytes(body), MessageType.query)


def test_selectors_alone_cannot_enable_controls() -> None:
    """Mode/type TLVs must not authorize constructor temperature defaults."""
    d = device()
    d.process_message(frame(bytes.fromhex("002010ffffffff01ffff0003010300120100")))
    assert not d._quintuple_ready
    assert d.attributes[A.temperature_min][0] is None
    with (
        patch.object(d, "build_send") as send,
        pytest.raises(ValueError, match="first 0x2010"),
    ):
        d.set_target_temperature(33, None, 0)
    send.assert_not_called()


@pytest.mark.parametrize(
    ("mode", "water_type", "limit_tag"),
    [
        (3, 0, 29),
        (3, 0, 30),
        (2, 0, 31),
        (2, 0, 32),
        (5, 0, 31),
        (3, 1, 37),
        (3, 1, 38),
    ],
)
def test_full_reply_clears_selected_limits(
    mode: int,
    water_type: int,
    limit_tag: int,
) -> None:
    """An unavailable active limit revokes readiness and clears derived bounds."""
    d = device()
    d.process_message(QUERY_REPLY)
    assert bool(d._quintuple_ready)
    d.process_message(
        full_status(
            {
                3: bytes((mode,)),
                18: bytes((water_type,)),
                28: b"\x01",
                limit_tag: b"\x7f\xff",
            },
        ),
    )
    assert not bool(d._quintuple_ready)
    bounds = [d.attributes[A.temperature_min][0], d.attributes[A.temperature_max][0]]
    assert None in bounds
    with (
        patch.object(d, "build_send") as send,
        pytest.raises(ValueError, match="first 0x2010"),
    ):
        d.set_target_temperature(25, None, 0)
    send.assert_not_called()
    d.process_message(QUERY_REPLY)
    assert d._quintuple_ready


def test_sparse_ack_preserves_omitted_limits_and_clears_explicit_sentinel() -> None:
    """An omitted zone is preserved; an explicitly unavailable limit is not."""
    d = device()
    d.process_message(QUERY_REPLY)
    second = d.attributes[A.zone_heating_temp_max][1]
    d.process_message(frame(bytes.fromhex("002010ffffffff01ffff001d020226")))
    assert d.attributes[A.zone_heating_temp_max] == [55, second]
    assert d._quintuple_ready
    d.process_message(frame(bytes.fromhex("002010ffffffff01ffff001d027fff")))
    assert d.attributes[A.zone_heating_temp_max] == [None, second]
    assert not d._quintuple_ready


@pytest.mark.parametrize("tag", [39, 40])
def test_unknown_dhw_limits_block_temperature_writes(tag: int) -> None:
    """DHW cannot reuse default or stale limits when the controller clears them."""
    d = device()
    d.process_message(QUERY_REPLY)
    d.process_message(full_status({tag: b"\x7f\xff"}))
    with (
        patch.object(d, "build_send") as send,
        pytest.raises(ValueError, match="limits"),
    ):
        d.set_attribute(A.dhw_target_temp, 49)
    send.assert_not_called()


@pytest.mark.parametrize("tag", [3, 18])
def test_invalid_selectors_clear_readiness(tag: int) -> None:
    """Unknown modes and temperature types cannot retain prior write readiness."""
    d = device()
    d.process_message(QUERY_REPLY)
    d.process_message(full_status({tag: b"\xff"}))
    assert not d._quintuple_ready
    assert d.attributes[A.temperature_min][0] is None


def test_auto_mode_requires_reported_actual_mode() -> None:
    """Unavailable auto selection cannot silently select the heating defaults."""
    d = device()
    d.process_message(full_status({3: b"\x05", 28: b"\xff"}))
    assert not d._quintuple_ready


@pytest.mark.parametrize("tag", [31, 32])
def test_mode_change_checks_destination_limits(tag: int) -> None:
    """A valid current heating range does not authorize unknown cooling limits."""
    d = device()
    d.process_message(full_status({tag: b"\x7f\xff"}))
    assert d._quintuple_ready  # Heating's own limits are still valid.
    with (
        patch.object(d, "build_send") as send,
        pytest.raises(ValueError, match="limits"),
    ):
        d.set_target_temperature(20, cast("MideaHVACMode", 2), 0)
    send.assert_not_called()


def test_mode_change_rejects_target_outside_destination_range() -> None:
    """A 33 C heating target cannot be reused for cooling, whose upper bound is 25."""
    d = device()
    d.process_message(QUERY_REPLY)
    with (
        patch.object(d, "build_send") as send,
        pytest.raises(ValueError, match="limits"),
    ):
        d.set_target_temperature(33, cast("MideaHVACMode", 2), 0)
    send.assert_not_called()


@pytest.mark.parametrize(
    ("lower", "upper"),
    [(None, 55), (25, None), (55, 25), (float("nan"), 55), (25, float("inf"))],
)
def test_unusable_limit_pairs(lower: float | None, upper: float | None) -> None:
    """Reject missing, inverted and non-finite limits."""
    assert not device()._valid_quintuple_limits(lower, upper)


def test_both_configured_zones_require_limits() -> None:
    """Readiness includes the second zone only when reported as configured."""
    d = device()
    d.process_message(full_status({17: b"\x01", 33: b"\x7f\xff"}))
    assert not d._quintuple_ready


@pytest.mark.parametrize(
    "invalid_status",
    [
        frame(bytes.fromhex("002010ffffffff01ffff001101ff")),
        full_status({17: b"\xff"}),
    ],
)
def test_invalid_double_zone_revokes_zone2_controls(invalid_status: bytes) -> None:
    """An explicit invalid capability must not retain stale zone-2 authorization."""
    d = device()
    d.process_message(full_status({17: b"\x01"}))
    assert d.attributes[A.double_zone] is True
    d.process_message(invalid_status)
    assert d.attributes[A.double_zone] is None
    with (
        patch.object(d, "build_send") as send,
        pytest.raises(ValueError, match="Zone 2"),
    ):
        d.set_attribute(A.zone2_power, True)
    send.assert_not_called()


ENERGY_REPLY = bytes.fromhex(
    "aa9bc300000000000003002f12ff1cffff00ffff02ffffffff0258020b006b00"
    "000230000364c000030ffc0002ed380000ad0c00008e30000001f60000000000"
    "0000000000000000000000000054c400003e8000001edc00000113000002bc00"
    "0001f40000012c000000e90000157c00001068000007d000000113000054c400"
    "003e8000001edc00000113000054c400003e8000001edc0000011312",
)
EXPECTED = {
    "instant_power0": 1070,
    "instant_renew_power0": 5230,
    "current_unit_capacity": 6,
    "total_energy_consumption": 443,
    "total_produced_energy": 2224,
}


def test_energy_query_matches_vendor_lua() -> None:
    """The read-only query exactly matches vendor jsonToData output."""
    assert (
        MessageQuery2F12().serialize().hex()
        == "aa14c300000000000003002f12ffffffff00ffffeb"
    )


@pytest.mark.parametrize("kind", [MessageType.query, MessageType.notify1])
def test_real_energy_reply(kind: MessageType) -> None:
    """Live reply gives kW heat, watts electricity and kWh totals."""
    packet = bytearray(ENERGY_REPLY)
    packet[9] = kind
    response = MessageC3Response(bytes(packet), model="17100007")
    assert response.quintuple_energy is True
    for name, value in EXPECTED.items():
        assert getattr(response, name) == value
    d = device()
    status = d.process_message(bytes(packet))
    for name, value in EXPECTED.items():
        assert status[name] == value
        assert d.attributes[A(name)] == value
    assert d._quintuple_ready is False  # Energy is not basic control status.


@pytest.mark.parametrize(
    ("tag", "width", "name", "expected"),
    [
        (2, 2, "current_unit_capacity", 0.35),
        (3, 2, "instant_renew_power0", 350),
        (4, 2, "instant_power0", 350),
        (6, 4, "total_produced_energy", 0.35),
        (9, 4, "total_energy_consumption", 0.35),
    ],
)
def test_fractional_energy_precision(
    tag: int,
    width: int,
    name: str,
    expected: float,
) -> None:
    """Raw 35 must yield 0.35, not reciprocal multiplication's float artifact."""
    body = bytearray.fromhex("002f12ffffffff01ffff")
    body.extend(tag.to_bytes(2, "big") + bytes((width,)) + (35).to_bytes(width, "big"))
    parsed = C3QuintupleEnergyBody(body)
    assert getattr(parsed, name) == expected


@pytest.mark.parametrize(
    ("model", "kind"),
    [("17100003", MessageType.query), ("17100007", MessageType.set)],
)
def test_energy_dispatch_is_restricted(model: str, kind: MessageType) -> None:
    """Never reinterpret other models or control acknowledgements as energy."""
    response = MessageC3Response(frame(ENERGY_REPLY[10:-1], kind), model=model)
    assert not hasattr(response, "quintuple_energy")


@pytest.mark.parametrize(("fill", "expected"), [(0, 0), (255, None)])
def test_zero_and_unavailable(fill: int, expected: int | None) -> None:
    """Invalid counters clear the current state; genuine zeros remain numeric."""
    body = bytearray(ENERGY_REPLY[10:-1])
    body[10:] = bytes([fill]) * (len(body) - 10)
    response = C3QuintupleEnergyBody(body)
    for name in EXPECTED:
        assert getattr(response, name) == expected


def test_sparse_energy_and_malformed_tlv() -> None:
    """Partial updates preserve unrelated counters; malformed TLVs are atomic."""
    d = device()
    d.process_message(ENERGY_REPLY)
    envelope = bytes.fromhex("002f12ffffffff01ffff")
    d.process_message(
        frame(envelope + bytes.fromhex("0004020000"), MessageType.notify1),
    )
    assert d.attributes[A.instant_power0] == 0
    assert d.attributes[A.total_produced_energy] == 2224
    for tail in ["00", "00040200", "00040100", "000402006b00060200"]:
        parsed = C3QuintupleEnergyBody(bytearray(envelope + bytes.fromhex(tail)))
        assert parsed.quintuple_energy is False
        assert not hasattr(parsed, "instant_power0")
    unknown = C3QuintupleEnergyBody(bytearray(envelope + bytes.fromhex("ffff0100")))
    assert unknown.quintuple_energy is False


@pytest.mark.parametrize("length", [0, 9, 10, 48])
def test_truncated_energy(length: int) -> None:
    """Short sequential blocks must not produce plausible-looking power."""
    parsed = C3QuintupleEnergyBody(bytearray(ENERGY_REPLY[10:-1][:length]))
    assert parsed.quintuple_energy is False
    assert not hasattr(parsed, "instant_power0")


def test_minimum_energy_and_unknown_format() -> None:
    """A complete core block is enough; unsupported encodings are ignored."""
    body = bytearray(ENERGY_REPLY[10:-1][:49])
    assert C3QuintupleEnergyBody(body).instant_power0 == 1070
    body[7] = 2
    assert C3QuintupleEnergyBody(body).quintuple_energy is False


def test_other_telemetry_cannot_overwrite_energy() -> None:
    """Do not mix legacy raw counters/capacity with the authoritative 2F12 table."""
    d = device()
    d.process_message(QUERY_REPLY)
    d.process_message(ENERGY_REPLY)
    body = bytearray.fromhex("002f10ff1cffff00ffff") + bytearray(180)
    body[60:64] = bytes.fromhex("00000051")
    status = d.process_message(frame(bytes(body), MessageType.notify1))
    for name, value in EXPECTED.items():
        assert name not in status
        assert d.attributes[A(name)] == value
    assert status[A.temp_tw_out] == 0.0


@pytest.mark.parametrize(
    ("raw", "expected"), [(215, 21.5), (0x800A, -1.0), (0x7FFF, None), (0xFFFF, None)]
)
@pytest.mark.parametrize(
    ("offset", "name"),
    [
        (15, "outdoor_temperature"),
        (19, "temp_tw_in"),
        (21, "temp_tw_out"),
        (27, "temp_t1"),
        (29, "temp_tw2"),
        (37, "temp_ta"),
    ],
)
def test_native_telemetry(
    raw: int, expected: float | None, offset: int, name: str
) -> None:
    """Lua telemetry temperatures preserve tenths and clear unavailable sensors."""
    d = device()
    body = bytearray.fromhex("002f10ffffffff00ffff") + bytearray(29)
    body[offset : offset + 2] = raw.to_bytes(2, "big")
    status = d.process_message(frame(bytes(body), MessageType.query))
    assert status[name] == expected
    assert d.attributes[name] == expected


@pytest.mark.parametrize(
    "body", ["002f10", "002f10ffffffff01ffff", "002f10ffffffff00ffff00"]
)
def test_partial_native_telemetry(body: str) -> None:
    """Unsupported/truncated telemetry must not fabricate temperature values."""
    d = device()
    assert d.process_message(frame(bytes.fromhex(body), MessageType.query)) == {}


def test_native_telemetry_query() -> None:
    """The compact query uses the vendor envelope."""
    assert device().build_query()[2].body == bytes.fromhex("002f10ffffffff00ffff")


def test_native_unported_optional_controls_are_not_advertised() -> None:
    """Core only creates generic entities for attributes the library exposes."""
    d = device()
    assert "silent_level" not in d.attributes
    assert "disinfect" not in d.attributes
    assert "eco_mode" not in d.attributes
    assert "silent_mode" not in d.attributes
