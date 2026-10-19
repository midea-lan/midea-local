"""Pre-commit hook: scope the Lua conformance comparison to touched files.

Invoked by prek with the staged file paths that changed (see the ``local``
hook in ``.pre-commit-config.yaml``). Two rules decide what gets compared:

* a ``lua/<type>/*.lua`` file was added or changed -> compare
  ``midealocal/devices/<type>`` against *that* lua file only.
* a ``midealocal/devices/<type>/*.py`` file changed -> compare it against
  *every* ``lua/<type>/*.lua`` file (the full corpus for that device type).

Findings are always printed. Only :data:`~tests.lua_conformance.verified.
VERIFIED_DEVICES` can fail the commit, and only on the same structural
regressions ``conformance_report_test.py`` gates on; every other device type
is informational, since most of the corpus still has known, untriaged
MISSING/DIFFERENT findings (see DISCREPANCIES.md).
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import TYPE_CHECKING

from .mapping import DEVICES_ROOT, LUA_ROOT, MatchStatus, build_mapping
from .run import compare_pair
from .verified import VERIFIED_DEVICES, structural_offenders

if TYPE_CHECKING:
    from .compare import Comparison


def _device_key(path: Path, root: Path) -> str | None:
    try:
        rel = path.relative_to(root)
    except ValueError:
        return None
    return rel.parts[0] if len(rel.parts) > 1 else None


def _touched_types(paths: list[Path]) -> tuple[dict[str, set[Path]], set[str]]:
    """Split touched files into ``(lua files by type, python-touched types)``."""
    lua_files: dict[str, set[Path]] = {}
    py_types: set[str] = set()
    for path in paths:
        if not path.exists():
            continue  # deleted, nothing to compare
        key = _device_key(path, LUA_ROOT)
        if key is not None and path.suffix == ".lua":
            lua_files.setdefault(key, set()).add(path)
            continue
        key = _device_key(path, DEVICES_ROOT)
        if key is not None:
            py_types.add(key)
    return lua_files, py_types


def _collect_comparisons(paths: list[Path]) -> list[Comparison]:
    matched = {row.key for row in build_mapping() if row.status is MatchStatus.MATCHED}
    lua_files, py_types = _touched_types(paths)

    comparisons: list[Comparison] = []
    for key in sorted(py_types & matched):
        comparisons.extend(
            compare_pair(key, lua_path)
            for lua_path in sorted((LUA_ROOT / key).glob("*.lua"))
        )
    for key in sorted(lua_files):
        if key in py_types or key not in matched:
            continue  # already covered above, or no midealocal package to check
        comparisons.extend(
            compare_pair(key, lua_path) for lua_path in sorted(lua_files[key])
        )
    return comparisons


def main(argv: list[str] | None = None) -> int:
    """Compare touched device types against their Lua evidence."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("files", nargs="*", help="staged files passed by prek")
    args = parser.parse_args(argv)

    comparisons = _collect_comparisons([Path(f).resolve() for f in args.files])
    if not comparisons:
        return 0

    failed = False
    for cmp in comparisons:
        counts = cmp.counts()
        print(  # noqa: T201 - CLI feedback
            f"[lua-conformance] {cmp.lua_source} vs {cmp.package}: {counts}",
        )
        if cmp.package not in VERIFIED_DEVICES:
            continue
        offenders = structural_offenders(cmp.findings)
        if offenders:
            failed = True
            print(  # noqa: T201 - CLI feedback
                f"  VERIFIED_DEVICES regression in {cmp.package!r}:",
            )
            for finding in offenders:
                print(f"    {finding}")  # noqa: T201 - CLI feedback

    if failed:
        print(  # noqa: T201 - CLI feedback
            "\nlua-conformance: a VERIFIED_DEVICES type gained a structural "
            "MISSING/DIFFERENT finding (field offset/mask, command body-type "
            "or framing). Fix the mismatch, or if it's intentional update the "
            "golden vectors in conformance_<device>_test.py.",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
