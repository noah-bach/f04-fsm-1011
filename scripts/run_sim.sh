#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$project_dir"
for tool in iverilog vvp git sha256sum date tee; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'STOP: missing command %s; send this output to your tutor.\n' "$tool" >&2
        exit 1
    fi
done
run_id="$(date -u +%Y%m%dT%H%M%SZ)_$$"
run_dir="$project_dir/build/sim_runs/$run_id"
mkdir -p "$run_dir"
sources=(rtl/f04_mealy.sv rtl/f04_moore.sv rtl/tt_um_f04_fsm_1011.sv tb/tb_f04.sv)
{
    printf 'run_id=%s\ndate_utc=%s\n' "$run_id" "$(date -u +%FT%TZ)"
    printf 'purpose=F04_first_functional_simulation\n'
    printf 'clock_period_ns=10 (simulation illustration, not Fmax)\n'
    printf 'seed_data_hex=F0410111\nseed_unused_pins_hex=13579BDF\n'
    printf 'pdk=not_used\nppa=not_measured\n'
    printf 'git_HEAD_of_repository_at_run_time='; git rev-parse HEAD
    printf 'git_status_begin\n'; git status --short; printf 'git_status_end\n'
    printf 'NOTE=source_files_may_be_uncommitted; use hashes below as well as HEAD\n'
    printf 'iverilog_version_begin\n'; iverilog -V 2>&1 || true
    printf 'iverilog_version_end\nvvp_version_begin\n'; vvp -V 2>&1 || true
    printf 'vvp_version_end\nsource_sha256_begin\n'
    sha256sum "${sources[@]}" scripts/run_sim.sh
    printf 'source_sha256_end\n'
    printf 'compile_cwd=%s\n' "$project_dir"
    printf 'compile_command=iverilog -g2012 -Wall -s tb_f04 -o %s/sim.vvp rtl/f04_mealy.sv rtl/f04_moore.sv rtl/tt_um_f04_fsm_1011.sv tb/tb_f04.sv\n' "$run_dir"
    printf 'simulate_cwd=%s\nsimulate_command=vvp sim.vvp\n' "$run_dir"
} > "$run_dir/manifest.txt"
printf 'Compile log: %s/compile.log\n' "$run_dir"
iverilog -g2012 -Wall -s tb_f04 -o "$run_dir/sim.vvp" "${sources[@]}" 2>&1 | tee "$run_dir/compile.log"
printf 'Simulation log: %s/sim.log\n' "$run_dir"
(
    cd "$run_dir"
    vvp sim.vvp 2>&1 | tee sim.log
)
printf '%s\n' "$run_dir" > "$project_dir/build/LAST_SIM_RUN.txt"
printf 'Evidence folder: %s\n' "$run_dir"
printf 'Open waveform with: bash scripts/view_wave.sh\n'
