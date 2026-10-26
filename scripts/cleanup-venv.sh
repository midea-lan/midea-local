#!/usr/bin/env bash
set -euo pipefail

echo "🗑️  Removing virtual environments..."

if [ -n "${VIRTUAL_ENV:-}" ]; then
    echo "⚠️  Active virtual environment detected at $VIRTUAL_ENV."
    if type deactivate > /dev/null 2>&1; then
        echo "Attempting to deactivate..."
        deactivate 2>/dev/null || true
    else
        echo "Note: This script must be sourced to deactivate the venv: source scripts/cleanup-venv.sh"
    fi
fi

for venv in .venv venv env ENV env.bak venv.bak; do
    if [ -d "$venv" ]; then
        rm -rf "$venv"
        echo "Removed $venv"
    fi
done

echo "✅ Virtual environment cleanup complete!"

# Suppress zsh RPROMPT warning
if [ -n "${ZSH_VERSION:-}" ]; then
    RPROMPT="" 2>/dev/null || true
fi
