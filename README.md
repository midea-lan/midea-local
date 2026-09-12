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
`--username`/`--password`/`--cloud-name` again.

```json
{
  "username": "user@example.com",
  "password": "your-cloud-password",
  "cloud_name": "SmartHome"
}
```

All fields are optional; only include what you need. Run
`python3 -m midealocal.cli discover -h` for the full option list.

#### `midea-devices.json` token/key cache

Every device needs a token/key pair, normally fetched from the cloud on
each run. `discover` caches the pair that successfully connects to a device
in `midea-devices.json`, keyed by `device_id`, and `_get_keys` checks this
cache before contacting the cloud at all. In practice this means only the
_first_ `discover`/`setattr` run for a given device needs your cloud
credentials — every run after that connects straight to the device with the
cached key, with no cloud login required. The file is managed automatically;
you don't need to create or edit it yourself.

```json
{
  "devices": [
    {
      "device_id": "146235046630006",
      "token": "...",
      "key": "..."
    }
  ]
}
```

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
