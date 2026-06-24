# 250mon

Lightweight hardware monitor for AMD Cyan Skillfish (BC-250) GPU and CPU.

Reads frequency, voltage, temperature, load, power, and usage from sysfs/procfs. Outputs CSV, JSON, live dashboards, WebSocket streams, and plots.

> Tested on CachyOS (Arch-based) with AMD BC-250 APU.

## Dependencies

**250mon** (core):
- `bash`, `awk`, `grep`, `sed`, `date`, `sleep`
- No external packages required

**250mon-draw** (plotting):
- `python3`, `matplotlib`

**250mon-serve** (WebSocket):
- `python3`, `websockets`

## Install

```bash
sudo cp 250mon 250mon-draw 250mon-serve /usr/local/bin/
sudo chmod +x /usr/local/bin/250mon /usr/local/bin/250mon-draw /usr/local/bin/250mon-serve
```

## Usage

```
250mon [OPTIONS]

Component selection (default: both GPU and CPU):
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

Service:
  --service [ACTION]  Run as service (no arg: daemon; install|uninstall|start|stop|restart)
  --serve [PORT]      Start WebSocket server (default: 25052)

Info:
  -h, --help          Show this help message
  -v, --version       Show version
```

## Metrics

### GPU

| Column | Description | Source |
|--------|-------------|--------|
| `gpu_freq_mhz` | GPU shader clock (MHz) | `pp_dpm_sclk` |
| `gpu_voltage_mv` | GPU core voltage (mV) | `pp_od_clk_voltage` |
| `gpu_temp_c` | GPU temperature (°C) | hwmon/amdgpu |
| `gpu_load_pct` | GPU busy % (null if unsupported) | `gpu_busy_percent` |
| `gpu_mem_clock_mhz` | Memory clock (MHz) | `pp_dpm_mclk` |
| `gpu_power_w` | GPU power draw (W) | hwmon power1_average |
| `gpu_vram_used_mib` | VRAM used (MiB) | `mem_info_vram_used` |
| `gpu_vram_total_mib` | VRAM total (MiB) | `mem_info_vram_total` |

### CPU

| Column | Description | Source |
|--------|-------------|--------|
| `cpu_freq_mhz` | Average CPU frequency (MHz) | `/proc/cpuinfo` |
| `cpu_temp_c` | CPU temperature (°C) | k10temp hwmon |
| `cpu_usage_pct` | Aggregate CPU usage (%) | `/proc/stat` |
| `nvme_temp_c` | NVMe temperature (°C) | nvme hwmon |

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
| `state.json` | All values as JSON |
| `gpu_freq` | GPU frequency (MHz) |
| `gpu_temp` | GPU temperature (°C) |
| `gpu_power` | GPU power draw (W) |
| `gpu_voltage` | GPU voltage (mV) |
| `gpu_mem_clock` | GPU memory clock (MHz) |
| `gpu_vram_used` | VRAM used (MiB) |
| `gpu_vram_total` | VRAM total (MiB) |
| `cpu_freq` | CPU frequency (MHz) |
| `cpu_temp` | CPU temperature (°C) |
| `cpu_usage` | CPU usage (%) |
| `nvme_temp` | NVMe temperature (°C) |

```bash
cat /run/250mon/state.json      # Read all state
cat /run/250mon/gpu_temp        # Read individual metric
```

## WebSocket Server

Stream live state to clients (web dashboards, scripts, etc.):

```bash
250mon --serve          # Default port 25052
250mon --serve 8080     # Custom port
```

Streams `state.json` to all connected clients every second.

Requires: `python3`, `websockets` module (`pip install websockets`)

### Client example

```javascript
const ws = new WebSocket("ws://localhost:25052");
ws.onmessage = (e) => console.log(JSON.parse(e.data));
```

## License

MIT
