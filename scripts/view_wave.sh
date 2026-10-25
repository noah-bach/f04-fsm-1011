#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
if ! command -v gtkwave >/dev/null 2>&1; then
    printf 'STOP: gtkwave not found; simulation logs can still be inspected.\n' >&2
    exit 1
fi
if [[ ! -f "$project_dir/build/LAST_SIM_RUN.txt" ]]; then
    printf 'STOP: run bash scripts/run_sim.sh successfully first.\n' >&2
    exit 1
fi
IFS= read -r run_dir < "$project_dir/build/LAST_SIM_RUN.txt"
if [[ ! -f "$run_dir/wave.vcd" ]]; then
    printf 'STOP: waveform not found: %s/wave.vcd\n' "$run_dir" >&2
    exit 1
fi
GDK_BACKEND=x11 gtkwave "$run_dir/wave.vcd"
