#!/usr/bin/env bash
# Build and install lua-format (https://github.com/Koihik/LuaFormatter) into
# .venv/bin so the `midea-local download` CLI can pretty-print downloaded lua
# scripts to match the style already used under lua/.
#
# No official binary release exists past v1.1.0 and there is no pip/apt/npm
# package for the current version, so this builds it from source.
set -euo pipefail

LUA_FORMAT_VERSION="1.3.6"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENV_BIN="$REPO_ROOT/.venv/bin"
TARGET="$VENV_BIN/lua-format"

if [ -x "$TARGET" ]; then
  echo "lua-format is already installed: $TARGET"
  exit 0
fi

if command -v lua-format >/dev/null 2>&1; then
  echo "lua-format is already installed: $(command -v lua-format)"
  exit 0
fi

for tool in git cmake make; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Error: '$tool' is required to build lua-format but was not found." >&2
    exit 1
  fi
done

if [ ! -d "$VENV_BIN" ]; then
  echo "Error: $VENV_BIN not found. Run scripts/setup.sh first." >&2
  exit 1
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "Cloning LuaFormatter $LUA_FORMAT_VERSION..."
git clone --quiet --recurse-submodules --depth 1 --branch "$LUA_FORMAT_VERSION" \
  https://github.com/Koihik/LuaFormatter.git "$WORK_DIR/LuaFormatter"

echo "Building lua-format (this can take a few minutes)..."
cmake -S "$WORK_DIR/LuaFormatter" -B "$WORK_DIR/LuaFormatter" -DCMAKE_BUILD_TYPE=Release
make -C "$WORK_DIR/LuaFormatter" lua-format \
  -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)"

install -m 755 "$WORK_DIR/LuaFormatter/lua-format" "$TARGET"

echo "Installed lua-format to $TARGET"
