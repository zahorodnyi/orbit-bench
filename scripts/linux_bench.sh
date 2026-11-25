#!/usr/bin/env bash
set -euo pipefail

STARS=${STARS:-5120}
STEPS=${STEPS:-280}
FREQ=${FREQ:-999}

ROOT=$(cd "$(dirname "$0")/.." && pwd)
RES=${RES:-$ROOT/results}
FG=${FLAMEGRAPH_DIR:-/opt/FlameGraph}
TMP=/tmp/orbit-bench
export CARGO_TARGET_DIR=$TMP/target

VARIANTS=(baseline_debug baseline_release optimized_release)

variant_cmd() {
    case "$1" in
        baseline_debug)    echo "$CARGO_TARGET_DIR/debug/orbit-bench --mode aos" ;;
        baseline_release)  echo "$CARGO_TARGET_DIR/release/orbit-bench --mode aos" ;;
        optimized_release) echo "$CARGO_TARGET_DIR/release/orbit-bench --mode soa" ;;
    esac
}

mkdir -p "$TMP" "$RES"/{time,perf_stat,perf_report,flamegraphs}

echo "== Build (debug + release) =="
(cd "$ROOT" && cargo build --quiet && cargo build --release --quiet)

{
    echo "kernel: $(uname -srm)"
    echo "perf:   $(perf --version)"
    echo "workload: --stars $STARS --steps $STEPS, perf -F $FREQ"
} | tee "$RES/linux_env.txt"

for v in "${VARIANTS[@]}"; do
    cmd="$(variant_cmd "$v") --stars $STARS --steps $STEPS"
    echo
    echo "== $v: $cmd =="

    echo "-- /usr/bin/time -v"
    /usr/bin/time -v -o "$TMP/$v.time" $cmd > "$TMP/$v.out"
    { echo "$cmd"; cat "$TMP/$v.out"; echo; cat "$TMP/$v.time"; } > "$RES/time/$v.txt"

    echo "-- perf stat -d"
    perf stat -d -o "$TMP/$v.stat" $cmd > /dev/null
    { echo "perf stat -d $cmd"; cat "$TMP/$v.stat"; } > "$RES/perf_stat/$v.txt"

    echo "-- perf record + report"
    perf record -e cpu-clock -F "$FREQ" --call-graph fp -o "$TMP/$v.data" $cmd > /dev/null 2> "$TMP/$v.record.log"
    perf report -i "$TMP/$v.data" --stdio --no-children --sort symbol -n --percent-limit 0.5 \
        > "$RES/perf_report/$v.txt" 2> /dev/null

    echo "-- FlameGraph"
    perf script -i "$TMP/$v.data" -F comm,pid,tid,time,event,ip,sym,dso 2> /dev/null \
        | "$FG/stackcollapse-perf.pl" \
        | awk '{c=$NF; sub(/ [0-9]+$/,""); n=split($0,f,";"); s=f[1]; for(i=2;i<=n;i++) if(f[i]!=f[i-1]) s=s";"f[i]; print s, c}' > "$RES/flamegraphs/$v.folded"
    "$FG/flamegraph.pl" --title "orbit-bench: $v" --subtitle "perf cpu-clock ${FREQ}Hz, ${STARS} stars x ${STEPS} steps" \
        "$RES/flamegraphs/$v.folded" > "$RES/flamegraphs/$v.svg"
done

echo
echo "== Differential FlameGraph: baseline_release -> optimized_release =="
"$FG/difffolded.pl" -n \
    <(sed 's/::aos::/::/g' "$RES/flamegraphs/baseline_release.folded") \
    <(sed 's/::soa::/::/g' "$RES/flamegraphs/optimized_release.folded") \
    | "$FG/flamegraph.pl" --title "diff: baseline_release -> optimized_release" \
        --subtitle "red = grew, blue = shrank" > "$RES/flamegraphs/diff_baseline_to_optimized.svg"

echo "Done. Results in $RES"
