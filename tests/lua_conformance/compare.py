"""Comparison engine: Lua IR vs ``midealocal`` introspection -> findings.

Every comparison yields one or more :class:`Finding` objects carrying a
:class:`Verdict`:

``MATCH``    the Lua-derived fact and the Python implementation agree.
``MISSING``  the Lua file specifies something with no Python counterpart.
``DIFFERENT`` both sides implement the thing but disagree on a value/offset.
``UNKNOWN``  the comparison could not be made reliably (surfaced, never hidden).

A ``MISSING``/``DIFFERENT`` verdict is a *candidate* discrepancy, not a proven
bug -- it may be an unsupported feature, a device/model variation, a protocol
version difference or an intentional abstraction.  ``Finding.detail`` records
what is known; triage stays a human step.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from enum import Enum
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from .ir import DecodeField, ProtocolDefinition
    from .py_introspect import PythonProtocol


class Verdict(Enum):
    """Outcome of a single comparison."""

    MATCH = "MATCH"
    MISSING = "MISSING"
    DIFFERENT = "DIFFERENT"
    UNKNOWN = "UNKNOWN"


@dataclass(frozen=True)
class Finding:
    """One comparison result."""

    verdict: Verdict
    area: str
    name: str
    detail: str
    lua_source: str | None = None
    lua_repr: str | None = None
    py_repr: str | None = None
    example: str | None = None

    def __str__(self) -> str:
        """Render a compact one-block human-readable form."""
        lines = [
            f"[{self.verdict.value}] {self.area}: {self.name}",
            f"    {self.detail}",
        ]
        if self.lua_source:
            lines.append(f"    lua source : {self.lua_source}")
        if self.lua_repr:
            lines.append(f"    lua        : {self.lua_repr}")
        if self.py_repr:
            lines.append(f"    midealocal : {self.py_repr}")
        if self.example:
            lines.append(f"    example    : {self.example}")
        return "\n".join(lines)


@dataclass
class Comparison:
    """All findings for one Lua-file / device-package pair."""

    lua_source: str
    package: str
    findings: list[Finding] = field(default_factory=list)

    def by_verdict(self, verdict: Verdict) -> list[Finding]:
        """Return findings with the given verdict."""
        return [f for f in self.findings if f.verdict is verdict]

    def counts(self) -> dict[str, int]:
        """Return ``{verdict_name: count}`` across all findings."""
        out = {v.value: 0 for v in Verdict}
        for finding in self.findings:
            out[finding.verdict.value] += 1
        return out

    @property
    def ok(self) -> bool:
        """True when nothing is ``MISSING`` or ``DIFFERENT``."""
        return not any(
            f.verdict in (Verdict.MISSING, Verdict.DIFFERENT) for f in self.findings
        )


#: Lua decode-variable name (snake_case, after ``_value`` strip)  ->  midealocal
#: attribute name.  Kept small and conservative; add entries as real files need
#: them (see README "Adding a new comparison").
_NAME_ALIASES: dict[str, str] = {
    "work_status": "status",
    "runstate": "status",
    "left_time": "time_remaining",
    "remain_time": "time_remaining",
    "wash_stage": "progress",
    "errorcode": "error_code",
    "fanspeed": "fan_speed",
    "windspeed": "fan_speed",
    "wind_speed": "fan_speed",
}


def _camel_to_snake(name: str) -> str:
    # keep acronym runs together: PTCValue -> ptc_value, indoorTemp -> indoor_temp
    name = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", name)
    name = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", name)
    return name.lower()


def normalize_name(name: str) -> str:
    """Canonicalise a field name for cross-implementation matching.

    ``camelCase`` -> ``snake_case``, a *single* conservative suffix strip of
    ``_value`` (a pure Lua-ism: ``powerValue``, ``modeValue``), then a curated
    alias table.  ``_switch`` / ``_status`` are deliberately kept -- Midea
    firmware exposes e.g. ``dry`` and ``dry_status`` as distinct signals.
    """
    snake = re.sub(r"_+", "_", _camel_to_snake(name).strip("_"))
    if snake.endswith("_value") and snake != "_value":
        snake = snake[: -len("_value")]
    return _NAME_ALIASES.get(snake, snake)


def _norm_enum_value(value: str) -> str:
    return re.sub(r"[^a-z0-9]", "", value.lower())


_ENUM_PAIRS: tuple[tuple[str, tuple[str, ...]], ...] = (
    ("MODE", ("modes", "mode")),
    ("STATUS", ("status", "work_status", "run_status")),
    ("FANSPEED", ("speeds", "fan_speeds", "speed", "fan_speed")),
    ("WINDSPEED", ("speeds", "fan_speeds", "speed")),
    ("SWING", ("swing", "swing_modes")),
    ("PROGRESS", ("progress",)),
)


def _compare_identity(
    lua: ProtocolDefinition,
    py: PythonProtocol,
    out: list[Finding],
) -> None:
    if lua.device_type is None or py.device_type is None:
        out.append(
            Finding(
                Verdict.UNKNOWN,
                "identity",
                "device_type",
                "could not read device-type byte on one side",
                lua_source=lua.source,
                lua_repr=_hex(lua.device_type),
                py_repr=_hex(py.device_type),
            ),
        )
        return
    verdict = Verdict.MATCH if lua.device_type == py.device_type else Verdict.DIFFERENT
    out.append(
        Finding(
            verdict,
            "identity",
            "device_type",
            "Lua BYTE_DEVICE_TYPE vs midealocal DeviceType",
            lua_source=lua.source,
            lua_repr=_hex(lua.device_type),
            py_repr=_hex(py.device_type),
        ),
    )


def _hex(value: int | None) -> str | None:
    return None if value is None else f"0x{value:02X}"


def _enum_src(lua: ProtocolDefinition, category: str) -> str | None:
    enum = lua.enum(category)
    return str(enum.source) if enum and enum.source else None


def _compare_enums(
    lua: ProtocolDefinition,
    py: PythonProtocol,
    out: list[Finding],
) -> None:
    for lua_cat, py_names in _ENUM_PAIRS:
        lua_map = lua.paired_enum(lua_cat)
        if not lua_map:
            continue
        src = _enum_src(lua, lua_cat)
        label = lua_cat.lower()
        py_enum = py.enum(*py_names)
        if py_enum is None:
            out.append(
                Finding(
                    Verdict.UNKNOWN,
                    "enum",
                    label,
                    f"Lua defines a {lua_cat} enum with {len(lua_map)} values; "
                    f"midealocal exposes no equivalent {{int: name}} table "
                    f"(it may map these values implicitly in device code)",
                    lua_source=src,
                    lua_repr=_fmt_enum(lua_map),
                ),
            )
            continue
        py_by_value = {v: k for k, v in _int_keyed(py_enum.members).items()}
        for value, lua_name in sorted(lua_map.items()):
            name = f"{label}[0x{value:02X}]"
            py_name = py_by_value.get(value)
            if py_name is None:
                out.append(
                    Finding(
                        Verdict.MISSING,
                        "enum",
                        name,
                        f"Lua maps 0x{value:02X} -> {lua_name!r}; "
                        f"midealocal has no entry for that value",
                        lua_source=src,
                        lua_repr=f"0x{value:02X} -> {lua_name!r}",
                    ),
                )
            elif _norm_enum_value(py_name) == _norm_enum_value(lua_name):
                out.append(
                    Finding(
                        Verdict.MATCH,
                        "enum",
                        name,
                        f"both map 0x{value:02X} -> {lua_name!r}",
                        lua_source=src,
                    ),
                )
            else:
                out.append(
                    Finding(
                        Verdict.DIFFERENT,
                        "enum",
                        name,
                        "same protocol value, different logical name",
                        lua_source=src,
                        lua_repr=f"0x{value:02X} -> {lua_name!r}",
                        py_repr=f"0x{value:02X} -> {py_name!r}",
                    ),
                )


def _int_keyed(members: dict[str, int | str]) -> dict[str, int]:
    return {k: v for k, v in members.items() if isinstance(v, int)}


def _fmt_enum(mapping: dict[int, str]) -> str:
    return ", ".join(f"0x{k:02X}={v}" for k, v in sorted(mapping.items()))


def _compare_decode_fields(
    lua: ProtocolDefinition,
    py: PythonProtocol,
    out: list[Finding],
) -> None:
    py_by_name = {normalize_name(f.name): f for f in py.decode_fields}
    py_by_sig: dict[tuple[int, int, int], list[str]] = {}
    for f in py.decode_fields:
        py_by_sig.setdefault(f.signature(), []).append(f.name)

    for lf in lua.decode_fields:
        key = normalize_name(lf.name)
        pf = py_by_name.get(key)
        if pf is not None:
            if lf.signature() == pf.signature():
                out.append(
                    Finding(
                        Verdict.MATCH,
                        "decode_field",
                        key,
                        f"both read byte[{lf.byte}] mask 0x{lf.mask:02X} >> {lf.shift}",
                        lua_source=str(lf.source),
                        lua_repr=f"{lf.name} = byte[{lf.byte}] & 0x{lf.mask:02X} "
                        f">> {lf.shift}",
                        py_repr=f"{pf.name} = byte[{pf.byte}] & 0x{pf.mask:02X} "
                        f">> {pf.shift}",
                    ),
                )
            elif _right_align_equivalent(lf, pf):
                out.append(
                    Finding(
                        Verdict.UNKNOWN,
                        "decode_field",
                        key,
                        "likely equivalent: Lua keeps the masked bits in place "
                        "while midealocal right-aligns them; compare the enum "
                        "mappings, not the raw integers",
                        lua_source=str(lf.source),
                        lua_repr=f"byte[{lf.byte}] & 0x{lf.mask:02X} >> {lf.shift}",
                        py_repr=f"byte[{pf.byte}] & 0x{pf.mask:02X} >> {pf.shift}",
                    ),
                )
            else:
                out.append(
                    Finding(
                        Verdict.DIFFERENT,
                        "decode_field",
                        key,
                        "field parsed from a different offset/mask/shift",
                        lua_source=str(lf.source),
                        lua_repr=f"byte[{lf.byte}] & 0x{lf.mask:02X} >> {lf.shift}"
                        + (f"  ({lf.transform})" if lf.transform else ""),
                        py_repr=f"byte[{pf.byte}] & 0x{pf.mask:02X} >> {pf.shift}"
                        + (f"  ({pf.transform})" if pf.transform else ""),
                        example=_decode_example(lf, pf),
                    ),
                )
            continue

        sig_owner = py_by_sig.get(lf.signature())
        if sig_owner:
            out.append(
                Finding(
                    Verdict.MATCH,
                    "decode_field",
                    key,
                    "no name match, but midealocal reads the identical "
                    f"byte[{lf.byte}] & 0x{lf.mask:02X} >> {lf.shift} "
                    f"as {sig_owner[0]!r}",
                    lua_source=str(lf.source),
                    lua_repr=f"{lf.name} = byte[{lf.byte}] & 0x{lf.mask:02X}",
                    py_repr=f"{sig_owner[0]} = byte[{lf.byte}] & 0x{lf.mask:02X}",
                ),
            )
        else:
            out.append(
                Finding(
                    Verdict.MISSING,
                    "decode_field",
                    key,
                    f"Lua reads {lf.name!r} from byte[{lf.byte}] "
                    f"(mask 0x{lf.mask:02X}, shift {lf.shift}); "
                    f"midealocal parses nothing there",
                    lua_source=str(lf.source),
                    lua_repr=f"{lf.name} = byte[{lf.byte}] & 0x{lf.mask:02X} "
                    f">> {lf.shift}" + (f"  ({lf.transform})" if lf.transform else ""),
                ),
            )

    lua_keys = {normalize_name(f.name) for f in lua.decode_fields}
    lua_sigs = {lf.signature() for lf in lua.decode_fields}
    out.extend(
        Finding(
            Verdict.UNKNOWN,
            "decode_field",
            normalize_name(pf.name),
            "midealocal parses this field but this Lua file does not "
            "(newer protocol, another model, or Lua omission)",
            py_repr=f"{pf.name} = byte[{pf.byte}] & 0x{pf.mask:02X} >> {pf.shift}",
        )
        for pf in py.decode_fields
        if normalize_name(pf.name) not in lua_keys and pf.signature() not in lua_sigs
    )


def _trailing_zero_bits(mask: int) -> int:
    if mask <= 0:
        return 0
    count = 0
    while not mask & 1:
        mask >>= 1
        count += 1
    return count


def _right_align_equivalent(lua_f: DecodeField, py_f: DecodeField) -> bool:
    """Report whether the two reads select the same bits, one raw and one shifted.

    ``lua: byte[i] & 0xE0``  vs  ``py: (byte[i] & 0xE0) >> 5`` -- same physical
    field, different integer convention (Lua leaves enum bits high, midealocal
    right-aligns to a small index).  Not a protocol discrepancy.
    """
    return (
        lua_f.byte == py_f.byte
        and lua_f.mask == py_f.mask
        and {lua_f.shift, py_f.shift} == {0, _trailing_zero_bits(lua_f.mask)}
        and _trailing_zero_bits(lua_f.mask) > 0
    )


def _decode_example(lua_f: DecodeField, py_f: DecodeField) -> str:
    probe = 0x24
    lua_val = (probe & lua_f.mask) >> lua_f.shift
    py_val = (probe & py_f.mask) >> py_f.shift
    return f"raw byte 0x{probe:02X} -> lua {lua_val}, midealocal {py_val}"


def _compare_commands(
    lua: ProtocolDefinition,
    py: PythonProtocol,
    out: list[Finding],
) -> None:
    py_body_types = {c.body_type for c in py.commands if c.body_type is not None}
    seen: set[int] = set()
    for cmd in lua.commands:
        if cmd.body_type is None or cmd.body_type in seen:
            continue
        seen.add(cmd.body_type)
        if cmd.body_type in py_body_types:
            owners = [c.name for c in py.commands if c.body_type == cmd.body_type]
            out.append(
                Finding(
                    Verdict.MATCH,
                    "command",
                    f"body_type 0x{cmd.body_type:02X}",
                    f"Lua builds a request with body[0]=0x{cmd.body_type:02X}; "
                    f"midealocal has {', '.join(owners)}",
                    lua_source=str(cmd.source),
                    lua_repr=f"trigger={cmd.trigger_key!r}",
                ),
            )
        else:
            out.append(
                Finding(
                    Verdict.MISSING,
                    "command",
                    f"body_type 0x{cmd.body_type:02X}",
                    f"Lua builds a request with body[0]=0x{cmd.body_type:02X} "
                    f"(trigger {cmd.trigger_key!r}); no midealocal Message* "
                    f"emits that body type",
                    lua_source=str(cmd.source),
                ),
            )


def _compare_framing(lua: ProtocolDefinition, out: list[Finding]) -> None:
    head = lua.framing.get("BYTE_PROTOCOL_HEAD")
    if head is not None:
        out.append(
            Finding(
                Verdict.MATCH if head == 0xAA else Verdict.DIFFERENT,
                "framing",
                "protocol_head",
                "packet start byte",
                lua_source=lua.source,
                lua_repr=_hex(head),
                py_repr="0xAA",
            ),
        )
    length = lua.framing.get("BYTE_PROTOCOL_LENGTH")
    if length is not None:
        out.append(
            Finding(
                Verdict.MATCH if length == 10 else Verdict.UNKNOWN,
                "framing",
                "header_length",
                "bytes before the body (MessageBase.HEADER_LENGTH)"
                if length == 10
                else "Lua uses a non-standard header length; its byte offsets "
                "are in a different coordinate system than midealocal's body",
                lua_source=lua.source,
                lua_repr=str(length),
                py_repr="10",
            ),
        )


def compare(lua: ProtocolDefinition, py: PythonProtocol) -> Comparison:
    """Compare a Lua :class:`ProtocolDefinition` against a :class:`PythonProtocol`."""
    result = Comparison(lua_source=lua.source, package=py.package)
    out = result.findings
    _compare_identity(lua, py, out)
    _compare_framing(lua, out)
    _compare_enums(lua, py, out)

    header_len = lua.framing.get("BYTE_PROTOCOL_LENGTH")
    if header_len not in (None, 10):
        out.append(
            Finding(
                Verdict.UNKNOWN,
                "decode_field",
                "*",
                f"skipped byte-offset comparison: this Lua file frames bodies "
                f"after a {header_len}-byte header (T_0008 container), so its "
                f"messageBytes[i] indices do not line up with midealocal's "
                f"10-byte-header body[i]",
                lua_source=lua.source,
            ),
        )
    else:
        _compare_decode_fields(lua, py, out)
        _compare_commands(lua, py, out)
    for note in lua.unparsed:
        out.append(
            Finding(
                Verdict.UNKNOWN,
                "extractor",
                "unparsed",
                note,
                lua_source=lua.source,
            ),
        )
    for note in py.notes:
        out.append(
            Finding(
                Verdict.UNKNOWN,
                "introspection",
                "note",
                note,
                lua_source=py.package,
            ),
        )
    return result
