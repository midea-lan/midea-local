# Contributing Guide (English Version)

> [中文版点这里 / Chinese Version](./CONTRIBUTING.zh.md)

Thank you for contributing to this project!
This guide explains how to set up your development environment with **[uv](https://docs.astral.sh/uv/)** and a local virtual environment, and how to contribute code following our workflow and style rules.

GitHub Path: `.github/CONTRIBUTING.md`

---

## Table of Contents

1. [Overview](#1-overview)
2. [System Requirements](#2-system-requirements)
3. [Install uv](#3-install-uv)
4. [Quick Start](#4-quick-start)
5. [Windows Users](#5-windows-users)
6. [China Mainland Network Mirrors](#6-china-mainland-network-mirrors)
7. [Common Commands](#7-common-commands)
8. [Commit & Pull Request Workflow](#8-commit--pull-request-workflow)
9. [Code Style, Pre-commit & Testing](#9-code-style-pre-commit--testing)
10. [Issues & Community Conduct](#10-issues--community-conduct)

---

## 1. Overview

This project uses **uv** to manage the Python toolchain and a local `.venv` virtual
environment. uv installs the right Python version for you (3.12–3.14 are supported), is
fast, and works the same on Linux, macOS, Windows, and WSL2 — no Docker required.

> ✅ Recommended: run `./scripts/setup.sh` (or `scripts\setup.ps1` on Windows) once after
> cloning; it creates the `.venv`, installs all dependencies, and wires up the pre-commit
> hooks.

---

## 2. System Requirements

- **OS:** Linux / macOS / Windows / Windows + WSL2
- **[uv](https://docs.astral.sh/uv/):** manages Python and dependencies (see [section 3](#3-install-uv))
- **Python:** ≥ 3.12 — you do **not** need to install it yourself; uv downloads it on demand
- **Git**
- **Node.js (optional):** only needed for the `commitlint` commit-message hook
- **Editor:** any. For VS Code, the workspace is preconfigured (`.vscode/`) to use `.venv`;
  the recommended extensions are `charliermarsh.ruff` and `ms-python.python`.

---

## 3. Install uv

**macOS / Linux / WSL2:**

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**Windows (PowerShell):**

```powershell
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
```

**Alternatives:** `brew install uv` (macOS), `pipx install uv`, or
`winget install --id=astral-sh.uv` (Windows). See the
[official install docs](https://docs.astral.sh/uv/getting-started/installation/) for more.

Verify with `uv --version`.

---

## 4. Quick Start

```bash
git clone https://github.com/midea-lan/midea-local.git
cd midea-local
./scripts/setup.sh          # Windows: scripts\setup.ps1
```

The setup script:

1. creates a `.venv` with Python 3.12 (`uv venv --python 3.12`),
2. installs runtime + dev + type-stub dependencies (`uv pip install -r requirements-all.txt`),
3. installs the pre-commit hooks (commit and commit-msg stages).

**Manual setup** (equivalent to the script):

```bash
uv venv --python 3.12
uv pip install -r requirements-all.txt
uv run pre-commit install
uv run pre-commit install --hook-type commit-msg
```

Then either activate the environment (`source .venv/bin/activate`) or prefix commands with
`uv run` (e.g. `uv run python -m pytest ./tests/`).

---

## 5. Windows Users

Native Windows is fully supported — install uv (see [section 3](#3-install-uv)) and run
`scripts\setup.ps1` from PowerShell. **WSL2 is optional**, not required.

If you prefer WSL2:

1. Enable it: `wsl --install -d Ubuntu` then `wsl --set-default-version 2`.
2. Install uv **inside** WSL using the macOS/Linux command.
3. Clone the repo inside the WSL Linux filesystem (e.g. `/home/<user>/midea-local`), not
   under `C:\`, to avoid performance and permission issues.

---

## 6. China Mainland Network Mirrors

If PyPI or the Python download is slow, point uv at a mirror **before** running the setup
script:

```bash
# PyPI package mirror (Tsinghua shown as an example)
export UV_DEFAULT_INDEX="https://pypi.tuna.tsinghua.edu.cn/simple"
# Python interpreter download mirror
export UV_PYTHON_INSTALL_MIRROR="https://mirror.nju.edu.cn/github-release/astral-sh/python-build-standalone/"
```

On Windows PowerShell use `$env:UV_DEFAULT_INDEX = "..."` instead of `export`. You can also
persist these in your shell profile.

---

## 7. Common Commands

| Task                       | Command                                                                       |
| -------------------------- | ----------------------------------------------------------------------------- |
| Run all tests              | `uv run python -m pytest ./tests/`                                            |
| Run one test file          | `uv run python -m pytest tests/devices/ac/message_ac_test.py`                 |
| Coverage report            | `uv run python -m pytest --cov=midealocal --cov-report term-missing ./tests/` |
| Lint / format / type-check | `uv run pre-commit run --all-files`                                           |
| Ruff only                  | `uv run ruff check .` / `uv run ruff format .`                                |
| Build the package          | `uv run python -m build`                                                      |
| Add a dependency           | edit `requirements*.txt`, then `uv pip install -r requirements-all.txt`       |

---

## 8. Commit & Pull Request Workflow

1. Create a branch:

   ```bash
   git checkout -b feat/add-feature
   ```

2. Follow [Conventional Commits](https://www.conventionalcommits.org/) message format:
   - `feat:` → New feature
   - `fix:` → Bug fix
   - `chore:` → Tooling, configs, or non-functional updates
   - `docs:` → Documentation only
   - `refactor:` → Code restructure
   - `test:` → Test-only changes

3. Example:

   ```bash
   feat: add user authentication
   chore: update pre-commit hooks
   fix: correct API endpoint error
   ```

4. Push and open a Pull Request.
   GitHub Actions will validate your commit messages automatically.
   Do not commit directly to `main` (the `no-commit-to-branch` hook blocks it).

---

## 9. Code Style, Pre-commit & Testing

- **Pre-commit** is installed by the setup script and runs on every commit. It includes:
  - `ruff` → Linting and formatting
  - `mypy` → Type checking (strict)
  - `pylint` → Additional static analysis
- Run the full suite any time with `uv run pre-commit run --all-files`, and fix all reported
  issues before committing.
- Tests use `pytest`. CI runs the full pre-commit suite and the tests across the
  Python 3.12/3.13/3.14 × Linux/macOS/Windows matrix and blocks merge on failure.

---

## 10. Issues & Community Conduct

When opening Issues:

- Include steps to reproduce, logs, and your environment info.
- Be respectful, concise, and follow community guidelines.

---

**File Path:**

- English: `.github/CONTRIBUTING.md`
- Chinese: `.github/CONTRIBUTING.zh.md`
