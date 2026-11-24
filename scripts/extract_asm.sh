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

tmp = pathlib.Path(sys.argv[1])
asm = pathlib.Path(sys.argv[2])

def extract_fn(path, symbol):
    lines = path.read_text().splitlines()
    out = []
    inside = False
    for line in lines:
        s = line.strip()
        if re.match(rf"^_?{symbol}:", s):
            inside = True
        if inside:
            if s.startswith((".cfi_", ".loc", ".file", ".p2align", ".type", ".size", ".section")):
                continue
            if re.match(r"^Ltmp\d+:$|^Lfunc_begin\d+:$|^\.Lfunc_end", s):
                continue
            out.append(line)
            if s in ("ret", "retq") or s.startswith(".cfi_endproc") or s.startswith("Lfunc_end") or s.startswith(".Lfunc_end"):
                pass
        if inside and (s.startswith("Lfunc_end") or s.startswith(".Lfunc_end") or line.startswith(".cfi_endproc") or s == ".cfi_endproc"):
            break
    raw = path.read_text()
    m = re.search(rf"(^_?{symbol}:.*?\.cfi_endproc)", raw, re.M | re.S)
    if m:
        cleaned = []
        for line in m.group(1).splitlines():
            s = line.strip()
            if s.startswith((".cfi_", ".loc", ".file", ".p2align")):
                continue
            if re.match(r"^Ltmp\d+:$|^Lfunc_begin\d+:$", s):
                continue
            cleaned.append(line)
        return "\n".join(cleaned) + "\n"
    return "\n".join(out) + "\n"

specs = [
    ("arm64_O0_aos.s",          tmp / "arm64_O0.s",     "aos_compute_forces", "ARM64 -O0 (baseline_debug, AoS)"),
    ("arm64_O3_aos.s",          tmp / "arm64_O3.s",     "aos_compute_forces", "ARM64 -O3 (baseline_release, AoS)"),
    ("arm64_O3_soa_neon.s",     tmp / "arm64_O3.s",     "soa_compute_forces", "ARM64 -O3 (optimized_release, SoA + NEON 128-bit .4s)"),
    ("x86_64_O3_aos_sse2.s",    tmp / "x86_O3_sse2.s",  "aos_compute_forces", "x86-64 -O3 (baseline_release, AoS, SSE2)"),
    ("x86_64_O3_soa_sse2.s",    tmp / "x86_O3_sse2.s",  "soa_compute_forces", "x86-64 -O3 (SoA, SSE2 128-bit xmm)"),
    ("x86_64_O3_soa_avx2_fma.s",tmp / "x86_O3_avx2.s",  "soa_compute_forces", "x86-64 -O3 -C target-cpu=x86-64-v3 (SoA, AVX2+FMA 256-bit ymm)"),
]

summary_lines = [
    f"{'file':<28} {'lines':>6} {'vector_ops':>11} {'key_simd_instructions'}"
]

for fname, src_path, sym, desc in specs:
    code = extract_fn(src_path, sym)
    (asm / fname).write_text(code)
    n_lines = len(code.splitlines())
    if "arm64" in fname:
        vops = re.findall(r"\b[a-z0-9]+\.4s\b", code)
    elif "avx2" in fname:
        vops = re.findall(r"\bv[a-z0-9]+ps\b|\bvbroadcastss\b|\bvmovups\b", code)
    else:
        vops = re.findall(r"\b[a-z0-9]+ps\b|\bmovups\b|\bmovaps\b", code)
    uniq = ", ".join(sorted(set(vops))) if vops else "(scalar only)"
    summary_lines.append(f"{fname:<28} {n_lines:>6} {len(vops):>11} {uniq}")

summary = "\n".join(summary_lines) + "\n"
(asm / "summary.txt").write_text(summary)
print(summary)
PY
