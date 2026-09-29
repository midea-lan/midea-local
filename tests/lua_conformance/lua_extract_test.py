"""Unit tests for the Lua static extractor.

These use small synthetic snippets so the parser is exercised independently of
the real proprietary files.
"""

from __future__ import annotations

from pathlib import Path

import pytest

from tests.lua_conformance.lua_extract import extract_from_file, extract_from_source

_FIXTURES = Path(__file__).parent / "fixtures"

_CLASSIC = (_FIXTURES / "synthetic_classic.lua").read_text(encoding="utf-8")


def test_extracts_scalar_constants() -> None:
    """``local NAME = value`` lines become typed :class:`Constant` entries."""
    defn = extract_from_source(_CLASSIC, "synthetic_classic.lua")
    assert defn.constants["BYTE_MODE_COOL"].value == 0x20
    assert defn.constants["VALUE_MODE_COOL"].value == "cool"
    assert defn.constants["KEY_POWER"].value == "power"
    assert defn.constants["BYTE_MODE_COOL"].source is not None
    assert defn.constants["BYTE_MODE_COOL"].source.line == 23


def test_extracts_identity_and_framing() -> None:
    """Device-type byte, lua version and framing constants are recovered."""
    defn = extract_from_source(_CLASSIC, "synthetic_classic.lua")
    assert defn.device_type == 0xAC
    assert defn.lua_version == 7
    assert defn.framing["BYTE_PROTOCOL_HEAD"] == 0xAA
    assert defn.framing["BYTE_PROTOCOL_LENGTH"] == 0x0A


def test_pairs_byte_and_value_enums() -> None:
    """``BYTE_MODE_*`` + ``VALUE_MODE_*`` combine into a byte->name mapping."""
    defn = extract_from_source(_CLASSIC, "synthetic_classic.lua")
    mode = defn.enum("MODE")
    assert mode is not None
    assert mode.members == {"AUTO": 0x10, "COOL": 0x20, "HEAT": 0x30}
    assert defn.paired_enum("MODE") == {0x10: "auto", 0x20: "cool", 0x30: "heat"}


def test_extracts_decode_fields_with_mask_and_transform() -> None:
    """``bit.band`` / arithmetic reads become :class:`DecodeField` entries."""
    defn = extract_from_source(_CLASSIC, "synthetic_classic.lua")
    by_name = {f.name: f for f in defn.decode_fields}

    assert by_name["powerValue"].byte == 1
    assert by_name["powerValue"].mask == 0x01
    assert by_name["powerValue"].boolean is True

    assert by_name["modeValue"].signature() == (2, 0x30, 0)
    assert by_name["temperatureValue"].signature() == (2, 0x0F, 0)

    assert by_name["errorCode"].signature() == (5, 0xFF, 0)

    indoor = by_name["indoorTemperatureValue"]
    assert indoor.byte == 11
    assert indoor.transform is not None
    assert "- 50" in indoor.transform


def test_extracts_encode_assignments_and_commands() -> None:
    """``bodyBytes[i] = ...`` lines and their body-type dispatch are captured."""
    defn = extract_from_source(_CLASSIC, "synthetic_classic.lua")
    body_types = {c.body_type for c in defn.commands}
    assert 0xC3 in body_types

    control = next(c for c in defn.commands if c.body_type == 0xC3)
    assert control.request_type == 0x02
    assigned_bytes = {a.byte for a in control.assignments}
    assert {0, 1, 2} <= assigned_bytes


def test_unusual_file_degrades_without_raising() -> None:
    """A structurally different file still yields constants + honest 'unparsed'."""
    defn = extract_from_file(_FIXTURES / "synthetic_unusual.lua")
    assert defn.device_type == 0xB1
    assert defn.enum("MODE_VALUES") is not None  # value-only enum still recovered
    assert defn.decode_fields == []
    assert defn.commands == []
    assert any("jsonToData" in note for note in defn.unparsed)
    assert any("ByByte" in note or "binToModel" in note for note in defn.unparsed)
    # the unparsable ``local COMPUTED = 1 + 2`` / table are simply skipped
    assert "COMPUTED" not in defn.constants
    assert "SOME_TABLE" not in defn.constants


@pytest.mark.parametrize(
    "source",
    [
        "",
        "not lua at all !!!",
        "function jsonToData(x)\n  -- no end here",
        "local X = 0x",
    ],
    ids=["empty", "garbage", "truncated_func", "bad_hex"],
)
def test_malformed_sources_do_not_raise(source: str) -> None:
    """The extractor must never raise on malformed input."""
    defn = extract_from_source(source, "malformed.lua")
    assert defn.source == "malformed.lua"


def test_real_e1_file_smoke() -> None:
    """End-to-end sanity check against a real (small, old) plugin file."""
    repo_root = Path(__file__).resolve().parents[2]
    defn = extract_from_file(repo_root / "lua" / "e1" / "T_0000_E1_3.lua")
    assert defn.device_type == 0xE1
    assert defn.paired_enum("MODE")[0x04] == "eco_wash"
    temp = defn.decode_field("temperature")
    assert temp is not None
    assert temp.byte == 11
