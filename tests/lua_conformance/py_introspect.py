"""Introspection of ``midealocal`` device packages into the shared IR.

Two complementary techniques are used, both implementation-agnostic:

* **AST analysis** of ``midealocal/devices/<type>/message.py`` recovers the
  response-body field map -- every ``self.<name> = ... body[<i>] ...`` becomes a
  :class:`~tests.lua_conformance.ir.DecodeField` with the same
  ``(byte, mask, shift)`` signature the Lua extractor produces.
* **Runtime instantiation** of the ``Message*`` request classes: each is built
  with a throwaway protocol version and its ``.body`` bytearray captured, giving
  the concrete request bytes ``midealocal`` emits (body-type byte at offset 0,
  matching the IR coordinate system).

Class-level lookup tables on the device class (``_modes``, ``_status``,
``_speeds`` ...) are lowered into :class:`~tests.lua_conformance.ir.Enum`.

Importing a device package is side-effect free (no socket, no thread start), so
this is safe to do at test-collection time.
"""

from __future__ import annotations

import ast
import importlib
import inspect
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from .ir import DecodeField, Enum


@dataclass
class PyCommand:
    """A concrete request emitted by a ``midealocal`` ``Message*`` class."""

    name: str
    body_type: int | None
    body: bytes
    message_type: int | None = None


@dataclass
class PythonProtocol:
    """Everything introspected from one ``midealocal`` device package."""

    package: str
    device_type: int | None = None
    attributes: frozenset[str] = frozenset()
    enums: dict[str, Enum] = field(default_factory=dict)
    decode_fields: list[DecodeField] = field(default_factory=list)
    commands: list[PyCommand] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)

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
            lowered = candidate.lower().lstrip("_")
            for name, enum in self.enums.items():
                if name.lower().lstrip("_") == lowered:
                    return enum
        return None


def _const_int(node: ast.expr) -> int | None:
    if isinstance(node, ast.Constant) and isinstance(node.value, int):
        return node.value
    if isinstance(node, ast.UnaryOp) and isinstance(node.op, ast.USub):
        inner = _const_int(node.operand)
        return -inner if inner is not None else None
    return None


def _contains_body_subscript(node: ast.AST) -> int | None:
    """Return the first ``body[i]`` / ``data[i]`` index found under ``node``."""
    for child in ast.walk(node):
        if (
            isinstance(child, ast.Subscript)
            and isinstance(child.value, ast.Name)
            and child.value.id in {"body", "data"}
        ):
            idx = _const_int(child.slice)
            if idx is not None:
                return idx
    return None


class _BodyExprVisitor(ast.NodeVisitor):
    """Collect ``body[i]`` subscripts and the mask/shift applied *to them*.

    A mask/shift is only recorded when the ``BinOp`` that carries it actually
    contains a ``body[...]`` subscript in its own subtree -- so
    ``parse_temperature(body[13], decimal & 0x0F)`` does not wrongly attribute
    the ``& 0x0F`` (which applies to ``decimal``) to ``body[13]``.
    """

    def __init__(self) -> None:
        self.indices: list[int] = []
        self.mask: int | None = None
        self.shift: int | None = None
        self.boolean = False

    def visit_Subscript(self, node: ast.Subscript) -> None:
        if isinstance(node.value, ast.Name) and node.value.id in {"body", "data"}:
            idx = _const_int(node.slice)
            if idx is not None:
                self.indices.append(idx)
        self.generic_visit(node)

    def visit_BinOp(self, node: ast.BinOp) -> None:
        if isinstance(node.op, (ast.BitAnd, ast.RShift)) and (
            _contains_body_subscript(node) is not None
        ):
            const_side = _const_int(node.right)
            if isinstance(node.op, ast.BitAnd):
                other = _const_int(node.left)
                mask = const_side if const_side is not None else other
                if mask is not None and self.mask is None:
                    self.mask = mask
            elif const_side is not None and self.shift is None:
                self.shift = const_side
        self.generic_visit(node)

    def visit_Compare(self, node: ast.Compare) -> None:
        # `(body[i] & x) > 0`  /  `... == mask` -> boolean field
        if len(node.ops) == 1 and isinstance(
            node.ops[0],
            (ast.Gt, ast.GtE, ast.Eq, ast.NotEq),
        ):
            self.boolean = True
        self.generic_visit(node)


def _extract_decode_fields_from_ast(message_py: Path) -> list[DecodeField]:
    tree = ast.parse(message_py.read_text(encoding="utf-8"), str(message_py))
    fields: list[DecodeField] = []
    seen: set[tuple[str, int, int, int]] = set()
    for node in ast.walk(tree):
        if not isinstance(node, ast.Assign) or len(node.targets) != 1:
            continue
        target = node.targets[0]
        if not (
            isinstance(target, ast.Attribute)
            and isinstance(target.value, ast.Name)
            and target.value.id == "self"
        ):
            continue
        visitor = _BodyExprVisitor()
        visitor.visit(node.value)
        if not visitor.indices:
            continue
        try:
            transform = ast.unparse(node.value)
        except Exception:  # noqa: BLE001 - best-effort text for the report
            transform = None
        byte = visitor.indices[0]
        multi = len(set(visitor.indices)) > 1
        field_ = DecodeField(
            name=target.attr,
            byte=byte,
            mask=visitor.mask if visitor.mask is not None else 0xFF,
            shift=visitor.shift or 0,
            transform=transform if (multi or visitor.shift or visitor.mask) else None,
            boolean=visitor.boolean and not multi,
        )
        key = (field_.name, field_.byte, field_.mask, field_.shift)
        if key in seen:
            continue
        seen.add(key)
        fields.append(field_)
    return fields


_ENUM_ATTR_HINTS = (
    "mode",
    "status",
    "speed",
    "fan",
    "swing",
    "progress",
    "preset",
    "gear",
    "level",
    "type",
)


def _lower_lookup(name: str, value: Any) -> Enum | None:  # noqa: ANN401
    clean = name.strip("_")
    if isinstance(value, dict) and value and all(isinstance(k, int) for k in value):
        members: dict[str, int | str] = {
            str(v): k for k, v in value.items() if isinstance(v, str)
        }
        if members:
            return Enum(clean, members)
    if (
        isinstance(value, (list, tuple))
        and value
        and all(isinstance(v, str) for v in value)
    ):
        return Enum(clean, {v: i for i, v in enumerate(value)})
    return None


def _extract_enums_from_class(device_cls: type) -> dict[str, Enum]:
    enums: dict[str, Enum] = {}
    for klass in reversed(inspect.getmro(device_cls)):
        for name, value in vars(klass).items():
            if name.startswith("__"):
                continue
            if not any(hint in name.lower() for hint in _ENUM_ATTR_HINTS):
                continue
            lowered = _lower_lookup(name, value)
            if lowered is not None:
                enums[lowered.name] = lowered
    return enums


def _extract_commands(message_mod: Any) -> tuple[list[PyCommand], list[str]]:  # noqa: ANN401
    commands: list[PyCommand] = []
    notes: list[str] = []
    module_name = getattr(message_mod, "__name__", "")
    for name, obj in vars(message_mod).items():
        if not (inspect.isclass(obj) and name.startswith("Message")):
            continue
        if getattr(obj, "__module__", "") != module_name:
            continue  # imported base class, not a device request
        if name.endswith(("Response", "Base")):
            continue
        instance: Any = None
        for args, kwargs in ((("1",), {}), ((1,), {}), ((), {"protocol_version": 1})):
            try:
                instance = obj(*args, **kwargs)
            except Exception:  # noqa: BLE001 - probing unknown constructors
                instance = None
            else:
                break
        if instance is None:
            notes.append(f"could not instantiate {name} to capture request bytes")
            continue
        try:
            body = bytes(instance.body)
        except Exception:  # noqa: BLE001
            notes.append(f"{name}.body raised while capturing request bytes")
            continue
        commands.append(
            PyCommand(
                name=name,
                body_type=body[0] if body else None,
                body=body,
                message_type=getattr(instance, "message_type", None),
            ),
        )
    return commands, notes


def introspect_device(package: str) -> PythonProtocol:
    """Introspect ``midealocal.devices.<package>`` into a :class:`PythonProtocol`.

    ``package`` is the device folder name (``e1``, ``ac``, ``x13`` ...).
    """
    result = PythonProtocol(package=package)

    try:
        pkg_mod = importlib.import_module(f"midealocal.devices.{package}")
    except Exception as exc:  # noqa: BLE001
        result.notes.append(f"import failed: {exc!r}")
        return result

    try:
        from midealocal.const import DeviceType  # noqa: PLC0415

        result.device_type = int(DeviceType[package.upper()])
    except Exception:  # noqa: BLE001 - unknown / non-enum folder
        result.notes.append(f"no DeviceType member for {package!r}")

    device_cls = getattr(pkg_mod, "MideaAppliance", None)
    if device_cls is not None:
        result.enums = _extract_enums_from_class(device_cls)

    attrs_enum = getattr(pkg_mod, "DeviceAttributes", None)
    if attrs_enum is not None:
        result.attributes = frozenset(m.value for m in attrs_enum)

    try:
        message_mod = importlib.import_module(
            f"midealocal.devices.{package}.message",
        )
    except Exception as exc:  # noqa: BLE001
        result.notes.append(f"message import failed: {exc!r}")
        return result

    message_py = Path(inspect.getfile(message_mod))
    result.decode_fields = _extract_decode_fields_from_ast(message_py)
    result.commands, cmd_notes = _extract_commands(message_mod)
    result.notes.extend(cmd_notes)
    return result
