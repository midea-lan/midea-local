#!/usr/bin/env bash
# No strict mode: this script may be sourced and must not alter the caller's shell options.

project_root="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
venvs=(.venv venv env ENV env.bak venv.bak)

echo "🗑️  Removing virtual environments..."

if [ -n "${VIRTUAL_ENV:-}" ]; then
    echo "⚠️  Active virtual environment detected at $VIRTUAL_ENV."
    if type deactivate > /dev/null 2>&1; then
        echo "Attempting to deactivate..."
        deactivate 2>/dev/null || true
    fi
fi

if [ -n "${VIRTUAL_ENV:-}" ]; then
    for venv in "${venvs[@]}"; do
        if [ "$VIRTUAL_ENV" = "$project_root/$venv" ]; then
            echo "❌ $VIRTUAL_ENV is still active. Run 'deactivate' first, or source this script: source scripts/cleanup-venv.sh"
            # return when sourced, exit when executed
            return 1 2>/dev/null || exit 1
        fi
    done
fi

for venv in "${venvs[@]}"; do
    if [ -d "$project_root/$venv" ]; then
        rm -rf "${project_root:?}/$venv"
        echo "Removed $venv"
    fi
done

echo "✅ Virtual environment cleanup complete!"

# Suppress zsh RPROMPT warning
if [ -n "${ZSH_VERSION:-}" ]; then
    RPROMPT="" 2>/dev/null || true
fi
