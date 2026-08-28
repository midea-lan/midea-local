"""Whole-suite conformance run: invariants + report/render smoke tests.

Per-device regression protection lives in the ``conformance_<device>_test.py``
files (golden encode/decode vectors derived from the Lua). This module only
checks corpus-wide invariants that must hold regardless of how many Lua files
exist, so unrelated ``main`` churn (a new Lua file, a ``message.py`` tweak)
never turns CI red here.
"""

from __future__ import annotations

import pytest

from tests.lua_conformance import build_mapping, compare_pair, generate_all, iter_pairs
from tests.lua_conformance.compare import Verdict
from tests.lua_conformance.mapping import LUA_ROOT, MatchStatus
from tests.lua_conformance.report import render_mapping, render_report

#: Device types with hand-written golden vectors in a ``conformance_*_test.py``.
#: For these, every Lua file must agree with ``midealocal`` on field offsets,
#: command body-types and framing (name-only enum differences are allowed and
#: covered explicitly in the per-device test).
VERIFIED_DEVICES = ("e1",)


@pytest.fixture(scope="module")
def comparisons() -> list:
    """Every mapped (package, lua file) comparison."""
    return generate_all()


def test_mapping_covers_all_lua_and_python(comparisons: list) -> None:
    """Sanity: the run touches every MATCHED device type and many lua files."""
    rows = build_mapping()
    matched = [r for r in rows if r.status is MatchStatus.MATCHED]
    packages = {c.package for c in comparisons}
    assert packages == {r.key for r in matched}
    assert len(comparisons) == len(iter_pairs())
    assert len(comparisons) > 100


@pytest.mark.parametrize("device", VERIFIED_DEVICES)
def test_verified_device_has_no_structural_regression(device: str) -> None:
    """A verified device must not gain a MISSING or wrong-offset finding.

    This is the regression gate: if a ``midealocal`` change makes a verified
    device diverge from its Lua evidence on a field offset, mask, command
    body-type or framing constant, this fails. Enum name differences are
    intentional-until-proven and checked in the per-device test instead.
    """
    for lua_path in sorted((LUA_ROOT / device).glob("*.lua")):
        result = compare_pair(device, lua_path)
        offenders = [
            f
            for f in result.findings
            if f.verdict is Verdict.MISSING
            or (
                f.verdict is Verdict.DIFFERENT
                and f.area in {"decode_field", "command", "framing"}
            )
        ]
        assert not offenders, f"{lua_path.name}:\n" + "\n".join(
            str(f) for f in offenders
        )


def test_every_finding_has_traceable_provenance(comparisons: list) -> None:
    """MISSING/DIFFERENT findings point back at a Lua source location."""
    for cmp in comparisons:
        for finding in cmp.findings:
            if finding.verdict in (Verdict.MISSING, Verdict.DIFFERENT):
                assert finding.lua_source, finding
                assert finding.detail


def test_render_report_smoke(comparisons: list) -> None:
    """The Markdown report renders and contains the expected sections."""
    text = render_report(comparisons[:20], title="test")
    assert "# test" in text
    assert "## Summary" in text
    assert "## DIFFERENT" in text
    assert "## MISSING" in text
    assert "## UNKNOWN (collapsed)" in text


def test_render_mapping_smoke() -> None:
    """The Markdown mapping renders with a row per device type."""
    text = render_mapping(build_mapping())
    assert "| device type |" in text
    assert "e1" in text
    assert "UNMATCHED" in text
