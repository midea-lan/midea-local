# Midea-local python lib

[![Python build](https://github.com/rokam/midea-local/actions/workflows/python-build.yml/badge.svg)](https://github.com/rokam/midea-local/actions/workflows/python-build.yml)
[![codecov](https://codecov.io/github/rokam/midea-local/graph/badge.svg?token=8V0C1T2GJA)](https://codecov.io/github/rokam/midea-local)

Control your Midea M-Smart appliances via local area network.

This library is part of https://github.com/georgezhao2010/midea_ac_lan code. It was separated to segregate responsibilities.

⭐If this component is helpful for you, please star it, it encourages me a lot.

## Getting started

### Finding your device

```python
from midealocal.discover import discover
# Without knowing the ip address
discover()
# If you know the ip address
discover(ip_address="203.0.113.11")
# The device type is in hexadecimal as in midealocal/devices/TYPE
type_code = hex(list(discover().values())[0]['type'])[2:]
```

### Getting data from device

```python
from midealocal.discover import discover
from midealocal.devices import device_selector

token = '...'
key = '...'

# Get the first device
d = list(discover().values())[0]
# Select the device
ac = device_selector(
  name="AC",
  device_id=d['device_id'],
  device_type=d['type'],
  ip_address=d['ip_address'],
  port=d['port'],
  token=token,
  key=key,
  protocol=d['protocol'],
  model=d['model'],
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
