#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ASM=$ROOT/results/asm
SRC=$ASM/godbolt_example.rs
TMP=/tmp/orbit_asm
mkdir -p "$ASM" "$TMP"

rustc --edition=2021 --crate-type=lib -C opt-level=0 -C force-frame-pointers=yes --emit=asm "$SRC" -o "$TMP/arm64_O0.s"
rustc --edition=2021 --crate-type=lib -C opt-level=3 -C force-frame-pointers=yes --emit=asm "$SRC" -o "$TMP/arm64_O3.s"
rustc --edition=2021 --crate-type=lib --target x86_64-unknown-linux-gnu -C opt-level=3 -C target-cpu=x86-64 -C llvm-args=-x86-asm-syntax=intel --emit=asm "$SRC" -o "$TMP/x86_O3_sse2.s"
rustc --edition=2021 --crate-type=lib --target x86_64-unknown-linux-gnu -C opt-level=3 -C target-cpu=x86-64-v3 -C llvm-args=-x86-asm-syntax=intel --emit=asm "$SRC" -o "$TMP/x86_O3_avx2.s"

python3 - "$TMP" "$ASM" <<'PY'
import pathlib, re, sys

tmp, asm = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])

def extract_fn(path, symbol):
    m = re.search(rf"(^_?{symbol}:.*?\.cfi_endproc)", path.read_text(), re.M | re.S)
    if not m:
        return ""
    lines = [
        line for line in m.group(1).splitlines()
        if not line.strip().startswith((".cfi_", ".loc", ".file", ".p2align"))
        and not re.match(r"^Ltmp\d+:$|^Lfunc_begin\d+:$", line.strip())
    ]
    return "\n".join(lines) + "\n"

specs = [
    ("arm64_O0_aos.s",           tmp / "arm64_O0.s",    "aos_compute_forces"),
    ("arm64_O3_aos.s",           tmp / "arm64_O3.s",    "aos_compute_forces"),
    ("arm64_O3_soa_neon.s",      tmp / "arm64_O3.s",    "soa_compute_forces"),
    ("x86_64_O3_aos_sse2.s",     tmp / "x86_O3_sse2.s", "aos_compute_forces"),
    ("x86_64_O3_soa_sse2.s",     tmp / "x86_O3_sse2.s", "soa_compute_forces"),
    ("x86_64_O3_soa_avx2_fma.s", tmp / "x86_O3_avx2.s", "soa_compute_forces"),
]

rows = [f"{'file':<28} {'lines':>6} {'vector_ops':>11} {'key_simd_instructions'}"]
for fname, src_path, sym in specs:
    code = extract_fn(src_path, sym)
    (asm / fname).write_text(code)
    pat = r"\b[a-z0-9]+\.4s\b" if "arm64" in fname else (
        r"\bv[a-z0-9]+ps\b|\bvbroadcastss\b|\bvmovups\b" if "avx2" in fname else r"\b[a-z0-9]+ps\b|\bmovups\b|\bmovaps\b"
    )
    vops = re.findall(pat, code)
    uniq = ", ".join(sorted(set(vops))) if vops else "(scalar only)"
    rows.append(f"{fname:<28} {len(code.splitlines()):>6} {len(vops):>11} {uniq}")

summary = "\n".join(rows) + "\n"
(asm / "summary.txt").write_text(summary)
print(summary)
PY
