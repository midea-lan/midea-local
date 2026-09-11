# Midea-local python lib

[![Python build](https://github.com/midea-lan/midea-local/actions/workflows/python-build.yml/badge.svg)](https://github.com/midea-lan/midea-local/actions/workflows/python-build.yml)
[![codecov](https://codecov.io/github/midea-lan/midea-local/graph/badge.svg?token=8V0C1T2GJA)](https://codecov.io/github/midea-lan/midea-local)

> [中文版 / Chinese README](./README_hans.md)

Control your Midea M-Smart appliances via local area network.

This library is part of https://github.com/georgezhao2010/midea_ac_lan code. It was separated to segregate responsibilities.

⭐If this component is helpful for you, please star it, it encourages me a lot.

## Getting started

### Finding your device

```python3
from midealocal.discover import discover

# Without knowing the ip address
discover()
# If you know the ip address
discover(ip_address="203.0.113.11")
# The device type is in hexadecimal as in midealocal/devices/TYPE
type_code = hex(list(discover().values())[0]["type"])[2:]
```

### Getting data from device

```python3
from midealocal.discover import discover
from midealocal.devices import device_selector

token = "..."
key = "..."

# Get the first device
d = list(discover().values())[0]
# Select the device
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

# Connect and authenticate
ac.connect()

# Getting the attributes
print(ac.attributes)
# Setting the temperature
ac.set_target_temperature(23.0, None)
# Setting the swing
ac.set_swing(False, False)
```

### command line tool

```python3
python3 -m midealocal.cli -h
```

#### `midea-local.json` config file

`python3 -m midealocal.cli save` writes your cloud username, password and
cloud name to `midea-local.json` in the current directory (use `--user` to
save it to your user config folder instead). Every `midealocal.cli` command
then loads that file automatically, so you don't have to pass
`--username`/`--password`/`--cloud-name` again — use `--configfile <path>` to
point at a different file instead.

For `discover`, the file can also carry `skip_discovery: true` with a
device's `ip`, `token` and `key` (e.g. captured from a previous `discover`
run). When set, discovery skips the cloud key lookup entirely and connects
straight to that device with the stored credentials. It still performs the
local network probe first, since some devices only answer status queries
once they've seen it.

```json
{
  "username": "user@example.com",
  "password": "your-cloud-password",
  "cloud_name": "SmartHome",
  "skip_discovery": true,
  "ip": "192.168.1.65",
  "token": "...",
  "key": "..."
}
```

All fields are optional; only include what you need. Run
`python3 -m midealocal.cli discover -h` for the full option list.

## Development

This project uses [uv](https://docs.astral.sh/uv/) for its development environment.
After [installing uv](https://docs.astral.sh/uv/getting-started/installation/):

```bash
git clone https://github.com/midea-lan/midea-local.git
cd midea-local
./scripts/setup.sh          # Linux / macOS / WSL2  (Windows: scripts\setup.ps1)
```

This creates a `.venv`, installs all dependencies, and sets up the prek hooks.
Run tools with `uv run`, e.g. `uv run python -m pytest ./tests/`. See the contributing
guide for the full workflow and per-OS uv install instructions.

## Contributing Guide

[CONTRIBUTING](.github/CONTRIBUTING.md)
[中文版CONTRIBUTING](.github/CONTRIBUTING.zh.md)
