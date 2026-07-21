ARG VARIANT=3.14
FROM mcr.microsoft.com/vscode/devcontainers/python:${VARIANT}-bookworm

# Install uv (the project's dev-environment manager) from the official image.
# Pinned to a minor version for reproducibility; bump as needed.
COPY --from=ghcr.io/astral-sh/uv:0.11 /uv /uvx /usr/local/bin/

# define apt default source
ARG APT_MIRROR_DOMAIN="deb.debian.org"
# uv package index + Python download mirror (empty => uv defaults / PyPI).
# China users can override these, e.g.:
#   UV_DEFAULT_INDEX=https://pypi.tuna.tsinghua.edu.cn/simple
#   UV_PYTHON_INSTALL_MIRROR=https://mirror.nju.edu.cn/github-release/astral-sh/python-build-standalone/
ARG UV_DEFAULT_INDEX=""
ARG UV_PYTHON_INSTALL_MIRROR=""
ENV UV_DEFAULT_INDEX=${UV_DEFAULT_INDEX} \
    UV_PYTHON_INSTALL_MIRROR=${UV_PYTHON_INSTALL_MIRROR}

# [Option] Install Node.js (needed for the commitlint commit-msg hook)
ARG INSTALL_NODE="true"
ARG NODE_VERSION="lts/*"
RUN if [ "${INSTALL_NODE}" = "true" ]; then su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi

# [Optional] Override APT mirror for China users:
# Set in your local shell profile: export APT_MIRROR_DOMAIN="mirrors.tuna.tsinghua.edu.cn"
RUN if [ -n "${APT_MIRROR_DOMAIN}" ] && [ "${APT_MIRROR_DOMAIN}" != "deb.debian.org" ]; then \
    cp /etc/apt/sources.list /etc/apt/sources.list.bak && \
    sed -i "s|deb.debian.org|${APT_MIRROR_DOMAIN}|g" /etc/apt/sources.list && \
    sed -i "s|security.debian.org|${APT_MIRROR_DOMAIN}|g" /etc/apt/sources.list && \
    apt-get clean all && rm -rf /var/lib/apt/lists/* && apt-get update; \
    fi

# Pre-warm the uv cache with the 3.12 interpreter + project dependencies and
# pre-commit, so the first container start (scripts/setup.sh) is fast. The
# workspace .venv itself is created on create by scripts/setup.sh (see the
# devcontainer.json postCreateCommand); this only populates uv's global cache.
COPY requirements*.txt /tmp/uv-tmp/
RUN su vscode -c "uv venv /tmp/uv-tmp/.venv --python 3.12 \
    && VIRTUAL_ENV=/tmp/uv-tmp/.venv uv pip install -r /tmp/uv-tmp/requirements-all.txt pre-commit" \
    && rm -rf /tmp/uv-tmp/.venv

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>
