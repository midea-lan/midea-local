# 贡献指南（中文版）

> [English Version / 英文版点这里](./CONTRIBUTING.md)

感谢你为本项目做出贡献！
本指南介绍如何使用 **[uv](https://docs.astral.sh/uv/)** 和本地虚拟环境搭建开发环境，以及如何遵循我们的工作流与代码规范进行贡献。

GitHub 路径：`.github/CONTRIBUTING.zh.md`

---

## 目录

1. [概述](#1-概述)
2. [系统要求](#2-系统要求)
3. [安装 uv](#3-安装-uv)
4. [快速开始](#4-快速开始)
5. [Windows 用户](#5-windows-用户)
6. [中国大陆网络镜像](#6-中国大陆网络镜像)
7. [常用命令](#7-常用命令)
8. [提交与 Pull Request 工作流](#8-提交与-pull-request-工作流)
9. [代码风格、Pre-commit 与测试](#9-代码风格pre-commit-与测试)
10. [问题反馈与社区行为规范](#10-问题反馈与社区行为规范)

---

## 1. 概述

本项目使用 **uv** 管理 Python 工具链和本地 `.venv` 虚拟环境。uv 会自动为你安装合适的
Python 版本（支持 3.12–3.14），速度快，并且在 Linux、macOS、Windows 和 WSL2 上表现一致，
无需 Docker。

> ✅ 推荐：克隆仓库后运行一次 `./scripts/setup.sh`（Windows 上使用 `scripts\setup.ps1`），
> 它会创建 `.venv`、安装所有依赖并配置 pre-commit 钩子。

---

## 2. 系统要求

- **操作系统：** Linux / macOS / Windows / Windows + WSL2
- **[uv](https://docs.astral.sh/uv/)：** 管理 Python 与依赖（见[第 3 节](#3-安装-uv)）
- **Python：** ≥ 3.12 —— 你**无需**自行安装，uv 会按需下载
- **Git**
- **Node.js（可选）：** 仅用于 `commitlint` 提交信息钩子
- **编辑器：** 任意。使用 VS Code 时，工作区已预配置（`.vscode/`）指向 `.venv`；
  推荐扩展为 `charliermarsh.ruff` 和 `ms-python.python`。

---

## 3. 安装 uv

**macOS / Linux / WSL2：**

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**Windows（PowerShell）：**

```powershell
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
```

**其他方式：** `brew install uv`（macOS）、`pipx install uv`，或
`winget install --id=astral-sh.uv`（Windows）。更多方式见
[官方安装文档](https://docs.astral.sh/uv/getting-started/installation/)。

用 `uv --version` 验证是否安装成功。

---

## 4. 快速开始

```bash
git clone https://github.com/midea-lan/midea-local.git
cd midea-local
./scripts/setup.sh          # Windows：scripts\setup.ps1
```

该脚本会：

1. 用 Python 3.12 创建 `.venv`（`uv venv --python 3.12`），
2. 安装运行时 + 开发 + 类型声明依赖（`uv pip install -r requirements-all.txt`），
3. 安装 pre-commit 钩子（commit 与 commit-msg 阶段）。

**手动搭建**（与脚本等效）：

```bash
uv venv --python 3.12
uv pip install -r requirements-all.txt
uv run pre-commit install
uv run pre-commit install --hook-type commit-msg
```

之后可以激活环境（`source .venv/bin/activate`），或在命令前加 `uv run`
（例如 `uv run python -m pytest ./tests/`）。

---

## 5. Windows 用户

原生 Windows 已完整支持 —— 安装 uv（见[第 3 节](#3-安装-uv)）后，在 PowerShell 中运行
`scripts\setup.ps1` 即可。**WSL2 是可选的，并非必需。**

如果你更倾向于使用 WSL2：

1. 启用：`wsl --install -d Ubuntu`，然后 `wsl --set-default-version 2`。
2. 在 WSL **内部**使用 macOS/Linux 的命令安装 uv。
3. 将仓库克隆到 WSL 的 Linux 文件系统内（例如 `/home/<user>/midea-local`），
   不要放在 `C:\` 下，以避免性能和权限问题。

---

## 6. 中国大陆网络镜像

如果 PyPI 或 Python 下载较慢，可在运行 setup 脚本**之前**将 uv 指向镜像：

```bash
# PyPI 包镜像（以清华源为例）
export UV_DEFAULT_INDEX="https://pypi.tuna.tsinghua.edu.cn/simple"
# Python 解释器下载镜像
export UV_PYTHON_INSTALL_MIRROR="https://mirror.nju.edu.cn/github-release/astral-sh/python-build-standalone/"
```

在 Windows PowerShell 中使用 `$env:UV_DEFAULT_INDEX = "..."` 代替 `export`。
你也可以将它们写入 shell 配置文件长期生效。

---

## 7. 常用命令

| 任务                     | 命令                                                                          |
| ------------------------ | ----------------------------------------------------------------------------- |
| 运行全部测试             | `uv run python -m pytest ./tests/`                                            |
| 运行单个测试文件         | `uv run python -m pytest tests/devices/ac/message_ac_test.py`                 |
| 覆盖率报告               | `uv run python -m pytest --cov=midealocal --cov-report term-missing ./tests/` |
| 代码检查 / 格式化 / 类型 | `uv run pre-commit run --all-files`                                           |
| 仅运行 Ruff              | `uv run ruff check .` / `uv run ruff format .`                                |
| 构建软件包               | `uv run python -m build`                                                      |
| 新增依赖                 | 编辑 `requirements*.txt`，再执行 `uv pip install -r requirements-all.txt`     |

---

## 8. 提交与 Pull Request 工作流

1. 创建分支：

   ```bash
   git checkout -b feat/add-feature
   ```

2. 遵循 [Conventional Commits](https://www.conventionalcommits.org/) 提交信息规范：
   - `feat:` → 新功能
   - `fix:` → 修复 Bug
   - `chore:` → 工具、配置或非功能性更新
   - `docs:` → 仅文档
   - `refactor:` → 代码重构
   - `test:` → 仅测试

3. 示例：

   ```bash
   feat: add user authentication
   chore: update pre-commit hooks
   fix: correct API endpoint error
   ```

4. 推送并发起 Pull Request。
   GitHub Actions 会自动校验你的提交信息。
   请勿直接向 `main` 提交（`no-commit-to-branch` 钩子会阻止）。

---

## 9. 代码风格、Pre-commit 与测试

- **Pre-commit** 由 setup 脚本安装，并在每次提交时运行，包含：
  - `ruff` → 代码检查与格式化
  - `mypy` → 类型检查（严格模式）
  - `pylint` → 额外的静态分析
- 随时可用 `uv run pre-commit run --all-files` 运行完整套件，提交前请修复所有报告的问题。
- 测试使用 `pytest`。CI 会在 Python 3.12/3.13/3.14 × Linux/macOS/Windows 矩阵上运行完整的
  pre-commit 套件与测试，失败则阻止合并。

---

## 10. 问题反馈与社区行为规范

提交 Issue 时：

- 请包含复现步骤、日志和你的环境信息。
- 请保持尊重、简洁，并遵守社区准则。

---

**文件路径：**

- 英文：`.github/CONTRIBUTING.md`
- 中文：`.github/CONTRIBUTING.zh.md`
