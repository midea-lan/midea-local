#!/usr/bin/env bash
# Sync /usr/local/py-utils tool venvs with the system pip versions.
# Upgrades any tool whose venv version is older than what pip has installed.

set -euo pipefail

VENVS_DIR="/usr/local/py-utils/venvs"
UPDATED=0
SKIPPED=0
NOT_FOUND=0

pkg_version_in_venv() {
    local venv="$1"
    local pkg="$2"
    # Expand the python version glob using ls -d
    local site_packages
    site_packages=$(ls -d "${venv}/lib/python"*/site-packages 2>/dev/null | head -1)
    if [[ -z "${site_packages}" ]]; then
        return 1
    fi
    # Find the dist-info directory for this package (case-insensitive, handles dashes/underscores)
    local dist_info
    dist_info=$(find "${site_packages}" -maxdepth 1 -type d \
        -iname "${pkg}-*.dist-info" 2>/dev/null | head -1)
    if [[ -z "${dist_info}" ]]; then
        return 1
    fi
    # Extract version from directory name: <pkg>-<version>.dist-info
    basename "${dist_info}" | sed 's/\.dist-info$//' | rev | cut -d- -f1 | rev
}

pkg_version_in_sys() {
    local pkg="$1"
    pip show "${pkg}" 2>/dev/null | awk '/^Version:/{print $2}'
}

# Compare two version strings; returns 0 if $1 < $2
version_lt() {
    python3 -c "
import sys
from packaging.version import Version
sys.exit(0 if Version('$1') < Version('$2') else 1)
" 2>/dev/null
}

for venv_dir in "${VENVS_DIR}"/*/; do
    tool=$(basename "${venv_dir}")

    venv_ver=$(pkg_version_in_venv "${venv_dir}" "${tool}" 2>/dev/null || true)
    if [[ -z "${venv_ver}" ]]; then
        echo "[SKIP] ${tool}: not found in venv"
        (( NOT_FOUND++ )) || true
        continue
    fi

    sys_ver=$(pkg_version_in_sys "${tool}" || true)
    if [[ -z "${sys_ver}" ]]; then
        echo "[SKIP] ${tool}: not found in system pip"
        (( SKIPPED++ )) || true
        continue
    fi

    if version_lt "${venv_ver}" "${sys_ver}"; then
        echo "[UPDATE] ${tool}: ${venv_ver} -> ${sys_ver}"
        "${venv_dir}bin/python" -m pip install --quiet --upgrade "${tool}==${sys_ver}"
        (( UPDATED++ )) || true
    else
        echo "[OK]     ${tool}: ${venv_ver}"
        (( SKIPPED++ )) || true
    fi
done

echo ""
echo "Done. Updated: ${UPDATED}, Already up-to-date: ${SKIPPED}, Not found: ${NOT_FOUND}"
