"""Whole-suite conformance run: regression gate + report/render smoke tests."""

from __future__ import annotations

import pytest

from tests.lua_conformance import build_mapping, generate_all, iter_pairs
from tests.lua_conformance._baseline import current_discrepancies, load_baseline
from tests.lua_conformance.compare import Verdict
from tests.lua_conformance.mapping import MatchStatus
from tests.lua_conformance.report import render_mapping, render_report


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


def test_no_new_protocol_discrepancies() -> None:
    """MISSING/DIFFERENT findings must match the reviewed baseline exactly.

    A new entry means a code change made ``midealocal`` diverge further from the
    Lua protocol evidence -- inspect it.  A removed entry means a discrepancy
    was resolved -- regenerate with ``python -m tests.lua_conformance
    --baseline`` and commit the (smaller) baseline.
    """
    current = current_discrepancies()
    baseline = load_baseline()
    new = sorted(set(current) - set(baseline))
    resolved = sorted(set(baseline) - set(current))
    assert not new, "new protocol discrepancies:\n" + "\n".join(new)
    assert not resolved, (
        "these baseline discrepancies no longer occur -- regenerate the "
        "baseline:\n" + "\n".join(resolved)
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
