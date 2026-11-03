#!/usr/bin/env bash

# Find the absolute path of the directory where this script resides
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" &>/dev/null && pwd)

# Go up one level to reach the repository root directory
REPO_ROOT=$(dirname "$SCRIPT_DIR")

# Isolate the [tool.uv-version] block and extract the clean version string
sed -n '/\[tool.uv-version\]/,/version =/p' "$REPO_ROOT/pyproject.toml" | grep 'version =' | sed -E 's/.*version = "([^"]+)".*/\1/' | tr -d '\r' | xargs
