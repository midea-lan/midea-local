ARG VARIANT=3.12
FROM mcr.microsoft.com/vscode/devcontainers/python:${VARIANT}-bullseye

# define apt default source
ARG APT_MIRROR_DOMAIN="deb.debian.org"
# define pip default source
ARG PIP_MIRROR_DOMAIN="pypi.org"

# [Option] Install Node.js
ARG INSTALL_NODE="true"
ARG NODE_VERSION="lts/*"
RUN if [ "${INSTALL_NODE}" = "true" ]; then su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi

# .bashrc or .zshrc add mirror site:
# export APT_MIRROR_DOMAIN="mirrors.tuna.tsinghua.edu.cn"
# --- BEGIN: APT China Mirror Configuration ---
RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak && \
    sed -i "s|deb.debian.org|${APT_MIRROR_DOMAIN}|g" /etc/apt/sources.list && \
    sed -i "s|security.debian.org|${APT_MIRROR_DOMAIN}|g" /etc/apt/sources.list && \
    apt-get clean all && rm -rf /var/lib/apt/lists/* && apt-get update

# .bashrc or .zshrc add mirror site:
# export PIP_MIRROR_DOMAIN="pypi.tuna.tsinghua.edu.cn"
# --- BEGIN: PIP China Mirror Configuration ---
RUN echo "[global]" > /etc/pip.conf && \
    echo "index-url = https://${PIP_MIRROR_DOMAIN}/simple" >> /etc/pip.conf && \
    echo "trusted-host = ${PIP_MIRROR_DOMAIN}" >> /etc/pip.conf
# --- END: PIP Mirror Configuration ---

# Install Python dependencies from requirements
COPY requirements*.txt /tmp/pip-tmp/
RUN pip3 --disable-pip-version-check --no-cache-dir install -r /tmp/pip-tmp/requirements-all.txt \
   && rm -rf /tmp/pip-tmp

RUN pip3 --disable-pip-version-check --no-cache-dir install pre-commit

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>
