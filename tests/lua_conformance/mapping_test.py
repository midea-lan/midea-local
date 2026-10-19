"""Tests for the LUA <-> ``midealocal`` mapping logic."""

from __future__ import annotations

import pytest

from tests.lua_conformance.mapping import MatchStatus, build_mapping


@pytest.fixture(scope="module")
def rows() -> list:
    """Return the full mapping, built once for the module."""
    return build_mapping()


def test_every_device_type_is_classified(rows: list) -> None:
    """Every row has a status and at least one piece of evidence."""
    assert rows
    for row in rows:
        assert isinstance(row.status, MatchStatus)
        assert row.evidence


def test_matched_rows_have_both_sides_and_corroboration(rows: list) -> None:
    """A MATCHED row points at a real lua dir and package with real evidence."""
    matched = [r for r in rows if r.status is MatchStatus.MATCHED]
    assert len(matched) > 20
    for row in matched:
        assert row.lua_dir
        assert row.py_package
        assert row.lua_files
        assert any("DeviceType" in ev or "type token" in ev for ev in row.evidence)


def test_no_unexplained_conflicts(rows: list) -> None:
    """A CONFLICT would mean same-named dirs disagree on the device byte."""
    conflicts = [r for r in rows if r.status is MatchStatus.CONFLICT]
    assert conflicts == [], [r.key for r in conflicts]


def test_known_unmatched_are_reported_not_guessed(rows: list) -> None:
    """Lua-only and Python-only device types surface as UNMATCHED."""
    by_key = {r.key: r for r in rows}
    # e7 has a lua/ dir but no midealocal/devices/e7 package
    assert by_key["e7"].status is MatchStatus.UNMATCHED_NO_PYTHON
    # x34 has a package but no lua/ dir
    assert by_key["x34"].status is MatchStatus.UNMATCHED_NO_LUA


def test_e1_maps_cleanly(rows: list) -> None:
    """The reference device (E1) maps in both directions."""
    e1 = next(r for r in rows if r.key == "e1")
    assert e1.status is MatchStatus.MATCHED
    assert e1.device_type == 0xE1
    assert any(f.startswith("T_0000_E1_") for f in e1.lua_files)
