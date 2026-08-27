"""Lua protocol-conformance verification framework for ``midea-local``.

This package builds a reusable test/verification framework that compares the
protocol behavior implemented by ``midealocal`` against the protocol behavior
that can be *statically* extracted from the proprietary Midea Lua plugin files
stored under ``lua/`` at the repository root.

See ``README.md`` in this directory for the full design, usage and rationale.
"""

from __future__ import annotations

from .compare import Comparison, Finding, Verdict, compare, normalize_name
from .ir import (
    Command,
    DecodeField,
    EncodeAssignment,
    Enum,
    ProtocolDefinition,
)
from .lua_extract import extract_from_file, extract_from_source
from .mapping import DeviceMapping, MatchStatus, build_mapping
from .py_introspect import PythonProtocol, introspect_device
from .run import compare_pair, generate_all, iter_pairs

__all__ = [
    "Command",
    "Comparison",
    "DecodeField",
    "DeviceMapping",
    "EncodeAssignment",
    "Enum",
    "Finding",
    "MatchStatus",
    "ProtocolDefinition",
    "PythonProtocol",
    "Verdict",
    "build_mapping",
    "compare",
    "compare_pair",
    "extract_from_file",
    "extract_from_source",
    "generate_all",
    "introspect_device",
    "iter_pairs",
    "normalize_name",
]
