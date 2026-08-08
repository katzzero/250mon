# 250mon

Lightweight hardware monitor for AMD Cyan Skillfish (BC-250) GPU and CPU.

Reads frequency, voltage, temperature, power, usage, and fan speed from sysfs/procfs. Outputs CSV, JSON, live dashboards, WebSocket streams, and plots.

> Tested on CachyOS (Arch-based) with AMD BC-250 APU.

## Dependencies

**250mon** (core):
- `bash`, `awk`, `grep`, `sed`, `date`, `sleep`
- `python3` (for SMU voltage/frequency reading, no pip packages needed)

**250mon-draw** (plotting):
- `python3`, `matplotlib`

**250mon-serve** (WebSocket):
- `python3`, `websockets`

## Install

```bash
./install.sh                      # install to /usr/local/bin (auto sudo)
./install.sh --prefix /usr        # install to /usr/bin
./install.sh uninstall            # remove
```

For packaging (PKGBUILD), use a staged install with no system impact:

```bash
./install.sh --destdir "$pkgdir"
```

Installs `250mon`, `250mon-smu`, `250mon-draw`, `250mon-serve`, and `250mon_usage.py`.

### Fan Sensor Driver (Optional)

The BC-250 requires a custom driver to expose fan speed sensors:

```bash
# Install development headers
sudo pacman -S base-devel git linux-cachyos-headers

# Clone and compile the driver
git clone https://github.com/Fred78290/nct6687d.git
cd nct6687d
sudo make install

# Configure kernel module
echo 'options nct6687 force=true' | sudo tee /etc/modprobe.d/sensors.conf
echo 'nct6687' | sudo tee /etc/modules-load.d/99-sensors.conf

# Rebuild initramfs and reboot
sudo mkinitcpio -P
sudo reboot
```

## Usage

```
250mon [OPTIONS]

Component selection (default: full GPU and CPU):
  --gpu               Log GPU metrics only
  --cpu               Log CPU metrics only

Logging:
  -i, --interval MS   Sampling interval in milliseconds (default: 1000)
  -f, --format FMT    Output format: csv or json (default: csv)
  -o, --output FILE   Log to file (default: ~/250mon-YYYYMMDD-HHMMSS.<ext>)
  -q, --quiet         Suppress stdout, write to file only
  -c, --count N       Number of samples then exit (default: infinite)
  --max-size SIZE     Rotate log at size limit (e.g., 10M, 500K, 1G)
  --rotate N          Keep max N rotated files (default: 5)

Live display:
  -w, --watch         Single-line live display (Ctrl+C to exit)
  --live              Full-screen live dashboard (Ctrl+C to exit)
  --spark             Show sparklines in live dashboard (--live only)

Plotting:
  --draw              Print ASCII chart after logging (default: 60 samples)
  --plot              Generate plot image after logging (default: 30 samples)
  --plot-metrics M    Metrics to plot (comma-separated, passed to 250mon-draw)

Advanced:
  --per-core          Log per-core CPU frequencies instead of average
  --list-states       List GPU clock states and exit

Service:
  --service [ACTION]  Run as service (no arg: daemon; install|uninstall|start|stop|restart)

Info:
  -h, --help          Show this help message
  -v, --version       Show version
```

### 250mon-serve

```
250mon-serve [mode] [options]

Modes:
  ws [port] [interval]           WebSocket only
  http [port] [interval]         HTTP only
  full [ws_port] [http_port]     Both servers

Defaults from config.toml if no mode given.
```

## Metrics

### GPU

| Column | Description | Source |
|--------|-------------|--------|
| `gpu_freq_mhz` | GPU shader clock (MHz) | `pp_dpm_sclk` |
| `gpu_voltage_mv` | GPU core voltage (mV) | `pp_od_clk_voltage` |
| `gpu_temp_c` | GPU temperature (°C) | hwmon/amdgpu |
| `gpu_mem_clock_mhz` | Memory clock (MHz) | `pp_dpm_mclk` |
| `gpu_power_w` | GPU power draw (W) | hwmon power1_average |
| `gpu_vram_used_mib` | VRAM used (MiB) | `mem_info_vram_used` |
| `gpu_vram_total_mib` | VRAM total (MiB) | `mem_info_vram_total` |

### CPU

| Column | Description | Source |
|--------|-------------|--------|
| `cpu_freq_mhz` | Average CPU frequency (MHz) | `/proc/cpuinfo` |
| `cpu_voltage_mv` | CPU core voltage (mV) | SMU (embedded) |
| `cpuN_freq_mhz` | Per-core frequency by physical core id (with `--per-core`) | SMU (actual freq) |
| `cpuN_usage_pct` | Per-core usage by physical core id (with `--per-core`) | `/proc/stat` |
| `cpu_temp_c` | CPU temperature (°C) | k10temp hwmon |
| `cpu_usage_pct` | Aggregate CPU usage (%) | `/proc/stat` |
| `nvme_temp_c` | NVMe temperature (°C) | nvme hwmon |

### Memory

| Column | Description | Source |
|--------|-------------|--------|
| `ram_used_mib` | Used RAM (MiB) | `/proc/meminfo` |
| `ram_total_mib` | Total RAM (MiB) | `/proc/meminfo` |

### Fan

| Column | Description | Source |
|--------|-------------|--------|
| `fan_rpm` | Fan speed (RPM) | nct6686/nct6687 hwmon |

> **Note:** Fan monitoring requires the nct6687d driver. If not installed, `fan_rpm` will be empty and a warning will be shown.

## Examples

```bash
# Log to ~/250mon-YYYYMMDD-HHMMSS.csv
250mon

# GPU only, 100ms interval, JSON
250mon --gpu -i 100 -f json

# CPU only, 500ms, 60 samples
250mon --cpu -i 500 -c 60

# Custom output file, quiet
250mon -i 2000 -o hw.csv -q

# Single-line live display
250mon --watch

# Full-screen dashboard with sparklines
250mon --live --spark

# Log 30 samples then ASCII chart
250mon --draw -c 30

# Log 50 samples then save plot
250mon --plot -c 50

# Rotate logs at 10MB, keep 3 backups
250mon --max-size 10M --rotate 3

# Log per-core CPU frequencies (and per-core usage)
250mon --per-core -c 10

# List GPU clock states
250mon --list-states

# Run as background daemon
250mon --service

# Install systemd service
250mon --service install

# Start WebSocket server
250mon --serve
```

## Config File

Create `~/.config/250mon/config.toml` to set defaults:

```toml
interval = 1000
format = "csv"
gpu = true
cpu = true
max_size = "50M"
rotate = 5
```

CLI flags override config file values.

## Service Mode

Run 250mon as a background daemon writing live state to `/run/250mon/`:

```bash
250mon --service                # Start as daemon
250mon --service install        # Install systemd service (auto-start on boot)
250mon --service uninstall      # Remove service
250mon --service start          # Start service
250mon --service stop           # Stop service
250mon --service restart        # Restart service
```

### State files

| File | Description |
|------|-------------|
| `state.json` | All values as JSON with min/max |
| `gpu_freq` | GPU frequency (MHz) |
| `gpu_freq_min` / `gpu_freq_max` | Session min/max |
| `gpu_temp` | GPU temperature (°C) |
| `gpu_temp_min` / `gpu_temp_max` | Session min/max |
| `gpu_power` | GPU power draw (W) |
| `gpu_power_min` / `gpu_power_max` | Session min/max |
| `gpu_voltage` | GPU voltage (mV) |
| `gpu_voltage_min` / `gpu_voltage_max` | Session min/max |
| `gpu_mem_clock` | GPU memory clock (MHz) |
| `gpu_mem_clock_min` / `gpu_mem_clock_max` | Session min/max |
| `gpu_vram_used` | VRAM used (MiB) |
| `gpu_vram_used_min` / `gpu_vram_used_max` | Session min/max |
| `cpu_freq` | CPU frequency (MHz) |
| `cpu_freq_min` / `cpu_freq_max` | Session min/max |
| `cpu_temp` | CPU temperature (°C) |
| `cpu_temp_min` / `cpu_temp_max` | Session min/max |
| `cpu_usage` | CPU usage (%) |
| `cpu_usage_min` / `cpu_usage_max` | Session min/max |
| `nvme_temp` | NVMe temperature (°C) |
| `nvme_temp_min` / `nvme_temp_max` | Session min/max |
| `fan_rpm` | Fan speed (RPM) |
| `fan_rpm_min` / `fan_rpm_max` | Session min/max |
| `session_start` | Session start timestamp |
| `sample_count` | Number of samples collected |

```bash
cat /run/250mon/state.json      # Read all state with min/max
cat /run/250mon/gpu_temp        # Read individual metric (current)
cat /run/250mon/gpu_temp_min    # Read session minimum
cat /run/250mon/gpu_temp_max    # Read session maximum
```

### state.json format

```json
{
  "session": {"start": "2026-06-24T16:17:27-0300", "samples": 32},
  "gpu_freq": {"value": 350, "min": 350, "max": 350},
  "gpu_temp": {"value": 53.0, "min": 52.0, "max": 54.0},
  "gpu_power": {"value": 52.2, "min": 38.1, "max": 55.1},
  "cpu_freq": {"value": 2734, "min": 2360, "max": 3595},
  "cpu_temp": {"value": 61.9, "min": 60.9, "max": 61.9},
  "fan_rpm": {"value": 1064, "min": 1043, "max": 1076}
}
```

## WebSocket + HTTP Server

Stream live state to clients (web dashboards, scripts, etc.):

```bash
250mon-serve ws                          # WebSocket only
250mon-serve http                        # HTTP only
250mon-serve full                        # Both servers
250mon-serve full 8080 8081              # Custom ports
250mon-serve ws 8080 0.5                 # Custom port + interval
```

If no mode is given, reads from `config.toml`:
```toml
serve_mode = "ws"        # ws, http, or full
serve_ws_port = 25052
serve_http_port = 25053
serve_interval = 1.0
```

| Protocol | Default Port | Endpoint |
|----------|-------------|----------|
| WebSocket | 25052 | `ws://host:25052` |
| HTTP | 25053 | `GET http://host:25053/` |

Both return the same `state.json` with `{value, min, max}` per metric.

Requires: `python3`, `websockets` module (`pip install websockets`)

### Client examples

**WebSocket:**
```javascript
const ws = new WebSocket("ws://localhost:25052");
ws.onmessage = (e) => console.log(JSON.parse(e.data));
```

**HTTP:**
```bash
curl http://localhost:25053/
```

## License

MIT

## Acknowledgments

CPU voltage and per-core frequency reading based on [bc250_smu_oc](https://github.com/bc250-collective/bc250_smu_oc) (MIT License) by bc250-collective. The SMU communication code is embedded directly in `250mon-smu` — no external installation required.

### SMU vs /proc/cpuinfo

The `--per-core` flag uses SMU to read **actual** core frequencies, which differ from `/proc/cpuinfo`:

- `/proc/cpuinfo` reports the **requested** frequency (may show max even when idle)
- SMU reports the **real** frequency (shows actual clock, including power-gated cores)

All 8 physical cores are read positionally, so the two cores the BC-250 ships with
disabled (cores 3 and 7) appear automatically once unlocked (e.g. via the community
core-presence mask unlock, `SMN 0x5A870` 0x77 → 0xFF); disabled cores simply show
as empty until then.

Example:
```
Core  | SMU (actual) | cpuinfo (requested)
  3   |    1555 MHz  |     3491 MHz    ← cpuinfo shows max, SMU shows reality
```
