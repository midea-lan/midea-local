"""Build / load the conformance regression baseline.

The baseline is a sorted list of ``"package | verdict | area | name"`` strings
for every ``MISSING`` and ``DIFFERENT`` finding across all mapped comparisons.
The regression test asserts the live run reproduces exactly this set, so a code
change that introduces a *new* protocol discrepancy fails CI, while genuine
fixes are applied by regenerating the file (``python -m tests.lua_conformance
--baseline``) and reviewing the diff.
"""

from __future__ import annotations

import json
from pathlib import Path

from .compare import Verdict
from .run import generate_all

BASELINE_PATH = Path(__file__).parent / "conformance_baseline.json"
_TRACKED = (Verdict.MISSING, Verdict.DIFFERENT)


def current_discrepancies(*, limit_per_dir: int | None = None) -> list[str]:
    """Return the sorted discrepancy keys for the live comparison run."""
    keys: set[str] = set()
    for cmp in generate_all(limit_per_dir=limit_per_dir):
        for finding in cmp.findings:
            if finding.verdict in _TRACKED:
                keys.add(
                    f"{cmp.package} | {finding.verdict.value} | "
                    f"{finding.area} | {finding.name}",
                )
    return sorted(keys)


def load_baseline() -> list[str]:
    """Load the checked-in baseline discrepancy keys."""
    data = json.loads(BASELINE_PATH.read_text(encoding="utf-8"))
    return [str(item) for item in data]


def write_baseline(*, limit_per_dir: int | None = None) -> int:
    """Regenerate ``conformance_baseline.json`` from the live run."""
    keys = current_discrepancies(limit_per_dir=limit_per_dir)
    BASELINE_PATH.write_text(json.dumps(keys, indent=2) + "\n", encoding="utf-8")
    return len(keys)
