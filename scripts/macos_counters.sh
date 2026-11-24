#!/usr/bin/env bash
set -euo pipefail

STARS=${STARS:-5120}
STEPS=${STEPS:-280}

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=$ROOT/results/macos_counters
mkdir -p "$OUT"

cd "$ROOT"
cargo build --quiet
cargo build --release --quiet

run_one() {
    local name=$1
    shift
    local cmd="$* --stars $STARS --steps $STEPS"
    echo "== macOS M5 counters: $name ($cmd) =="
    {
        echo "$cmd"
        /usr/bin/time -l $cmd 2>&1
    } | tee "$OUT/$name.txt"
}

run_one baseline_debug    ./target/debug/orbit-bench --mode aos
run_one baseline_release  ./target/release/orbit-bench --mode aos
run_one optimized_release ./target/release/orbit-bench --mode soa

python3 - "$OUT" <<'PY' | tee "$OUT/summary.txt"
import pathlib, re, sys

out = pathlib.Path(sys.argv[1])
rows = []
for name in ["baseline_debug", "baseline_release", "optimized_release"]:
    text = (out / f"{name}.txt").read_text()
    elapsed = float(re.search(r"elapsed=([0-9.]+)s", text).group(1))
    mpairs = float(re.search(r"throughput=([0-9.]+)Mpairs/s", text).group(1))
    instr = int(re.search(r"(\d+)\s+instructions retired", text).group(1))
    cycles = int(re.search(r"(\d+)\s+cycles elapsed", text).group(1))
    rss = int(re.search(r"(\d+)\s+maximum resident set size", text).group(1))
    footprint = int(re.search(r"(\d+)\s+peak memory footprint", text).group(1))
    ipc = instr / cycles
    ghz = (cycles / elapsed) / 1e9
    rows.append((name, elapsed, mpairs, instr, cycles, ipc, ghz, rss, footprint))

print(f"{'variant':<18} {'time_s':>8} {'Mpairs/s':>10} {'instructions':>16} {'cycles':>14} {'IPC':>6} {'eff_GHz':>8} {'peak_KB':>9}")
for r in rows:
    print(f"{r[0]:<18} {r[1]:>8.4f} {r[2]:>10.2f} {r[3]:>16,d} {r[4]:>14,d} {r[5]:>6.2f} {r[6]:>8.2f} {r[8]//1024:>9d}")
PY
