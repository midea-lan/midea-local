"""Protocol-conformance tests for the E1 (dishwasher) device.

Every expectation here is *derived from* ``lua/e1/T_0000_E1_3.lua`` and checked
against ``midealocal``.  The Lua derivation is quoted next to each assertion so
the test answers "why is this byte/value expected?".
"""

from __future__ import annotations

from pathlib import Path

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.e1.message import (
    E1GeneralMessageBody,
    MessageLock,
    MessageWork,
)
from tests.lua_conformance import compare_pair
from tests.lua_conformance.compare import Verdict
from tests.lua_conformance.lua_extract import extract_from_file

_LUA_FILE = Path(__file__).resolve().parents[2] / "lua" / "e1" / "T_0000_E1_3.lua"


@pytest.fixture(scope="module")
def lua_e1() -> object:
    """Return the extracted IR for the reference E1 Lua file."""
    return extract_from_file(_LUA_FILE)


# --- golden encode vectors ------------------------------------------------------
# lua jsonToData(): the "lock" branch ->  bodyBytes[0]=0x83
#                   bodyBytes[1] = 0x03 (lock on) / 0x04 (lock off)
@pytest.mark.parametrize(
    ("lock", "expected_byte1"),
    [(True, 0x03), (False, 0x04)],
    ids=["lock_on", "lock_off"],
)
def test_lock_request_matches_lua(lock: bool, expected_byte1: int) -> None:
    """MessageLock body reproduces the Lua ``lock`` command bytes."""
    message = MessageLock(ProtocolVersion.V1)
    message.lock = lock
    assert message.body[0] == 0x83  # lua bodyBytes[0]
    assert message.body[1] == expected_byte1  # lua bodyBytes[1]


# lua jsonToData(): the default branch -> bodyBytes[0]=0x08
#                   bodyBytes[1]=workStatus (0x03), bodyBytes[2]=mode
def test_work_request_matches_lua() -> None:
    """MessageWork body reproduces the Lua ``work`` command bytes."""
    message = MessageWork(ProtocolVersion.V1)
    message.mode = 0x04  # BYTE_MODE_ECO_WASH
    assert list(message.body[0:3]) == [0x08, 0x03, 0x04]


# --- golden decode vectors ----------------------------------------------------
# lua updateGlobalPropertyValueByByte():
#   workStatus = messageBytes[1]      mode        = messageBytes[2]
#   lock (bit 0x10 of messageBytes[5])
#   leftTime   = messageBytes[6]      washStage   = messageBytes[9]
#   errorCode  = messageBytes[10]     temperature = messageBytes[11]
def test_general_body_decode_matches_lua_offsets() -> None:
    """E1GeneralMessageBody reads every field from the Lua-specified offset."""
    body = bytearray(20)
    body[1] = 0x03  # -> status
    body[2] = 0x04  # -> mode
    body[5] = 0x10  # -> child lock bit
    body[6] = 45  # -> time_remaining
    body[9] = 3  # -> progress
    body[10] = 7  # -> error_code
    body[11] = 55  # -> temperature

    parsed = E1GeneralMessageBody(body)

    assert parsed.status == 0x03
    assert parsed.mode == 0x04
    assert parsed.child_lock is True
    assert parsed.time_remaining == 45
    assert parsed.progress == 3
    assert parsed.error_code == 7
    assert parsed.temperature == 55


# --- enum conformance -------------------------------------------------------
_EXPECTED_MODE_MATCHES = {
    0x01: "auto_wash",
    0x02: "strong_wash",
    0x03: "standard_wash",
    0x04: "eco_wash",
    0x05: "glass_wash",
    0x07: "fast_wash",
}


@pytest.mark.parametrize(("code", "name"), sorted(_EXPECTED_MODE_MATCHES.items()))
def test_mode_enum_values_agree_with_lua(
    lua_e1: object,
    code: int,
    name: str,
) -> None:
    """Wash-mode byte values shared by both sides map to the same name."""
    assert lua_e1.paired_enum("MODE")[code] == name  # type: ignore[attr-defined]


def test_known_mode_discrepancies_are_reported(lua_e1: object) -> None:  # noqa: ARG001
    """Framework surfaces the two intentional/edge E1 mode-name differences.

    * 0x00: lua ``neutral_gear`` vs midealocal ``none`` -- intentional rename.
    * 0x09: lua ``self_define`` (v3 file) vs midealocal ``90min`` -- protocol
      version drift worth a human look, tracked here as a DIFFERENT finding.
    """
    result = compare_pair("e1", _LUA_FILE)
    diffs = {
        f.name
        for f in result.findings
        if f.area == "enum" and f.verdict is Verdict.DIFFERENT
    }
    assert "mode[0x00]" in diffs
    assert "mode[0x09]" in diffs


def test_e1_has_no_missing_or_offset_discrepancies() -> None:
    """E1 has no MISSING findings and no wrong-offset decode/command/framing.

    DIFFERENT is limited to the documented enum-name cases asserted above.
    """
    result = compare_pair("e1", _LUA_FILE)
    assert result.by_verdict(Verdict.MISSING) == []
    offset_diffs = [
        f
        for f in result.by_verdict(Verdict.DIFFERENT)
        if f.area in {"decode_field", "command", "framing"}
    ]
    assert offset_diffs == [], [str(f) for f in offset_diffs]
