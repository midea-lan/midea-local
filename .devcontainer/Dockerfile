ARG VARIANT=3.14
FROM mcr.microsoft.com/vscode/devcontainers/python:${VARIANT}-bookworm

# define apt default source
ARG APT_MIRROR_DOMAIN="deb.debian.org"
# define pip default source
ARG PIP_MIRROR_DOMAIN="pypi.org"

# [Option] Install Node.js
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

# [Optional] Override pip mirror for China users:
# Set in your local shell profile: export PIP_MIRROR_DOMAIN="pypi.tuna.tsinghua.edu.cn"
RUN if [ -n "${PIP_MIRROR_DOMAIN}" ] && [ "${PIP_MIRROR_DOMAIN}" != "pypi.org" ]; then \
    echo "[global]" > /etc/pip.conf && \
    echo "index-url = https://${PIP_MIRROR_DOMAIN}/simple" >> /etc/pip.conf && \
    echo "trusted-host = ${PIP_MIRROR_DOMAIN}" >> /etc/pip.conf; \
    fi

# Install Python dependencies from requirements
COPY requirements*.txt /tmp/pip-tmp/
RUN pip3 --disable-pip-version-check --no-cache-dir install -r /tmp/pip-tmp/requirements-all.txt \
   && rm -rf /tmp/pip-tmp

RUN pip3 --disable-pip-version-check --no-cache-dir install pre-commit

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>
