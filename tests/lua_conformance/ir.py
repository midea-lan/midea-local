"""Intermediate representation (IR) of protocol facts.

The IR is deliberately small and hand-written.  It is the *only* thing the
comparison layer knows about -- neither Lua syntax nor ``midealocal`` internals
leak past the extractor / introspector boundary.

Both sides of the comparison are lowered into the same shapes:

* :class:`ProtocolDefinition` -- everything extracted from one Lua file.
* :class:`PythonProtocol` (see :mod:`py_introspect`) -- everything introspected
  from one ``midealocal`` device package.  It reuses :class:`Enum`,
  :class:`DecodeField` and :class:`EncodeAssignment` from here.

Byte indices in this module are always expressed in a single common coordinate
system: **offset 0 == the body-type byte**, i.e. the first byte *after* the
10-byte transport header and *before* the trailing checksum.  This is what
``midealocal``'s ``MessageRequest.body`` / ``MessageResponse.body`` expose, and
it is also what the classic Lua ``bodyBytes`` array (produced by
``extractBodyBytes`` / consumed by ``assembleUart``) uses.  The extractor is
responsible for normalising Lua's 1-based ``messageBytes[n]`` reads into this
space (see :mod:`lua_extract`).
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum as _Enum


class Kind(_Enum):
    """High level classification of an extracted fact, used only for reports."""

    CONSTANT = "constant"
    ENUM = "enum"
    DECODE_FIELD = "decode_field"
    ENCODE_ASSIGNMENT = "encode_assignment"
    COMMAND = "command"


@dataclass(frozen=True)
class SourceRef:
    """Where a fact came from -- ``path`` plus 1-based ``line`` when known."""

    path: str
    line: int | None = None

    def __str__(self) -> str:
        """Render as ``path:line`` (or just ``path``)."""
        return f"{self.path}:{self.line}" if self.line else self.path


@dataclass(frozen=True)
class Constant:
    """A named scalar constant (``local BYTE_MODE_COOL = 0x40``)."""

    name: str
    value: int | str
    source: SourceRef | None = None

    @property
    def stem(self) -> str:
        """Return the name with a leading ``BYTE_`` / ``VALUE_`` / ``KEY_`` removed."""
        for prefix in ("BYTE_", "VALUE_", "KEY_", "STR_", "ENUM_"):
            if self.name.startswith(prefix):
                return self.name[len(prefix) :]
        return self.name


@dataclass(frozen=True)
class Enum:
    """A group of related constants that form an enumeration.

    ``members`` maps the *logical* short name (``COOL``) to its protocol value.
    For a byte enum the value is an ``int``; for a "value" enum (the strings the
    Lua exposes to the app / cloud) the value is a ``str``.
    """

    name: str
    members: dict[str, int | str]
    source: SourceRef | None = None

    def by_value(self) -> dict[int | str, str]:
        """Return the reverse mapping (protocol value -> logical name)."""
        return {v: k for k, v in self.members.items()}


@dataclass(frozen=True)
class DecodeField:
    """One field read out of a response/notify body.

    ``value = (body[byte] & mask) >> shift`` followed by an optional
    ``transform`` (a free-form string such as ``"(x - 50) / 2"`` preserved
    verbatim from the source for the report).  ``mask`` defaults to ``0xFF``
    (whole byte) and ``shift`` to ``0``.
    """

    name: str
    byte: int
    mask: int = 0xFF
    shift: int = 0
    transform: str | None = None
    boolean: bool = False
    source: SourceRef | None = None

    def signature(self) -> tuple[int, int, int]:
        """Return the ``(byte, mask, shift)`` triple used for structural matching."""
        return (self.byte, self.mask, self.shift)


@dataclass(frozen=True)
class EncodeAssignment:
    """One byte written while building a request body.

    ``body[byte]`` is set from ``expr`` (verbatim source text) which references
    ``refs`` (the set of logical variable / constant names that appear in it).
    ``static_value`` is filled in when ``expr`` is a plain constant.
    """

    byte: int
    expr: str
    refs: frozenset[str] = frozenset()
    static_value: int | None = None
    source: SourceRef | None = None


@dataclass(frozen=True)
class Command:
    """A request the Lua knows how to build.

    ``body_type`` is the value written to ``body[0]`` (``None`` when it could
    not be determined statically).  ``trigger_key`` is the ``control``/``query``
    JSON key that selects this command, when the Lua dispatches on one.
    """

    name: str
    body_type: int | None
    trigger_key: str | None = None
    assignments: tuple[EncodeAssignment, ...] = ()
    request_type: int | None = None
    source: SourceRef | None = None


@dataclass
class ProtocolDefinition:
    """Everything statically extracted from a single Lua file."""

    source: str
    device_type: int | None = None
    lua_version: int | None = None
    model_ids: tuple[str, ...] = ()
    constants: dict[str, Constant] = field(default_factory=dict)
    enums: dict[str, Enum] = field(default_factory=dict)
    decode_fields: list[DecodeField] = field(default_factory=list)
    encode_assignments: list[EncodeAssignment] = field(default_factory=list)
    commands: list[Command] = field(default_factory=list)
    framing: dict[str, int] = field(default_factory=dict)
    #: Lines the extractor recognised as "interesting" but could not lower into
    #: the IR.  Surfaced in the report so nothing is silently dropped.
    unparsed: list[str] = field(default_factory=list)

    def decode_field(self, name: str) -> DecodeField | None:
        """Return the first decode field named ``name`` (case-insensitive)."""
        lowered = name.lower()
        return next(
            (f for f in self.decode_fields if f.name.lower() == lowered),
            None,
        )

    def enum(self, *candidates: str) -> Enum | None:
        """Return the first enum whose name matches any of ``candidates``."""
        for candidate in candidates:
            lowered = candidate.lower()
            for name, enum in self.enums.items():
                if name.lower() == lowered:
                    return enum
        return None

    def paired_enum(self, category: str) -> dict[int, str]:
        """Return ``{byte_value: logical_string}`` for a ``BYTE_``/``VALUE_`` pair.

        ``category`` is matched case-insensitively against the ``BYTE_`` enum
        (``<CAT>``) and the ``VALUE_`` enum (``<CAT>_VALUES``); members present
        in both are combined.  Falls back to the member name (lower-cased) when
        no ``VALUE_`` string exists for a member.
        """
        byte_enum = self.enum(category)
        value_enum = self.enum(f"{category}_VALUES")
        if byte_enum is None:
            return {}
        values = value_enum.members if value_enum else {}
        out: dict[int, str] = {}
        for member, raw in byte_enum.members.items():
            if not isinstance(raw, int):
                continue
            logical = values.get(member, member.lower())
            out[raw] = str(logical)
        return out
