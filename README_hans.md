# Midea-local Python 库

[![Python build](https://github.com/midea-lan/midea-local/actions/workflows/python-build.yml/badge.svg)](https://github.com/midea-lan/midea-local/actions/workflows/python-build.yml)
[![codecov](https://codecov.io/github/midea-lan/midea-local/graph/badge.svg?token=8V0C1T2GJA)](https://codecov.io/github/midea-lan/midea-local)

> [English README](./README.md)

通过局域网控制你的美的 M-Smart 智能家电。

本库源自 https://github.com/georgezhao2010/midea_ac_lan 项目，为了职责分离而拆分独立。

⭐ 如果这个组件对你有帮助，请点个 star，这对我是很大的鼓励。

## 快速开始

### 发现设备

```python3
from midealocal.discover import discover
# 未知 IP 地址时
discover()
# 已知 IP 地址时
discover(ip_address="203.0.113.11")
# 设备类型为十六进制，对应 midealocal/devices/TYPE
type_code = hex(list(discover().values())[0]['type'])[2:]
```

### 从设备获取数据

```python3
from midealocal.discover import discover
from midealocal.devices import device_selector

token = '...'
key = '...'

# 获取第一个设备
d = list(discover().values())[0]
# 选择设备
ac = device_selector(
  name="AC",
  device_id=d['device_id'],
  device_type=d['type'],
  ip_address=d['ip_address'],
  port=d['port'],
  token=token,
  key=key,
  device_protocol=d['protocol'],
  model=d['model'],
  subtype=0,
  customize="",
)

# 连接并认证
ac.connect()

# 获取属性
print(ac.attributes)
# 设置温度
ac.set_target_temperature(23.0, None)
# 设置摆风
ac.set_swing(False, False)
```

### 命令行工具

```python3
python3 -m midealocal.cli -h
```

## 开发环境

本项目使用 [uv](https://docs.astral.sh/uv/) 管理开发环境。
在[安装 uv](https://docs.astral.sh/uv/getting-started/installation/) 之后：

```bash
git clone https://github.com/midea-lan/midea-local.git
cd midea-local
./scripts/setup.sh          # Linux / macOS / WSL2 （Windows 使用 scripts\setup.ps1）
```

该脚本会创建 `.venv`、安装所有依赖并配置 pre-commit 钩子。
使用 `uv run` 运行工具，例如 `uv run python -m pytest ./tests/`。
完整流程与各操作系统的 uv 安装说明请参见贡献指南。

## 贡献指南

[英文版 CONTRIBUTING](.github/CONTRIBUTING.md)
[中文版 CONTRIBUTING](.github/CONTRIBUTING.zh.md)
