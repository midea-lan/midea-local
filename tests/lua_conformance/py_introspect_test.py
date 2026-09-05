"""Unit tests for ``midealocal`` device introspection."""

from __future__ import annotations

from tests.lua_conformance.py_introspect import introspect_device


def test_introspect_e1_decode_fields() -> None:
    """AST analysis recovers the E1 response-body field map with masks."""
    py = introspect_device("e1")
    assert py.device_type == 0xE1

    by_name = {f.name: f for f in py.decode_fields}
    assert by_name["status"].signature() == (1, 0xFF, 0)
    assert by_name["mode"].signature() == (2, 0xFF, 0)
    assert by_name["child_lock"].signature() == (5, 0x10, 0)
    assert by_name["temperature"].signature() == (11, 0xFF, 0)
    assert by_name["door"].boolean is True


def test_introspect_e1_enums_from_class_vars() -> None:
    """Class-level lookup tables (``_modes`` / ``_status``) lower into enums."""
    py = introspect_device("e1")
    modes = py.enum("modes")
    assert modes is not None
    assert modes.members["eco_wash"] == 0x04
    status = py.enum("status")
    assert status is not None
    assert status.members["running"] == 0x03


def test_introspect_e1_request_bytes() -> None:
    """Request classes are instantiated and their body bytes captured."""
    py = introspect_device("e1")
    by_name = {c.name: c for c in py.commands}
    assert by_name["MessageQuery"].body_type == 0x00
    assert by_name["MessageLock"].body_type == 0x83
    # MessageLock default body: [0x83, 0x04, 0x00 * 36]  (0x04 == "unlocked")
    assert by_name["MessageLock"].body[1] == 0x04


def test_introspect_unknown_package_is_soft_failure() -> None:
    """An unknown device folder yields notes, not an exception."""
    py = introspect_device("zz")
    assert py.device_type is None
    assert py.notes
