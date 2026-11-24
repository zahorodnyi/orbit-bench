#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

IMAGE=orbit-bench-linux
ACTION=${1:-bench}

case "$ACTION" in
    bench) CMD="scripts/linux_bench.sh" ;;
    demo)  CMD="scripts/demo_flamegraph.sh ${2:-baseline_release}" ;;
    shell) CMD="bash" ;;
    *)     echo "usage: $0 [bench|demo [variant]|shell]" >&2; exit 2 ;;
esac

TTY=""
[ -t 0 ] && TTY="-it"

docker build -t "$IMAGE" .

docker run --rm $TTY --privileged \
    -e STARS -e STEPS -e FREQ \
    -v "$PWD":/work -w /work \
    "$IMAGE" $CMD
