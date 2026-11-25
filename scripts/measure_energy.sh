#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.cargo/bin:/Users/${SUDO_USER:-$USER}/.cargo/bin:$PATH"
export DEVELOPER_DIR=${DEVELOPER_DIR:-/Library/Developer/CommandLineTools}

STARS=${STARS:-5120}
STEPS=${STEPS:-280}
INTERVAL_MS=${INTERVAL_MS:-100}
IDLE_SECS=${IDLE_SECS:-5}

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=${OUT:-$ROOT/results/energy}
RAW=/tmp/orbit_energy_raw
mkdir -p "$OUT" "$RAW"

cd "$ROOT"
if [ ! -x target/debug/orbit-bench ] || [ ! -x target/release/orbit-bench ]; then
    cargo build --quiet
    cargo build --release --quiet
fi

sudo -v

sample_phase() {
    local name=$1
    shift
    local log="$RAW/$name.log"
    rm -f "$log"
    echo "== Measuring powermetrics: $name =="
    sudo powermetrics --samplers cpu_power,gpu_power,ane_power,tasks \
        --show-process-energy -i "$INTERVAL_MS" -b 1 -o "$log" > /dev/null 2>&1 &
    local pm_pid=$!
    sleep 0.4
    "$@"
    sleep 0.4
    sudo kill -INT "$pm_pid" 2> /dev/null || true
    wait "$pm_pid" 2> /dev/null || true
}

sample_phase idle sleep "$IDLE_SECS"
sleep 1
sample_phase baseline_debug    ./target/debug/orbit-bench --mode aos --stars "$STARS" --steps "$STEPS"
sleep 1
sample_phase baseline_release  ./target/release/orbit-bench --mode aos --stars "$STARS" --steps "$STEPS"
sleep 1
sample_phase optimized_release ./target/release/orbit-bench --mode soa --stars "$STARS" --steps "$STEPS"

if [ -n "${SUDO_USER:-}" ]; then
    sudo chown -R "$SUDO_USER" "$RAW" "$OUT"
fi

python3 "$ROOT/scripts/analyze_energy.py" "$RAW" "$OUT"
