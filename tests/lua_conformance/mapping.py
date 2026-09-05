"""Map Lua plugin files to ``midealocal`` device packages.

Both sides name themselves after the device-type byte in hex (``e1``, ``ac``;
types ``< 0xA0`` get an ``x`` prefix -> ``x13``, ``x40``).  That gives a strong
*structural* candidate mapping, but it is only accepted when corroborated by
evidence that does not come from the name:

* the Lua ``BYTE_DEVICE_TYPE`` constant equals the package's ``DeviceType`` byte;
* failing that, the ``T_xxxx_<TYPE>_...`` token in the Lua filename equals the
  package's ``DeviceType`` byte.

Anything without corroboration is reported as ``UNMATCHED`` rather than guessed.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path

from .lua_extract import extract_from_file
from .py_introspect import introspect_device

_REPO_ROOT = Path(__file__).resolve().parents[2]
LUA_ROOT = _REPO_ROOT / "lua"
DEVICES_ROOT = _REPO_ROOT / "midealocal" / "devices"


class MatchStatus(Enum):
    """Outcome of trying to pair one device-type between the two trees."""

    MATCHED = "MATCHED"
    UNMATCHED_NO_PYTHON = "UNMATCHED_NO_PYTHON"
    UNMATCHED_NO_LUA = "UNMATCHED_NO_LUA"
    CONFLICT = "CONFLICT"


@dataclass
class DeviceMapping:
    """One device-type row of the mapping report."""

    key: str
    status: MatchStatus
    lua_dir: str | None = None
    py_package: str | None = None
    lua_files: tuple[str, ...] = ()
    device_type: int | None = None
    evidence: list[str] = field(default_factory=list)


def _lua_dirs() -> dict[str, Path]:
    return {
        p.name: p
        for p in sorted(LUA_ROOT.iterdir())
        if p.is_dir() and any(p.glob("*.lua"))
    }


def _py_packages() -> set[str]:
    return {
        p.name
        for p in DEVICES_ROOT.iterdir()
        if p.is_dir() and (p / "__init__.py").exists() and p.name != "__pycache__"
    }


def build_mapping() -> list[DeviceMapping]:
    """Return the full LUA<->``midealocal`` mapping, one row per device-type."""
    lua_dirs = _lua_dirs()
    py_packages = _py_packages()
    rows: list[DeviceMapping] = []

    for key in sorted(set(lua_dirs) | py_packages):
        lua_dir = lua_dirs.get(key)
        has_py = key in py_packages
        lua_files = (
            tuple(sorted(p.name for p in lua_dir.glob("*.lua"))) if lua_dir else ()
        )

        if lua_dir and not has_py:
            rows.append(
                DeviceMapping(
                    key=key,
                    status=MatchStatus.UNMATCHED_NO_PYTHON,
                    lua_dir=f"lua/{key}",
                    lua_files=lua_files,
                    evidence=["no midealocal/devices package with this name"],
                ),
            )
            continue
        if has_py and not lua_dir:
            rows.append(
                DeviceMapping(
                    key=key,
                    status=MatchStatus.UNMATCHED_NO_LUA,
                    py_package=f"midealocal/devices/{key}",
                    evidence=["no lua/ directory with this name"],
                ),
            )
            continue

        assert lua_dir is not None  # both-sided rows only reach here
        py = introspect_device(key)
        evidence: list[str] = []
        corroborated = False
        first_lua = extract_from_file(lua_dir / lua_files[0]) if lua_files else None
        if first_lua and first_lua.device_type is not None and py.device_type:
            if first_lua.device_type == py.device_type:
                evidence.append(
                    f"BYTE_DEVICE_TYPE == DeviceType.{key.upper()} "
                    f"(0x{py.device_type:02X})",
                )
                corroborated = True
            else:
                evidence.append(
                    f"CONFLICT: lua BYTE_DEVICE_TYPE=0x{first_lua.device_type:02X} "
                    f"!= DeviceType.{key.upper()}=0x{py.device_type:02X}",
                )
        token = key.removeprefix("x")
        if (
            not corroborated
            and py.device_type is not None
            and f"{py.device_type:02X}".lower() == token.lower()
        ):
            evidence.append(
                f"filename type token '{token}' == "
                f"DeviceType byte 0x{py.device_type:02X}",
            )
            corroborated = True

        status = MatchStatus.MATCHED if corroborated else MatchStatus.CONFLICT
        rows.append(
            DeviceMapping(
                key=key,
                status=status,
                lua_dir=f"lua/{key}",
                py_package=f"midealocal/devices/{key}",
                lua_files=lua_files,
                device_type=py.device_type,
                evidence=evidence or ["name match only, no corroborating evidence"],
            ),
        )
    return rows


def matched_packages() -> list[str]:
    """Return the device-type keys that map cleanly in both directions."""
    return [r.key for r in build_mapping() if r.status is MatchStatus.MATCHED]
