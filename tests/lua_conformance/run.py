"""Top-level drivers that tie extraction, mapping and comparison together.

``python -m tests.lua_conformance`` regenerates the checked-in
``GENERATED_MAPPING.md`` and ``GENERATED_REPORT.md`` next to this package.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from .compare import Comparison, compare
from .lua_extract import extract_from_file
from .mapping import LUA_ROOT, DeviceMapping, MatchStatus, build_mapping
from .py_introspect import introspect_device
from .report import render_mapping, render_report

_HERE = Path(__file__).resolve().parent


def iter_pairs(
    mapping: list[DeviceMapping] | None = None,
    *,
    limit_per_dir: int | None = None,
) -> list[tuple[str, Path]]:
    """Yield ``(package, lua_path)`` for every mapped device type."""
    mapping = mapping or build_mapping()
    pairs: list[tuple[str, Path]] = []
    for row in mapping:
        if row.status is not MatchStatus.MATCHED or row.lua_dir is None:
            continue
        files = sorted((LUA_ROOT / row.key).glob("*.lua"))
        if limit_per_dir is not None:
            files = files[:limit_per_dir]
        pairs += [(row.key, path) for path in files]
    return pairs


def compare_pair(package: str, lua_path: str | Path) -> Comparison:
    """Extract, introspect and compare a single ``(package, lua file)`` pair."""
    lua = extract_from_file(lua_path)
    py = introspect_device(package)
    return compare(lua, py)


def generate_all(*, limit_per_dir: int | None = None) -> list[Comparison]:
    """Run every mapped comparison and return the list of :class:`Comparison`."""
    return [
        compare_pair(package, path)
        for package, path in iter_pairs(limit_per_dir=limit_per_dir)
    ]


def main(argv: list[str] | None = None) -> int:
    """Regenerate the checked-in mapping and conformance reports."""
    parser = argparse.ArgumentParser(prog="tests.lua_conformance")
    parser.add_argument(
        "--limit-per-dir",
        type=int,
        default=None,
        help="only compare the first N lua files of each device type",
    )
    args = parser.parse_args(argv)

    mapping = build_mapping()
    (_HERE / "GENERATED_MAPPING.md").write_text(
        render_mapping(mapping),
        encoding="utf-8",
    )

    comparisons = generate_all(limit_per_dir=args.limit_per_dir)
    (_HERE / "GENERATED_REPORT.md").write_text(
        render_report(comparisons, title="LUA protocol-conformance report"),
        encoding="utf-8",
    )
    totals = Comparison("", "")
    for cmp in comparisons:
        totals.findings.extend(cmp.findings)
    counts = totals.counts()
    print(  # noqa: T201 - CLI feedback
        f"wrote GENERATED_MAPPING.md and GENERATED_REPORT.md "
        f"({len(comparisons)} comparisons: {counts})",
    )
    return 0
