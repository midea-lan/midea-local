# Midea DA washer LAN diagnostics

A small Windows toolkit for discovering a Midea/Little Swan DA washer on the local network and viewing the status attributes it actually reports. It uses the open-source [`midea-local`](https://github.com/midea-lan/midea-local) package; attribution and license boundaries are in [ATTRIBUTION.md](ATTRIBUTION.md).

The monitor is read-only: it sends LAN discovery and status queries, exposes an HTTP page bound to `127.0.0.1`, and has no control endpoint. It does not start a washer, change settings, reset pairing, access cloud credentials, or flash firmware.

## Windows quick start

1. Install Python 3.12 with the Windows Python launcher (`py`).
2. Double-click `install.bat` once. It creates an isolated `.venv` and installs `midea-local` 14.x.
3. Double-click `start_live_monitor.bat`. On first use, it discovers DA V1/V2 devices and asks you to select the washer. Device identifiers are written only to the ignored local file `discovery_round2_targeted.json`.
4. The browser opens `http://127.0.0.1:8765/`. Keep the console window open; press Ctrl+C there to stop.

At later launches, the tool rediscovers the selected device by its local device ID and updates its IP, so a DHCP address change does not require editing code. If more than one DA washer is present, the selection is only done at first setup.

## What the page shows

The page shows the DA attributes returned by the current library/device combination, raw program and water-level codes, raw response body, error code, and a rolling water-level-code chart. The target interval is one second; actual timing depends on the device reply and can be slower. A returned `wash_level` is a controller setting code, not measured water volume. The module does not expose capacitive-electrode state, analog pressure-sensor readings, or motor current through this status API.

For a file-based sampler, first initialize the same local device file, then run `run_diagnosis.py` with an allowed label such as `idle` or `wash_abnormal`. The sampler is also read-only. Run `plot_diagnosis.py` to render an SVG from local CSV files.

## Privacy and safety

The repository intentionally contains no device IP, serial number, MAC address, discovery result, live CSV/JSONL, or raw device payload. Local discovery and status logs can contain device identifiers; do not publish those files. The `.gitignore` excludes them by default.

Do not operate the washer with an exposed control board, wiring, or removed protective cover. Disconnect mains power before handling the board or touch electrodes. The LAN page is not an electrical safety instrument and cannot prove that the appliance is safe to run.

## Case notes

See [CASE_STUDY_ZH.md](CASE_STUDY_ZH.md) for an anonymized, evidence-limited example.
