"""Tests for the comparison engine, using hand-built IR objects."""

from __future__ import annotations

import pytest

from tests.lua_conformance.compare import Verdict, compare, normalize_name
from tests.lua_conformance.ir import (
    Constant,
    DecodeField,
    Enum,
    ProtocolDefinition,
    SourceRef,
)
from tests.lua_conformance.py_introspect import PyCommand, PythonProtocol


def _lua(**kw: object) -> ProtocolDefinition:
    base = {"source": "lua/xx/T_0000_XX_1.lua", "device_type": 0xAC}
    base.update(kw)
    return ProtocolDefinition(**base)  # type: ignore[arg-type]


def _py(**kw: object) -> PythonProtocol:
    base = {"package": "ac", "device_type": 0xAC}
    base.update(kw)
    return PythonProtocol(**base)  # type: ignore[arg-type]


@pytest.mark.parametrize(
    ("raw", "expected"),
    [
        ("workStatus", "status"),
        ("leftTime", "time_remaining"),
        ("temperatureValue", "temperature"),
        ("modeValue", "mode"),
        ("errorCode", "error_code"),
        ("dry_status", "dry_status"),  # _status is deliberately kept
        ("already_snake", "already_snake"),
    ],
)
def test_normalize_name(raw: str, expected: str) -> None:
    """Field-name canonicalisation for cross-implementation matching."""
    assert normalize_name(raw) == expected


def test_identity_match_and_mismatch() -> None:
    """Device-type byte agreement is MATCH; disagreement is DIFFERENT."""
    ok = compare(_lua(device_type=0xAC), _py(device_type=0xAC))
    assert any(f.area == "identity" and f.verdict is Verdict.MATCH for f in ok.findings)
    bad = compare(_lua(device_type=0xAC), _py(device_type=0xBF))
    assert any(
        f.area == "identity" and f.verdict is Verdict.DIFFERENT for f in bad.findings
    )


def test_decode_field_match_by_name() -> None:
    """Same normalised name + same (byte, mask, shift) -> MATCH."""
    lua = _lua(
        decode_fields=[
            DecodeField("temperatureValue", 11, 0xFF, 0, source=SourceRef("x", 1)),
        ],
    )
    py = _py(decode_fields=[DecodeField("temperature", 11, 0xFF, 0)])
    result = compare(lua, py)
    field = next(f for f in result.findings if f.area == "decode_field")
    assert field.verdict is Verdict.MATCH


def test_decode_field_missing() -> None:
    """A Lua read with no Python counterpart anywhere -> MISSING."""
    lua = _lua(
        decode_fields=[
            DecodeField("weirdSensor", 40, 0xFF, 0, source=SourceRef("x", 1)),
        ],
    )
    result = compare(lua, _py(decode_fields=[]))
    finding = next(f for f in result.findings if f.name == "weird_sensor")
    assert finding.verdict is Verdict.MISSING


def test_decode_field_different_offset() -> None:
    """Same field name, different byte offset -> DIFFERENT with a worked example."""
    lua = _lua(
        decode_fields=[DecodeField("errorCode", 16, 0xFF, 0, source=SourceRef("x", 1))],
    )
    py = _py(decode_fields=[DecodeField("error_code", 20, 0xFF, 0)])
    result = compare(lua, py)
    field = next(f for f in result.findings if f.name == "error_code")
    assert field.verdict is Verdict.DIFFERENT
    assert field.example is not None


def test_right_align_equivalence_is_not_flagged_as_different() -> None:
    """``byte&0xE0`` vs ``(byte&0xE0)>>5`` is a convention diff, not a bug."""
    lua = _lua(
        decode_fields=[DecodeField("modeValue", 2, 0xE0, 0, source=SourceRef("x", 1))],
    )
    py = _py(decode_fields=[DecodeField("mode", 2, 0xE0, 5)])
    result = compare(lua, py)
    field = next(f for f in result.findings if f.name == "mode")
    assert field.verdict is Verdict.UNKNOWN
    assert "right-align" in field.detail


def test_enum_value_match_missing_and_different() -> None:
    """Per-value enum comparison distinguishes MATCH / MISSING / DIFFERENT."""
    lua = _lua(
        constants={
            "BYTE_MODE_COOL": Constant("BYTE_MODE_COOL", 0x02),
            "BYTE_MODE_HEAT": Constant("BYTE_MODE_HEAT", 0x03),
            "BYTE_MODE_TURBO": Constant("BYTE_MODE_TURBO", 0x04),
        },
        enums={
            "MODE": Enum(
                "MODE",
                {"COOL": 0x02, "HEAT": 0x03, "TURBO": 0x04},
                SourceRef("x", 5),
            ),
        },
    )
    py = _py(
        enums={"modes": Enum("modes", {"cool": 0x02, "warm": 0x03})},
    )
    result = compare(lua, py)
    verdicts = {f.name: f.verdict for f in result.findings if f.area == "enum"}
    assert verdicts["mode[0x02]"] is Verdict.MATCH
    assert verdicts["mode[0x03]"] is Verdict.DIFFERENT
    assert verdicts["mode[0x04]"] is Verdict.MISSING


def test_command_body_type_presence() -> None:
    """A Lua body-type with / without a Python emitter -> MATCH / MISSING."""
    from tests.lua_conformance.ir import Command  # noqa: PLC0415

    lua = _lua(
        commands=[
            Command("control", body_type=0xC3, source=SourceRef("x", 1)),
            Command("special", body_type=0x01, source=SourceRef("x", 2)),
        ],
    )
    py = _py(
        commands=[PyCommand("MessageSet", body_type=0xC3, body=b"\xc3\x00")],
    )
    result = compare(lua, py)
    verdicts = {f.name: f.verdict for f in result.findings if f.area == "command"}
    assert verdicts["body_type 0xC3"] is Verdict.MATCH
    assert verdicts["body_type 0x01"] is Verdict.MISSING


def test_t0008_header_skips_offset_comparison() -> None:
    """A 16-byte-header Lua file must not be offset-compared to midealocal."""
    lua = _lua(
        framing={"BYTE_PROTOCOL_LENGTH": 16},
        decode_fields=[DecodeField("powerValue", 1, 0x01, 0, source=SourceRef("x", 1))],
    )
    result = compare(lua, _py(decode_fields=[DecodeField("power", 9, 0x01, 0)]))
    skip = next(f for f in result.findings if f.name == "*")
    assert skip.verdict is Verdict.UNKNOWN
    assert "T_0008" in skip.detail
    # the raw power field was NOT compared against the mismatched python offset
    assert not any(
        f.name == "power" and f.verdict is Verdict.DIFFERENT for f in result.findings
    )


def test_unparsed_notes_surface_as_unknown() -> None:
    """Extractor 'unparsed' notes are never silently dropped."""
    lua = _lua(unparsed=["no jsonToData(): encode side not extracted"])
    result = compare(lua, _py())
    assert any(
        f.area == "extractor" and f.verdict is Verdict.UNKNOWN for f in result.findings
    )
