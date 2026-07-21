#!/usr/bin/env bash
# Bootstrap the midea-local development environment with uv.
#
# Prerequisite: install uv first (https://docs.astral.sh/uv/getting-started/installation/):
#   curl -LsSf https://astral.sh/uv/install.sh | sh
#
# China Mainland users can point uv at a mirror before running this script, e.g.:
#   export UV_DEFAULT_INDEX="https://pypi.tuna.tsinghua.edu.cn/simple"
#   export UV_PYTHON_INSTALL_MIRROR="https://mirror.nju.edu.cn/github-release/astral-sh/python-build-standalone/"
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v uv >/dev/null 2>&1; then
  echo "Error: 'uv' is not installed." >&2
  echo "Install it: curl -LsSf https://astral.sh/uv/install.sh | sh" >&2
  exit 1
fi

# Create the virtual environment (uv downloads Python 3.12 if needed).
echo "Creating virtual environment (.venv) with Python 3.12..."
uv venv --python 3.12

# Activate it so the tools below resolve to this project's .venv. (This repo has no
# pyproject.toml, so `uv run` cannot auto-discover the environment.)
# shellcheck disable=SC1091
source .venv/bin/activate

# Install runtime + dev + type-stub dependencies, plus pre-commit.
echo "Installing dependencies from requirements-all.txt..."
uv pip install -r requirements-all.txt pre-commit

# Install the git pre-commit hooks (commit + commit-msg stages).
echo "Installing pre-commit hooks..."
pre-commit install
pre-commit install --hook-type commit-msg

# commitlint (a commit-msg hook) needs its shared config; install it if npm exists.
if command -v npm >/dev/null 2>&1; then
  echo "Installing @commitlint/config-conventional..."
  npm install --no-fund --no-audit @commitlint/config-conventional
else
  echo "Warning: 'npm' not found - skipping @commitlint/config-conventional." >&2
  echo "         Install Node.js if the commitlint commit-msg hook fails." >&2
fi

echo ""
echo "Done. The environment is active in this shell. In new shells, activate with:"
echo "  source .venv/bin/activate      # bash/zsh"
echo "Then run tools directly, e.g.:"
echo "  python3 -m pytest ./tests/"
echo "  pre-commit run --all-files"
