# Bootstrap the midea-local development environment with uv (Windows PowerShell).
#
# Prerequisite: install uv first (https://docs.astral.sh/uv/getting-started/installation/):
#   powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
#
# China Mainland users can point uv at a mirror before running this script, e.g.:
#   $env:UV_DEFAULT_INDEX = "https://pypi.tuna.tsinghua.edu.cn/simple"
#   $env:UV_PYTHON_INSTALL_MIRROR = "https://mirror.nju.edu.cn/github-release/astral-sh/python-build-standalone/"

$ErrorActionPreference = "Stop"

# Move to the repository root (parent of this script's directory).
Set-Location (Join-Path $PSScriptRoot "..")

if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Error "'uv' is not installed. Install it: powershell -c `"irm https://astral.sh/uv/install.ps1 | iex`""
    exit 1
}

# Create the virtual environment (uv downloads Python 3.12 if needed).
Write-Host "Creating virtual environment (.venv) with Python 3.12..."
uv venv --python 3.12

# Activate it so the tools below resolve to this project's .venv. (This repo has no
# pyproject.toml, so `uv run` cannot auto-discover the environment.)
& .venv\Scripts\Activate.ps1

# Install runtime + dev + type-stub dependencies, plus pre-commit.
Write-Host "Installing dependencies from requirements-all.txt..."
uv pip install -r requirements-all.txt pre-commit

# Install the git pre-commit hooks (commit + commit-msg stages).
Write-Host "Installing pre-commit hooks..."
pre-commit install
pre-commit install --hook-type commit-msg

# commitlint (a commit-msg hook) needs its shared config; install it if npm exists.
if (Get-Command npm -ErrorAction SilentlyContinue) {
    Write-Host "Installing @commitlint/config-conventional..."
    npm install --no-fund --no-audit @commitlint/config-conventional
} else {
    Write-Warning "'npm' not found - skipping @commitlint/config-conventional."
    Write-Warning "Install Node.js if the commitlint commit-msg hook fails."
}

Write-Host ""
Write-Host "Done. The environment is active in this shell. In new shells, activate with:"
Write-Host "  .venv\Scripts\Activate.ps1"
Write-Host "Then run tools directly, e.g.:"
Write-Host "  python -m pytest ./tests/"
Write-Host "  pre-commit run --all-files"
