# hw-logger

Lightweight bash logger for AMD Cyan Skillfish (BC-250) GPU and CPU metrics.

Reads frequency, voltage, temperature, load, and usage from sysfs/procfs and outputs in CSV or JSON format.

## Dependencies

- `bash`
- `awk`, `grep`, `sed`
- `date`, `sleep`

No external packages required.

## Usage

```
hw-logger [OPTIONS]

Component selection (default: both GPU and CPU):
  --gpu               Log GPU metrics only
  --cpu               Log CPU metrics only

Options:
  -i, --interval MS   Sampling interval in milliseconds (default: 1000)
  -f, --format FMT    Output format: csv or json (default: csv)
  -o, --output FILE   Log to file (default: ~/hwlog-YYYYMMDD-HHMMSS.<ext>)
  -q, --quiet         Suppress stdout, write to file only
  -c, --count N       Number of samples then exit (default: infinite)
  -h, --help          Show help message
  -v, --version       Show version
```

## Metrics

### GPU

| Column | Description | Source |
|--------|-------------|--------|
| `gpu_freq_mhz` | GPU shader clock | `pp_dpm_sclk` |
| `gpu_voltage_mv` | GPU core voltage | `pp_od_clk_voltage` |
| `gpu_temp_c` | GPU temperature | `hwmon/amdgpu` |
| `gpu_load_pct` | GPU busy % | `gpu_busy_percent` |
| `gpu_mem_clock_mhz` | Memory clock | `pp_dpm_mclk` |

### CPU

| Column | Description | Source |
|--------|-------------|--------|
| `cpu_freq_mhz` | Average CPU frequency | `/proc/cpuinfo` |
| `cpu_temp_c` | CPU temperature | `k10temp` hwmon |
| `cpu_usage_pct` | Aggregate CPU usage | `/proc/stat` |

## Examples

```bash
# Log to ~/hwlog-YYYYMMDD-HHMMSS.csv
hw-logger

# GPU only, 100ms interval, JSON (saves to ~/hwlog-YYYYMMDD-HHMMSS.jsonl)
hw-logger --gpu -i 100 -f json

# CPU only, 500ms, 60 samples
hw-logger --cpu -i 500 -c 60

# Custom output file, quiet
hw-logger -i 2000 -o hw.csv -q
```

## CSV Output

```csv
timestamp,gpu_freq_mhz,gpu_voltage_mv,gpu_temp_c,gpu_load_pct,gpu_mem_clock_mhz,cpu_freq_mhz,cpu_temp_c,cpu_usage_pct
2026-06-24T12:00:01-0300,350,699,52.0,,450,3592,59.8,36.9
```

## JSON Output

```json
{"timestamp":"2026-06-24T12:00:01-0300","gpu_freq_mhz":350,"gpu_voltage_mv":699,"gpu_temp_c":52.0,"gpu_load_pct":null,"gpu_mem_clock_mhz":450,"cpu_freq_mhz":3592,"cpu_temp_c":59.8,"cpu_usage_pct":36.9}
```

> Note: `gpu_load_pct` is `null` when `gpu_busy_percent` is not supported by the driver.

## Install

```bash
sudo cp hw-logger /usr/local/bin/
sudo chmod +x /usr/local/bin/hw-logger
```

## License

MIT
