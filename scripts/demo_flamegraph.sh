#!/usr/bin/env bash
set -euo pipefail

VARIANT=${1:-baseline_release}
STARS=${STARS:-4096}
STEPS=${STEPS:-120}
FG=${FLAMEGRAPH_DIR:-/opt/FlameGraph}

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=$ROOT/demo_out
export CARGO_TARGET_DIR=/tmp/orbit-bench/target

case "$VARIANT" in
    baseline_release)  MODE=aos ;;
    optimized_release) MODE=soa ;;
    *) echo "variant must be baseline_release or optimized_release" >&2; exit 2 ;;
esac

mkdir -p "$OUT"
cd "$ROOT"
cargo build --release --quiet
BIN=$CARGO_TARGET_DIR/release/orbit-bench

run() { echo; echo "\$ $*"; "$@"; }

echo "=== FlameGraph demo: $VARIANT ($STARS stars x $STEPS steps) ==="

echo; echo "[1/4] perf record"
run perf record -e cpu-clock -F 999 --call-graph fp -o "$OUT/perf.data" "$BIN" --mode "$MODE" --stars "$STARS" --steps "$STEPS"

echo; echo "[2/4] perf script"
perf script -i "$OUT/perf.data" -F comm,pid,tid,time,event,ip,sym,dso 2> /dev/null > "$OUT/perf.script"
echo "\$ perf script -i perf.data > perf.script    ($(grep -c '^[^[:space:]]' "$OUT/perf.script") samples)"
head -n 12 "$OUT/perf.script"

echo; echo "[3/4] stackcollapse-perf.pl"
"$FG/stackcollapse-perf.pl" "$OUT/perf.script" \
    | awk '{c=$NF; sub(/ [0-9]+$/,""); n=split($0,f,";"); s=f[1]; for(i=2;i<=n;i++) if(f[i]!=f[i-1]) s=s";"f[i]; print s, c}' > "$OUT/perf.folded"
echo "\$ stackcollapse-perf.pl perf.script > perf.folded"
sort -k2 -n -r -t' ' "$OUT/perf.folded" | head -n 5

echo; echo "[4/4] flamegraph.pl"
"$FG/flamegraph.pl" --title "orbit-bench: $VARIANT (demo)" "$OUT/perf.folded" > "$OUT/flame_$VARIANT.svg"
echo "\$ flamegraph.pl perf.folded > flame_$VARIANT.svg"

echo; echo "Done: demo_out/flame_$VARIANT.svg"
