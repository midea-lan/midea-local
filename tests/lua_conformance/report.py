"""Render mappings and comparisons into human-readable reports.

Two renderers:

* :func:`render_mapping` -- the ``lua/`` <-> ``midealocal/devices`` table.
* :func:`render_report` -- a Markdown conformance report over a list of
  :class:`~tests.lua_conformance.compare.Comparison` objects: a summary table,
  then every ``MISSING`` / ``DIFFERENT`` finding in full, then a collapsed
  index of ``UNKNOWN`` items so nothing is hidden but the report stays short.
"""

from __future__ import annotations

from collections import Counter
from typing import TYPE_CHECKING

from .compare import Verdict
from .mapping import MatchStatus

if TYPE_CHECKING:
    from .compare import Comparison, Finding
    from .mapping import DeviceMapping

_INTRO = (
    "Verdicts: **MATCH** (agree) / **MISSING** (in Lua, not in midealocal) / "
    "**DIFFERENT** (both implement it, values disagree) / **UNKNOWN** "
    "(not auto-verifiable). A MISSING/DIFFERENT verdict is a *candidate* "
    "discrepancy, not a proven bug -- see README 'Interpreting failures'."
)


def render_mapping(rows: list[DeviceMapping]) -> str:
    """Render the device-type mapping as Markdown."""
    out: list[str] = [
        "# LUA <-> midealocal mapping",
        "",
        "| device type | lua | midealocal | status | # lua files | evidence |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    out.extend(
        f"| {row.key} | {row.lua_dir or '-'} | {row.py_package or 'UNMATCHED'} "
        f"| {row.status.value} | {len(row.lua_files)} | {'; '.join(row.evidence)} |"
        for row in sorted(rows, key=lambda r: (r.status.value, r.key))
    )
    summary = Counter(r.status for r in rows)
    matched_files = sum(
        len(r.lua_files) for r in rows if r.status is MatchStatus.MATCHED
    )
    out += ["", "## Summary", ""]
    out += [
        f"- {status.value}: {summary[status]}"
        for status in MatchStatus
        if summary[status]
    ]
    out.append(f"- lua files under mapped device types: {matched_files}")
    return "\n".join(out) + "\n"


def _summary_table(comparisons: list[Comparison]) -> list[str]:
    rows = [
        "| lua file | package | MATCH | MISSING | DIFFERENT | UNKNOWN |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    total: Counter[str] = Counter()
    for cmp in sorted(comparisons, key=lambda c: c.lua_source):
        counts = cmp.counts()
        total.update(counts)
        rows.append(
            f"| {cmp.lua_source} | {cmp.package} | {counts['MATCH']} "
            f"| {counts['MISSING']} | {counts['DIFFERENT']} | {counts['UNKNOWN']} |",
        )
    rows.append(
        f"| **total** | | {total['MATCH']} | {total['MISSING']} "
        f"| {total['DIFFERENT']} | {total['UNKNOWN']} |",
    )
    return rows


def _detail_blocks(pairs: list[tuple[Comparison, Finding]]) -> list[str]:
    if not pairs:
        return ["_none_", ""]
    out: list[str] = []
    for cmp, finding in pairs:
        out += [
            f"### {cmp.package}: {finding.name}",
            "",
            "```",
            str(finding),
            "```",
            "",
        ]
    return out


def render_report(comparisons: list[Comparison], *, title: str = "") -> str:
    """Render a full Markdown conformance report."""
    diff = [(c, f) for c in comparisons for f in c.by_verdict(Verdict.DIFFERENT)]
    missing = [(c, f) for c in comparisons for f in c.by_verdict(Verdict.MISSING)]

    out: list[str] = [
        f"# {title or 'LUA protocol-conformance report'}",
        "",
        _INTRO,
        "",
        "## Summary",
        "",
        *_summary_table(comparisons),
        "",
        "## DIFFERENT",
        "",
        *_detail_blocks(diff),
        "## MISSING",
        "",
        *_detail_blocks(missing),
        "## UNKNOWN (collapsed)",
        "",
    ]
    for cmp in sorted(comparisons, key=lambda c: c.lua_source):
        unknown = cmp.by_verdict(Verdict.UNKNOWN)
        if not unknown:
            continue
        out.append(f"- **{cmp.lua_source}** ({len(unknown)}):")
        out += [f"  - {f.area}/{f.name}: {f.detail}" for f in unknown]
    out.append("")
    return "\n".join(out) + "\n"
