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

### Reusing a known device and discovery metadata

`create_device(descriptor, credentials, profile=None)` constructs a device without
network I/O. Save `device.descriptor.to_dict()` in your application's store; load it
with `DeviceDescriptor.from_dict()`. Credentials remain separate. The old
`device_selector()` and `connect()` defaults are unchanged.

```python
from midealocal.device_info import DeviceCredentials, DeviceDescriptor, DiscoveryProfile
from midealocal.devices import create_device
from midealocal.devices.ac import MideaACDevice

# saved_descriptor and saved_profile come from your application's storage.
descriptor = DeviceDescriptor.from_dict(saved_descriptor)
try:
    profile = DiscoveryProfile.from_dict(saved_profile) if saved_profile else None
except ValueError:
    profile = None
device = create_device(descriptor, DeviceCredentials(token=token, key=key), profile)
try:
    if not device.connect(check_protocol=True, readiness="control"):
        raise ConnectionError("Device did not become ready")
    device.open()
    if isinstance(device, MideaACDevice) and device.supports_confirmed_controls:
        actual = device.set_attributes({"mode": 2, "target_temperature": 24}).result()
        print(actual)
    # Persist this JSON-compatible metadata through your own storage layer.
    profile = device.export_discovery_profile()
    profile_data = profile.to_dict() if profile is not None else None
finally:
    device.close()
```

- `connect(False)` authenticates only. `connect(True)` performs the existing full
  probe. `connect(True, readiness="control")` waits for fresh basic state on ordinary
  ACs, then `open()` collects optional data through the background receiver. Other
  devices and ACs with specialized state protocols retain the full probe.
- `discovery_complete` means the initial discovery attempt window has ended, not
  that every capability replied. Subscribe with `register_update()` before `open()`;
  keep handling late updates and add newly discovered entities as needed. Completion
  sends `{"discovery_complete": True}`. Export updated profiles on subsequent updates.
- Profiles have a schema, device identity, and a seven-day validity window. Reusing
  one does not extend its timestamp. They contain confirmed protocol/capability
  metadata, never credentials, live state, or timeout-based unsupported conclusions.
  Invalid/expired profiles are ignored. If connection with a hint fails, retry once
  with a new device and no profile, and discard the old stored hint.
- Ordinary AC `set_attributes()` combines power, mode, temperature, fan speed, and
  swing changes into one SET. It first reads fresh state and then confirms the
  requested values with fresh C0 replies, retrying queries only. Named fan speeds
  use the existing mode buckets to tolerate firmware reporting AUTO as 103 for a
  command of 102; returned values are the actual readings. Failure raises via
  the Future; it does not prove the physical SET failed. `confirm=False` skips
  readback and returns `{}`. Temperature values must be encodable in half-degree
  steps. Confirmation has a five-second response budget after sending the command.
- `submit_operation()` serializes operations on the device's receiver thread and
  wakes it promptly. Before `open()`, it executes synchronously. Never submit from
  a device update callback or block the application's event loop on `.result()`;
  use an executor or `asyncio.wrap_future()` for a running device. Low-level socket
  calls must not run concurrently with queued operations. AC legacy setters also
  use the queue while the device is running.

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
in `midea-devices.json`, keyed by `device_id`, and tries that cached pair
first on every later run — before contacting the cloud at all. In practice
this means only the _first_ `discover`/`setattr` run for a given device
needs your cloud credentials. If a cached key ever stops working (e.g. the
device was re-paired), `discover` automatically falls back to fetching a
fresh key from the cloud and updates the cache. The file is managed
automatically; you don't need to create or edit it yourself.

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
