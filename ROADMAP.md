# 250mon Roadmap

## v0.1.0 — Current

- [x] GPU metrics: freq, voltage, temp, load, mem clock
- [x] CPU metrics: freq, temp, usage
- [x] CSV and JSON output formats
- [x] Configurable interval (ms)
- [x] Output to file (default: `~/250mon-YYYYMMDD-HHMMSS.<ext>`)
- [x] Component selection (`--gpu`, `--cpu`)
- [x] Quiet mode (`-q`)
- [x] Sample count limit (`-c`)
- [x] GPU power draw (watts)
- [x] VRAM usage (used/total in MiB)
- [x] NVMe temperature
- [x] 250mon-draw: Plotting tool (matplotlib, CSV/JSONL → PNG/SVG/PDF)
- [x] `--plot` flag: Auto-generate plot after logging

---

## v0.2.0 — Next

- [x] `--max-size SIZE` — Rotate log file at size limit (e.g., `10M`, `500K`)
- [x] `--rotate N` — Keep max N rotated files
- [x] Config file: `~/.config/250mon/config.toml`

## v0.3.0 — Enhancements

- [ ] `-w` / `--watch` — Single-line terminal display (live dashboard)
- [ ] `--daemon` — Run as systemd service with generated unit file
- [ ] Per-core CPU frequency logging (`--per-core`)
- [ ] GPU clock state listing (`--list-states`)

## v0.4.0 — Advanced

- [ ] SQLite export (`-f sqlite`)
- [ ] Network export (syslog, MQTT)
- [ ] Process-level GPU usage tracking
- [ ] Alert thresholds (temp/power limits with notifications)

## Ideas / Backlog

- [ ] Bash completion script
- [ ] Man page
- [ ] AUR package
- [ ] Nix flake
- [ ] Integration with cyan-skillfish-governor (read governor state)
