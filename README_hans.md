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
type_code = hex(list(discover().values())[0]["type"])[2:]
```

### 从设备获取数据

```python3
from midealocal.discover import discover
from midealocal.devices import device_selector

token = "..."
key = "..."

# 获取第一个设备
d = list(discover().values())[0]
# 选择设备
ac = device_selector(
    name="AC",
    device_id=d["device_id"],
    device_type=d["type"],
    ip_address=d["ip_address"],
    port=d["port"],
    token=token,
    key=key,
    device_protocol=d["protocol"],
    model=d["model"],
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

### 复用已知设备与探测快照

`create_device(descriptor, credentials, profile=None)` 使用已知信息构建设备，不执行
网络发现。调用方负责保存 `device.descriptor.to_dict()`，并用
`DeviceDescriptor.from_dict()` 恢复；凭据单独传入 `DeviceCredentials(token=..., key=...)`。
旧 `device_selector()` 和 `connect()` 的默认行为保持兼容。

- `connect(False)` 仅连接和认证；`connect(True)` 保留完整探测；
  `connect(True, readiness="control")` 在普通 AC 收到最新基础状态后即可返回，调用
  `open()` 后通过后台收包补充可选信息。其他设备、BB 和特殊温度协议 AC 保留完整探测。
- `discovery_complete` 表示初次探测响应窗口结束，不表示全部能力都有回复。请在
  `open()` 前用 `register_update()` 订阅，并持续处理晚到的回复、补建实体。
  窗口结束时会推送 `{"discovery_complete": True}`。
- `export_discovery_profile()` 返回可用 `.to_dict()` 序列化的 `DiscoveryProfile`，
  未确认协议时返回 `None`。存储由调用方实现；恢复使用 `DiscoveryProfile.from_dict()`，
  格式错误抛出 `ValueError`。快照校验设备身份、格式版本和默认七天有效期；重复导出不会
  续期。不保存凭据、实时状态或“超时即不支持”的结论。缓存连接失败后，应丢弃旧快照，
  用不带 profile 的新设备对象重试一次。
- 普通 AC 的 `set_attributes({"mode": 2, "target_temperature": 24})` 返回 Future：
  先读最新状态，用一个 SET 合并改动，再以新的 C0 回复确认。只重试查询，不重发 SET；
  确认失败会通过 Future 报错，但不能据此断言物理命令没有执行。`confirm=False` 跳过
  回读并返回空字典；温度需按半度编码。确认回复的总等待预算为五秒。
  新接口仅使用 CRC 正确、序号匹配当前查询的 C0 快照构建命令和确认结果，旧回复不能
  完成当前查询。同一连接验证过序号回显后，`supports_confirmed_controls` 才为真；
  不回显序号的固件继续使用旧 setter。新接口无法关联前置状态查询时，不会发出 SET。
  `mode=OFF` 转为关闭电源，保留设备记住的工作模式。
- 运行中操作由 `submit_operation()` 排到唯一收包线程，并立即唤醒该线程；尚未
  `open()` 时同步执行。设备回调内不能提交；应用事件循环不能直接等待 `.result()`，
  应使用 executor，或为运行中设备使用 `asyncio.wrap_future()`。不要把底层 socket
  调用与队列操作跨线程混用；运行中 AC 的旧 setter 也会进入队列。
  提交的函数必须可信且有执行时限；取消只阻止尚未开始的任务，关闭期间 Future 报错
  不代表正在执行的函数已经停止或物理命令没有执行。调用方负责快照来源及存储写权限。

英文 README 提供完整构建及控制示例。快照应在设备关闭前导出，并在后续能力更新时保存。

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

该脚本会创建 `.venv`、安装所有依赖并配置 prek 钩子。
使用 `uv run` 运行工具，例如 `uv run python -m pytest ./tests/`。
完整流程与各操作系统的 uv 安装说明请参见贡献指南。

## 贡献指南

[英文版 CONTRIBUTING](.github/CONTRIBUTING.md)
[中文版 CONTRIBUTING](.github/CONTRIBUTING.zh.md)
