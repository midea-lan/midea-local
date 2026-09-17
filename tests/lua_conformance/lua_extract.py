"""Static extraction of protocol facts from Midea Lua plugin files.

No Lua runtime is used.  The proprietary files are protocol *descriptions*
implemented in a small, extremely repetitive subset of Lua, and every fact we
need (constants, enum tables, byte offsets, masks, encode/decode formulas) is
recoverable with line-oriented parsing.  Anything the extractor recognises as
protocol-relevant but cannot lower into the IR is recorded in
``ProtocolDefinition.unparsed`` so it is visible in the report rather than
silently dropped.

The extractor targets the "classic" Lua structure shared by the large majority
of the collected files:

* a block of ``local KEY_* / VALUE_* / BYTE_*`` constant definitions;
* a ``jsonToData`` function that builds request bodies (``bodyBytes[i] = ...``);
* an ``updateGlobalPropertyValueByByte`` / ``binToModel`` function that reads
  response bodies (``var = bit.band(messageBytes[i], MASK)`` etc).

Files that deviate structurally still yield their constants and enums; their
command/field extraction simply degrades to ``unparsed`` entries, which the
mapping/report layer treats as ``UNKNOWN`` coverage rather than a failure.
"""

from __future__ import annotations

import re
from pathlib import Path

from .ir import (
    Command,
    Constant,
    DecodeField,
    EncodeAssignment,
    Enum,
    ProtocolDefinition,
    SourceRef,
)

_HEX_OR_INT = r"0[xX][0-9A-Fa-f]+|\d+"
_NUM_RE = re.compile(rf"^(?:{_HEX_OR_INT})$")

_LOCAL_CONST_RE = re.compile(
    r"^\s*(?:local\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"
    r"(0[xX][0-9A-Fa-f]+|\d+|\"[^\"]*\"|'[^']*')\s*(?:--.*)?$",
)

_DECODE_FUNCS = (
    "updateGlobalPropertyValueByByte",
    "binToModel",
    "dataToModel",
    "updateStatusByByte",
)
_ENCODE_FUNCS = ("jsonToData",)

# Decode-line regexes.  Each captures a Lua statement that reads one response
# byte into a variable; the names in the trailing docstring-style note describe
# the captured groups (identifier, byte index, optional mask, optional shift).
_D_BAND_RSHIFT = re.compile(  # ident = bit.rshift(bit.band(messageBytes[i], MASK), N)
    r"([A-Za-z_]\w*)\s*=\s*bit\.rshift\(\s*bit\.band\(\s*(?:messageBytes|binData)"
    r"\[(\d+)\]\s*,\s*([0-9A-Fa-fxX]+)\s*\)\s*,\s*(\d+)\s*\)",
)
_D_BAND_LSHIFT = re.compile(  # ident = bit.lshift(bit.band(messageBytes[i], MASK), N)
    r"([A-Za-z_]\w*)\s*=\s*bit\.lshift\(\s*bit\.band\(\s*(?:messageBytes|binData)"
    r"\[(\d+)\]\s*,\s*([0-9A-Fa-fxX]+)\s*\)\s*,\s*(\d+)\s*\)",
)
_D_BAND = re.compile(  # ident = bit.band(messageBytes[i], MASK)
    r"([A-Za-z_]\w*)\s*=\s*bit\.band\(\s*(?:messageBytes|binData)"
    r"\[(\d+)\]\s*,\s*([0-9A-Fa-fxX]+)\s*\)",
)
_D_RSHIFT = re.compile(  # ident = bit.rshift(messageBytes[i], N)
    r"([A-Za-z_]\w*)\s*=\s*bit\.rshift\(\s*(?:messageBytes|binData)"
    r"\[(\d+)\]\s*,\s*(\d+)\s*\)",
)
_D_ARITH = re.compile(  # ident = (messageBytes[i] - N) / M  (any arithmetic wrapper)
    r"([A-Za-z_]\w*)\s*=\s*(\(?\s*(?:messageBytes|binData)\[(\d+)\][^\n]*?)\s*$",
)
_D_PLAIN = re.compile(  # ident = messageBytes[i]
    r"([A-Za-z_]\w*)\s*=\s*(?:messageBytes|binData)\[(\d+)\]\s*(?:--.*)?$",
)

_E_ASSIGN = re.compile(  # bodyBytes[i] = <expr>
    r"(?:bodyBytes|bodyByte|bodyData|body)\[(\d+)\]\s*=\s*(.+)",
)

_IDENT_RE = re.compile(r"[A-Za-z_]\w*")

_MODEL_ID_RE = re.compile(r"^T_[0-9A-Fa-f]{4}_[0-9A-Za-z]+_([0-9A-Za-z]+)_")


def _to_int(token: str) -> int | None:
    token = token.strip()
    try:
        return int(token, 0)
    except ValueError:
        return None


def _resolve(token: str, consts: dict[str, Constant]) -> int | None:
    token = token.strip()
    direct = _to_int(token)
    if direct is not None:
        return direct
    const = consts.get(token)
    if const is not None and isinstance(const.value, int):
        return const.value
    return None


def _function_body(source: str, name: str) -> tuple[str, int] | None:
    """Return ``(body_text, start_line)`` for a top-level ``function name(...)``.

    The classic files put the closing ``end`` of every top-level function at
    column 0, so a non-greedy match up to ``^end`` is reliable.
    """
    pattern = re.compile(
        rf"^function\s+{re.escape(name)}\s*\([^)]*\)\s*\n(.*?)\n^end\s*$",
        re.DOTALL | re.MULTILINE,
    )
    match = pattern.search(source)
    if not match:
        return None
    start_line = source[: match.start()].count("\n") + 1
    return match.group(1), start_line


def _iter_logical_lines(body: str) -> list[tuple[int, str]]:
    """Yield ``(offset_line, joined_line)`` merging paren-continued Lua lines."""
    out: list[tuple[int, str]] = []
    buf = ""
    buf_line = 0
    depth = 0
    for idx, raw in enumerate(body.splitlines()):
        line = raw.split("--", 1)[0].rstrip() if "--" in raw else raw.rstrip()
        if not buf:
            buf_line = idx
        buf = line if not buf else f"{buf} {line.strip()}"
        depth += line.count("(") - line.count(")")
        if depth <= 0:
            out.append((buf_line, buf.strip()))
            buf = ""
            depth = 0
    if buf:
        out.append((buf_line, buf.strip()))
    return out


def _extract_constants(source: str, path: str) -> dict[str, Constant]:
    consts: dict[str, Constant] = {}
    for lineno, raw in enumerate(source.splitlines(), start=1):
        match = _LOCAL_CONST_RE.match(raw)
        if not match:
            continue
        name, rhs = match.group(1), match.group(2)
        if rhs[0] in "\"'":
            value: int | str = rhs[1:-1]
        else:
            parsed = _to_int(rhs)
            if parsed is None:
                continue
            value = parsed
        consts[name] = Constant(name, value, SourceRef(path, lineno))
    return consts


#: Category tokens that never form a meaningful enum on their own.
_ENUM_STOPWORDS = frozenset(
    {"PROTOCOL", "DEVICE", "CONTROL", "QUERY", "REQUEST", "CMD", "HEAD", "LENGTH"},
)


def _extract_enums(consts: dict[str, Constant], path: str) -> dict[str, Enum]:
    """Group ``BYTE_<CAT>_<MEMBER>`` / ``VALUE_<CAT>_<MEMBER>`` constants.

    ``BYTE_`` constants produce an ``<CAT>`` enum with ``int`` values; the
    matching ``VALUE_`` constants produce ``<CAT>_VALUES`` with ``str`` values.
    Members may themselves be multi-word (``AUTO_WASH``), so the *first* token
    after the prefix is the category and the remainder is the member name.
    """
    byte_groups: dict[str, dict[str, int | str]] = {}
    value_groups: dict[str, dict[str, int | str]] = {}
    group_line: dict[str, int] = {}
    for const in consts.values():
        if const.name.startswith("BYTE_"):
            groups = byte_groups
        elif const.name.startswith("VALUE_"):
            groups = value_groups
        else:
            continue
        parts = const.stem.split("_")
        if len(parts) < 2 or len(parts[0]) < 2:
            continue
        category, member = parts[0], "_".join(parts[1:])
        if category in _ENUM_STOPWORDS:
            continue
        groups.setdefault(category, {})[member] = const.value
        if const.source and const.source.line:
            group_line.setdefault(category, const.source.line)

    enums: dict[str, Enum] = {}
    for category, members in byte_groups.items():
        if len(members) >= 2:
            enums[category] = Enum(
                category,
                members,
                SourceRef(path, group_line.get(category)),
            )
    for category, members in value_groups.items():
        if len(members) >= 2:
            name = f"{category}_VALUES"
            enums[name] = Enum(
                name,
                members,
                SourceRef(path, group_line.get(category)),
            )
    return enums


def _extract_decode_fields(
    source: str,
    consts: dict[str, Constant],
    path: str,
) -> list[DecodeField]:
    fields: list[DecodeField] = []
    seen: set[tuple[str, int, int, int]] = set()
    for func in _DECODE_FUNCS:
        found = _function_body(source, func)
        if not found:
            continue
        body, start = found
        for off, line in _iter_logical_lines(body):
            lineno = start + off
            field = _match_decode_line(line, consts, SourceRef(path, lineno))
            if field is None:
                continue
            key = (field.name.lower(), field.byte, field.mask, field.shift)
            if key in seen:
                continue
            seen.add(key)
            fields.append(field)
    return fields


def _match_decode_line(  # noqa: PLR0911
    line: str,
    consts: dict[str, Constant],
    ref: SourceRef,
) -> DecodeField | None:
    match = _D_BAND_RSHIFT.search(line)
    if match:
        mask = _resolve(match.group(3), consts)
        return DecodeField(
            match.group(1),
            int(match.group(2)),
            mask if mask is not None else 0xFF,
            int(match.group(4)),
            source=ref,
        )
    match = _D_BAND_LSHIFT.search(line)
    if match:
        mask = _resolve(match.group(3), consts)
        return DecodeField(
            match.group(1),
            int(match.group(2)),
            mask if mask is not None else 0xFF,
            0,
            transform=f"<< {match.group(4)}",
            source=ref,
        )
    match = _D_BAND.search(line)
    if match:
        mask = _resolve(match.group(3), consts)
        return DecodeField(
            match.group(1),
            int(match.group(2)),
            mask if mask is not None else 0xFF,
            0,
            boolean=mask is not None and mask.bit_count() == 1,
            source=ref,
        )
    match = _D_RSHIFT.search(line)
    if match:
        return DecodeField(
            match.group(1),
            int(match.group(2)),
            0xFF,
            int(match.group(3)),
            source=ref,
        )
    match = _D_PLAIN.search(line)
    if match:
        return DecodeField(match.group(1), int(match.group(2)), source=ref)
    match = _D_ARITH.search(line)
    if match and any(op in match.group(2) for op in ("+", "-", "/", "*")):
        return DecodeField(
            match.group(1),
            int(match.group(3)),
            transform=match.group(2).strip(),
            source=ref,
        )
    return None


class _CommandAcc:
    """Mutable accumulator for the request currently being parsed out of Lua."""

    def __init__(self) -> None:
        self.trigger: str | None = None
        self.reqtype: int | None = None
        self.assigns: list[EncodeAssignment] = []
        self.bodytype: int | None = None

    def flush(self, commands: list[Command], ref: SourceRef) -> None:
        """Emit the accumulated assignments as a :class:`Command`, then reset."""
        if self.assigns:
            commands.append(
                Command(
                    name=self.trigger or "command",
                    body_type=self.bodytype,
                    trigger_key=self.trigger,
                    assignments=tuple(self.assigns),
                    request_type=self.reqtype,
                    source=ref,
                ),
            )
        self.assigns = []
        self.bodytype = None


def _extract_encode(
    source: str,
    consts: dict[str, Constant],
    path: str,
) -> tuple[list[EncodeAssignment], list[Command]]:
    assignments: list[EncodeAssignment] = []
    commands: list[Command] = []
    for func in _ENCODE_FUNCS:
        found = _function_body(source, func)
        if not found:
            continue
        body, start = found
        ref = SourceRef(path, start)
        acc = _CommandAcc()

        for off, line in _iter_logical_lines(body):
            lineno = start + off
            trig = re.search(r"(?:control|query|json)\[([A-Za-z_]\w*)\]", line)
            if ("if " in line or "elseif " in line) and trig:
                acc.flush(commands, ref)
                key_const = consts.get(trig.group(1))
                acc.trigger = str(key_const.value) if key_const else trig.group(1)
            elif re.search(r"\bif\s*\(?\s*query\s*\)?", line):
                acc.flush(commands, ref)
                acc.trigger = "query"
            elif re.search(r"\belseif\s*\(?\s*control\s*\)?", line):
                acc.flush(commands, ref)
                acc.trigger = "control"

            reqmatch = re.search(
                r"assemble\w*\([^,]+,\s*([A-Za-z_]\w*)\)|getTotalMsg\([^,]+,\s*"
                r"([A-Za-z_]\w*)\)",
                line,
            )
            if reqmatch:
                token = reqmatch.group(1) or reqmatch.group(2)
                acc.reqtype = _resolve(token, consts)

            match = _E_ASSIGN.search(line)
            if not match:
                continue
            byte = int(match.group(1))
            expr = match.group(2).strip()
            refs = frozenset(
                tok for tok in _IDENT_RE.findall(expr) if tok in consts or tok.islower()
            )
            static = _resolve(expr, consts)
            assign = EncodeAssignment(byte, expr, refs, static, SourceRef(path, lineno))
            assignments.append(assign)
            acc.assigns.append(assign)
            if byte == 0 and static is not None:
                acc.bodytype = static
        acc.flush(commands, ref)
    return assignments, commands


def _extract_identity(
    consts: dict[str, Constant],
    path: str,
) -> tuple[int | None, int | None, tuple[str, ...]]:
    device_type = None
    dt = consts.get("BYTE_DEVICE_TYPE")
    if dt and isinstance(dt.value, int):
        device_type = dt.value
    version = None
    vv = consts.get("VALUE_VERSION")
    if vv and isinstance(vv.value, int):
        version = vv.value
    models: list[str] = []
    stem = Path(path).stem
    match = _MODEL_ID_RE.match(stem)
    if match and not _NUM_RE.match(match.group(1)):
        models.append(match.group(1))
    for name, const in consts.items():
        if "SN8" in name and isinstance(const.value, str) and const.value:
            models.append(const.value)
    return device_type, version, tuple(dict.fromkeys(models))


def _extract_framing(consts: dict[str, Constant]) -> dict[str, int]:
    keys = (
        "BYTE_PROTOCOL_HEAD",
        "BYTE_PROTOCOL_LENGTH",
        "BYTE_DEVICE_TYPE",
        "BYTE_CONTROL_REQUEST",
        "BYTE_QUERY_REQUEST",
        "BYTE_QUERYL_REQUEST",
        "BYTE_CONTROL_CMD",
    )
    return {
        k: consts[k].value  # type: ignore[misc]
        for k in keys
        if k in consts and isinstance(consts[k].value, int)
    }


def extract_from_source(source: str, path: str = "<string>") -> ProtocolDefinition:
    """Extract a :class:`ProtocolDefinition` from Lua ``source`` text."""
    consts = _extract_constants(source, path)
    enums = _extract_enums(consts, path)
    decode_fields = _extract_decode_fields(source, consts, path)
    encode_assigns, commands = _extract_encode(source, consts, path)
    device_type, version, models = _extract_identity(consts, path)

    definition = ProtocolDefinition(
        source=path,
        device_type=device_type,
        lua_version=version,
        model_ids=models,
        constants=consts,
        enums=enums,
        decode_fields=decode_fields,
        encode_assignments=encode_assigns,
        commands=commands,
        framing=_extract_framing(consts),
    )

    if not _function_body(source, "jsonToData"):
        definition.unparsed.append("no jsonToData(): encode side not extracted")
    if not any(_function_body(source, f) for f in _DECODE_FUNCS):
        definition.unparsed.append(
            "no updateGlobalPropertyValueByByte()/binToModel(): "
            "decode side not extracted",
        )
    return definition


def extract_from_file(path: str | Path) -> ProtocolDefinition:
    """Extract a :class:`ProtocolDefinition` from the Lua file at ``path``.

    The recorded ``source`` is made repo-relative when possible so reports and
    golden data are stable across checkouts.
    """
    path = Path(path)
    text = path.read_text(encoding="utf-8", errors="replace")
    try:
        display = str(path.resolve().relative_to(Path(__file__).resolve().parents[2]))
    except ValueError:
        display = str(path)
    return extract_from_source(text, display)
