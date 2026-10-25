#!/usr/bin/env bash
# Setups the repository.

# Stop on errors
set -e

# Use copy mode for UV to avoid hardlink warnings on different filesystems
export UV_LINK_MODE=copy

# Find the absolute path of the directory where this script resides
SETUP_SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" &>/dev/null && pwd)

# Always use this repo's .venv, even if the shell exports another project's
# environment (e.g. a shared devcontainer)
REPO_ROOT=$(dirname "$SETUP_SCRIPT_DIR")
export UV_PROJECT_ENVIRONMENT="$REPO_ROOT/.venv"
export VIRTUAL_ENV="$UV_PROJECT_ENVIRONMENT"

# Add default VS Code settings if not existing
if [ ! -f "$REPO_ROOT/.vscode/settings.json" ]; then
    cp "$REPO_ROOT/.vscode/settings.default.jsonc" "$REPO_ROOT/.vscode/settings.json"
fi

# Fetch the centralized uv version from the companion script
UV_VERSION=$("$SETUP_SCRIPT_DIR/get-pyproject-uv.version.sh")

if ! uv --version 2>/dev/null; then
    pipx install "uv==$UV_VERSION"
elif ! uv --version 2>/dev/null | grep -q "$UV_VERSION"; then
    pipx upgrade "uv==$UV_VERSION"
fi
if ! prek --version 2>/dev/null; then
    uv tool install prek
fi
uv sync --frozen --all-groups
prek install --overwrite
prek install --hook-type commit-msg --overwrite

# Initialize the Lua submodule and install its own prek hook.
git -C "$REPO_ROOT" submodule update --init --recursive --remote
(
    cd "$REPO_ROOT/lua"
    prek install --overwrite
)

npm install --no-fund --no-audit @commitlint/config-conventional
