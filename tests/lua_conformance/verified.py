"""Devices with hand-written golden vectors -- the regression gate.

Shared between the test suite (``conformance_report_test.py``) and the
pre-commit hook (``precommit_check.py``) so both apply exactly the same
criteria for what counts as a blocking regression.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from .compare import Verdict

if TYPE_CHECKING:
    from .compare import Finding

#: Device types with hand-written golden vectors in a ``conformance_*_test.py``.
#: For these, every Lua file must agree with ``midealocal`` on field offsets,
#: command body-types and framing (name-only enum differences are allowed and
#: covered explicitly in the per-device test).
VERIFIED_DEVICES: tuple[str, ...] = ("e1",)

_STRUCTURAL_AREAS = {"decode_field", "command", "framing"}


def structural_offenders(findings: list[Finding]) -> list[Finding]:
    """Return the findings that fail the VERIFIED_DEVICES regression gate.

    A verified device must not gain a MISSING or wrong-offset finding: a
    MISSING verdict anywhere, or a DIFFERENT verdict in an area that encodes
    protocol structure (field offset/mask, command body-type, framing).
    Name-only enum differences are excluded on purpose -- see
    ``conformance_e1_test.py``.
    """
    return [
        f
        for f in findings
        if f.verdict is Verdict.MISSING
        or (f.verdict is Verdict.DIFFERENT and f.area in _STRUCTURAL_AREAS)
    ]
