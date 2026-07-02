# AGENTS.md

Guidance for AI coding agents (GitHub Copilot, Claude Code, Gemini CLI, Codex, etc.)
working in the `midea-local` repository. This is the canonical instructions file;
`CLAUDE.md` and `.github/copilot-instructions.md` point here.

`midea-local` is a Python library to control Midea M-Smart appliances over the local
network. It handles device discovery, the encrypted Midea LAN protocol, and per-device
message encoding/decoding. Python ≥ 3.12 (CI tests 3.12–3.14).

## Build, test, lint

Install everything (runtime + dev + types) with `pip install -r requirements-all.txt`.

- Run all tests: `python -m pytest ./tests/`
- Run one test file: `python -m pytest tests/devices/ac/message_ac_test.py`
- Run one test: `python -m pytest tests/devices/ac/message_ac_test.py::TestACMessage::test_message_query -v`
- Coverage (as CI does): `python -m pytest --cov=midealocal --cov-report xml ./tests/`
- Lint/format/type-check all at once via `pre-commit run --all-files`. Individually:
  `ruff check .`, `ruff format .`, `mypy midealocal`, `pylint --rcfile=pylintrc midealocal`.

`ruff` uses `lint.select = ["ALL"]` with curated ignores in `ruff.toml`; `mypy` runs in
strict mode (`mypy.ini`). Fix all reported issues before committing — CI runs the full
pre-commit suite across the OS/Python matrix and blocks merge on failure.

## Architecture

The protocol is split into three layers; understanding a feature usually means reading
across all three:

- **Transport / framing** (`device.py`, `packet_builder.py`, `security.py`, `crc8.py`):
  `MideaDevice` is a `threading.Thread` that owns the socket, handshake, auth (token/key),
  and the encrypt → frame → CRC pipeline. `LocalSecurity` implements V1/V2/V3 encryption.
- **Generic messages** (`message.py`): base classes `MessageRequest`, `MessageResponse`,
  `MessageBody`, `NewProtocolMessageBody`, plus `MessageType` and `ListTypes`. Every
  device message subclasses these.
- **Per-device packages** (`devices/<type>/`): one folder per appliance type, named by the
  device-type byte in hex (e.g. `ac`, `a1`, `e2`; types `< 0xA0` are prefixed with `x`,
  e.g. `x13`, `x40`). Each package has `__init__.py` (the device class) and `message.py`
  (that device's request/response messages).

Entry points: `discover.py` finds devices on the LAN; `devices/__init__.py`
`device_selector()` dynamically `import_module`s the right `devices/<type>` package and
instantiates its `MideaAppliance`. `cloud.py` retrieves token/key from Midea cloud
accounts. `cli.py` (`python -m midealocal.cli` / `midealocal`) and `library_test.py` are
user-facing harnesses.

## Conventions specific to this codebase

- **Adding/extending a device type**: create `devices/<hextype>/` matching the
  `device_selector` naming rule above. The device class extends `MideaDevice` and must be
  re-exported as `MideaAppliance` (see the `class MideaAppliance(MideaA1Device)` alias at
  the bottom of each `__init__.py`). Implement `build_query`, `process_message`,
  `make_message_set`, and `set_attribute`.
- **Attributes** are declared as a `DeviceAttributes(StrEnum)` per device and exposed
  through the `device.attributes` dict; state is never accessed by raw key elsewhere.
- **No magic numbers**: protocol offsets, lengths, and flag values are named module-level
  constants (see the block at the top of each `message.py` and `const.py`). Follow this
  when adding parsing logic; ruff's `PLR2004` enforces it outside `tests/`.
- **Device type registry**: register new appliance bytes in `const.py` `DeviceType` and,
  where relevant, `ListTypes` in `message.py`.
- **Tests** mirror the source tree under `tests/`, suffixed `_test.py`
  (e.g. `tests/devices/ac/message_ac_test.py`). Sample binary payloads live in
  `tests/responses/`. `tests/*` has relaxed ruff/mypy rules (asserts, private access, etc.).
- **Commits** must follow Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`,
  `refactor:`, `test:`); commitlint/commitizen enforce this and CI validates PR messages.
  Do not commit directly to `main` (pre-commit `no-commit-to-branch`).
- Recommended dev environment is **VS Code + Dev Container** (`.devcontainer/`); see
  `.github/CONTRIBUTING.md`.
