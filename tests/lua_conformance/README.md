# Lua protocol-conformance framework

This package answers one question, with automated tests and a structured report:

> For the protocol behaviour represented by the Midea Lua plugin files we have
> collected under `lua/`, how closely does the current `midealocal`
> implementation match?

It is a **regression and protocol-conformance suite**, not a rewrite. The Lua
files are treated as the primary protocol evidence; `midealocal` is the thing
under test. A mismatch is reported, never "fixed" by changing production code.

---

## 1. Why the Lua files are useful

Each `lua/<type>/T_*.lua` file is Midea's own reference implementation of the
LAN protocol for a device model: it defines the protocol constants, the enum
tables, the exact byte offsets and bit masks used to build control frames and to
parse status frames, and the encode/decode formulas (temperature scaling, timer
packing, ...). That is exactly the information a conformance test needs, and it
comes from the vendor rather than from us.

The files are proprietary and may depend on an external runtime, so this
framework **never executes them**. Everything is recovered by static,
line-oriented parsing (`lua_extract.py`).

## 2. What the framework does

```
lua/<type>/*.lua ──▶ lua_extract ──▶ ProtocolDefinition ┐
                                                         ├─▶ compare ─▶ [Finding...]
midealocal/devices/<type> ─▶ py_introspect ─▶ PythonProtocol ┘
```

| module             | role                                                                       |
| ------------------ | -------------------------------------------------------------------------- |
| `ir.py`            | the intermediate representation both sides are lowered into                |
| `lua_extract.py`   | static extraction of protocol facts from a Lua file                        |
| `py_introspect.py` | AST + runtime introspection of a `midealocal` device package               |
| `mapping.py`       | pairs `lua/<type>` with `midealocal/devices/<type>`, with evidence         |
| `compare.py`       | the comparison engine → `Finding(verdict, area, name, detail, ...)`        |
| `report.py`        | renders the mapping and a Markdown conformance report                      |
| `run.py`           | drivers: `compare_pair`, `generate_all`, `python -m tests.lua_conformance` |

### The IR coordinate system

All byte indices are expressed with **offset 0 == the body-type byte** — the
first byte after the 10-byte transport header and before the trailing checksum.
This is what `midealocal`'s `MessageRequest.body` / `MessageResponse.body`
expose, and it is what the classic Lua `bodyBytes` / `messageBytes` arrays use
(`extractBodyBytes` strips the header, keeping `[0]` = body type). So a Lua
`messageBytes[6]` read and a Python `body[6]` read are directly comparable.

## 3. How Lua information is extracted

`lua_extract.py` targets the "classic" structure shared by most of the collected
files:

- `local KEY_* / VALUE_* / BYTE_* = ...` → `Constant`s (scalars only; tables and
  computed RHS are skipped, not guessed).
- `BYTE_<CAT>_<MEMBER>` + `VALUE_<CAT>_<MEMBER>` groups → `Enum` (`<CAT>` with
  int values) and `<CAT>_VALUES` (string values); `paired_enum("<CAT>")` merges
  them into `{byte_value: logical_name}`.
- `updateGlobalPropertyValueByByte` / `binToModel` body → `DecodeField`s:
  `var = messageBytes[i]`, `bit.band(messageBytes[i], MASK)`,
  `bit.rshift(bit.band(...), N)`, `(messageBytes[i] - 50) / 2`, etc.
- `jsonToData` body → `EncodeAssignment`s (`bodyBytes[i] = <expr>`) grouped into
  `Command`s keyed by the `bodyBytes[0]` value and the `control[KEY_*]` trigger.
- `BYTE_DEVICE_TYPE`, `VALUE_VERSION`, filename token, `deviceSN8` strings →
  device identity.

Anything the extractor recognises as protocol-relevant but cannot lower is added
to `ProtocolDefinition.unparsed` and surfaced in the report as `UNKNOWN` — never
dropped silently. Files with a different structure still yield their constants
and enums; their field/command extraction just degrades to `UNKNOWN`.

`py_introspect.py` recovers the Python side without assuming its internals are
right: response fields come from an **AST** walk of
`devices/<type>/message.py` (`self.x = ... body[i] ... & MASK >> N`), request
bytes come from **instantiating** each `Message*` class and reading `.body`, and
enum tables come from class vars (`_modes`, `_status`, ...). Importing a device
package is side-effect free (no socket, no thread).

## 4. How Lua implementations are mapped to Python implementations

`mapping.py` pairs directories by name **and requires corroboration** that does
not come from the name: the Lua `BYTE_DEVICE_TYPE` (or the `T_xxxx_<TYPE>_...`
filename token) must equal the package's `DeviceType` byte. Rows without
corroboration are `CONFLICT`; device types present on only one side are
`UNMATCHED_NO_PYTHON` / `UNMATCHED_NO_LUA`. The full table is regenerated into
[`GENERATED_MAPPING.md`](GENERATED_MAPPING.md).

## 5. How to add support for a new Lua file

Nothing to do for a new file inside an already-mapped `lua/<type>/` directory —
`generate_all()` picks up every `*.lua` automatically, and if the type is in
`VERIFIED_DEVICES` (`conformance_report_test.py`) any structural regression it
reveals fails CI.

For a **new device type**:

1. Drop the files in `lua/<newtype>/`.
2. If `midealocal/devices/<newtype>` exists, `build_mapping()` will pair them and
   the run will include them. If not, the row shows `UNMATCHED_NO_PYTHON`.
3. Regenerate the report (below) and review the new rows.

If the files use a structure the extractor does not recognise, extend
`lua_extract.py` (add a regex to `_DECODE_FUNCS` / the decode-line patterns, or a
new `_extract_*` pass). Keep it defensive: unknown constructs go to `unparsed`.

## 6. How to add a new comparison

Add a `_compare_<thing>(lua, py, out)` function in `compare.py` that appends
`Finding`s, and call it from `compare()`. Use the existing helpers
(`normalize_name`, `paired_enum`, `DecodeField.signature`). If a real file needs
a Lua-variable-name → `midealocal`-attribute alias, add it to `_NAME_ALIASES`
(snake_case keys, kept deliberately small).

## 7. How to interpret failures

| verdict       | meaning                                                                                   |
| ------------- | ----------------------------------------------------------------------------------------- |
| **MATCH**     | Lua-derived fact and `midealocal` agree.                                                  |
| **MISSING**   | Lua specifies something (field, command body-type, enum value) `midealocal` lacks.        |
| **DIFFERENT** | both implement it, values/offsets disagree — the finding includes a worked example.       |
| **UNKNOWN**   | not auto-verifiable (structure the extractor can't read, `T_0008` header, implicit enum). |

**A `MISSING`/`DIFFERENT` verdict is a candidate discrepancy, not a proven
bug.** For each one decide whether it is: a genuine bug; an unsupported feature;
a device/model variation; a newer/older protocol version; an intentional
abstraction (e.g. E1 `neutral_gear` → `none`); insufficient Lua information; or
a wrong mapping. Encode protocol _facts_ in tests, don't force `midealocal` to
reproduce every Lua implementation detail.

Real examples currently surfaced (see [`DISCREPANCIES.md`](DISCREPANCIES.md)):

- `b0` mode `0x06`: Lua `hot_steam` vs `midealocal` `host_steam` — looks like a
  genuine typo in `midealocal`.
- `ac` `prevent_cold`: Lua reads `byte[10] & 0x08 >> 3`, `midealocal` reads
  `byte[10] & 0x20 >> 5` — worth a protocol-version check.

## 8. How to run the complete verification suite

```bash
# all conformance tests (unit tests for the framework + real comparisons)
uv run python -m pytest tests/lua_conformance/

# regenerate the human-readable artifacts (mapping + full report)
python -m tests.lua_conformance

# quick subset while iterating
python -m tests.lua_conformance --limit-per-dir 2
```

**Regression protection.** There is no frozen whole-corpus baseline (it went
stale on every unrelated `main` change). Instead:

- `conformance_<device>_test.py` holds hand-written golden encode/decode vectors
  for each _verified_ device (E1 today) — these are the real per-device gate.
- `conformance_report_test.py::test_verified_device_has_no_structural_regression`
  asserts that, for every device in `VERIFIED_DEVICES`, no Lua file produces a
  `MISSING` or wrong-offset `DIFFERENT` finding. Add a device to that tuple once
  it has golden vectors and its offsets/commands line up.
- The remaining `MISSING`/`DIFFERENT` findings for unverified devices are
  informational — read them in `GENERATED_REPORT.md` / `DISCREPANCIES.md`.

## 9. What cannot currently be automatically verified

- **Newer Lua architecture** — the large `T_0000_AC_00000Q1*` / `_2024*` files
  and several device types (`b3`, `e3` v-N, `e6`, ...) do not use
  `updateGlobalPropertyValueByByte` / `jsonToData`; only their constants/enums
  are extracted. Everything else is `UNKNOWN`.
- **`T_0008_*` container files** — 16-byte header; their `messageBytes[i]`
  indices are in a different coordinate system, so byte-offset comparison is
  skipped (reported as one `UNKNOWN`).
- **Encode formulas** — request _bodies_ are captured, but which settable
  attribute drives which byte is not inferred; golden encode vectors are written
  by hand per device (see `conformance_e1_test.py`).
- **Multi-branch decode** — when Lua reads a field differently per `dataType`,
  only one branch is captured.
- **Implicit enums** — devices like `ac` map mode/fan values in device code
  rather than a `{int: str}` table; those comparisons are `UNKNOWN`.
- **`UNMATCHED` device types** — 16 `lua/` dirs have no Python package; 4 Python
  packages have no `lua/` dir.

## Files in this directory

- `GENERATED_MAPPING.md`, `GENERATED_REPORT.md` — regenerated by
  `python -m tests.lua_conformance` (excluded from prek: generated artifacts).
- `conformance_<device>_test.py` — per-device golden vectors (the regression gate).
- `DISCREPANCIES.md` — curated summary of what the first full run found.
- `fixtures/` — synthetic Lua for the extractor unit tests (no proprietary data).
