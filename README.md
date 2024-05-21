# Midea-local python lib
[![Python build](https://github.com/rokam/midea-local/actions/workflows/python-build.yml/badge.svg)](https://github.com/rokam/midea-local/actions/workflows/python-build.yml)
![Python tests](https://raw.githubusercontent.com/rokam/midea-local/badges/tests.svg)
[![Python coverage](https://raw.githubusercontent.com/rokam/midea-local/badges/coverage.svg)](https://app.codecov.io/github/rokam/midea-local)
![Python fake8](https://raw.githubusercontent.com/rokam/midea-local/badges/flake8.svg)

Control your Midea M-Smart appliances via local area network.

This library is part of https://github.com/georgezhao2010/midea_ac_lan code. It was separated to segregate responsabilities.

⭐If this component is helpful for you, please star it, it encourages me a lot.

## Getting started

### Finding your device
```python
from midealocal.discover import discover
# Without knowing the ip address
discover()
# If you know the ip address
discover(ip_address="203.0.113.11")
# The device type is in hexadecimal and in midealocal/devices/TYPE
type_code = hex(list(d.values())[0]['type'])[2:]
```
