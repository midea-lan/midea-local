#!/usr/bin/env bash
# No strict mode: this script may be sourced and must not alter the caller's shell options.

project_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
venvs=(.venv venv env ENV env.bak venv.bak)

echo "🗑️  Removing virtual environments..."

for venv in "${venvs[@]}"; do
    if [ "${VIRTUAL_ENV:-}" = "$project_root/$venv" ]; then
        echo "⚠️  Active virtual environment detected at $VIRTUAL_ENV."
        if type deactivate > /dev/null 2>&1; then
            echo "Attempting to deactivate..."
            deactivate 2>/dev/null || true
        fi
        if [ -n "${VIRTUAL_ENV:-}" ]; then
            echo "❌ $VIRTUAL_ENV is still active. Run 'deactivate' first, or source this script: source scripts/cleanup-venv.sh"
            # return when sourced, exit when executed
            return 1 2>/dev/null || exit 1
        fi
        break
    fi
done

for venv in "${venvs[@]}"; do
    [ -d "$project_root/$venv" ] || continue
    if [ ! -f "$project_root/$venv/pyvenv.cfg" ]; then
        echo "⚠️  Skipping $venv: not a virtual environment (no pyvenv.cfg)"
        continue
    fi
    if ! rm -rf "${project_root:?}/$venv"; then
        echo "❌ Failed to remove $venv"
        return 1 2>/dev/null || exit 1
    fi
    echo "Removed $venv"
done

echo "✅ Virtual environment cleanup complete!"
