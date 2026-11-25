#!/usr/bin/env python3
import csv
import pathlib
import re
import sys

PHASES = ["idle", "baseline_debug", "baseline_release", "optimized_release"]
COLORS = {"idle": "#64748b", "baseline_debug": "#dc2626", "baseline_release": "#d97706", "optimized_release": "#16a34a"}
LABELS = {
    "idle": "idle (system baseline)",
    "baseline_debug": "baseline_debug (AoS, -O0)",
    "baseline_release": "baseline_release (AoS, -O3)",
    "optimized_release": "optimized_release (SoA + SIMD, -O3)",
}


def find_watts(chunk, pattern):
    m = re.search(pattern, chunk, re.I)
    if not m:
        return None
    val = float(m.group(1))
    return val / 1000.0 if m.group(2).lower() == "mw" else val


def parse_log(path):
    samples = []
    for chunk in re.split(r"\*\*\* Sampled system activity", path.read_text(errors="replace"))[1:]:
        m_dt = re.search(r"\(([0-9.]+)\s*ms elapsed\)", chunk)
        dt = float(m_dt.group(1)) / 1000.0 if m_dt else 0.1
        cpu_w = find_watts(chunk, r"CPU Power:\s*([0-9.]+)\s*(mW|W)") or 0.0
        gpu_w = find_watts(chunk, r"GPU Power:\s*([0-9.]+)\s*(mW|W)") or 0.0
        ane_w = find_watts(chunk, r"ANE Power:\s*([0-9.]+)\s*(mW|W)") or 0.0
        comb_w = find_watts(chunk, r"Combined Power[^:]*:\s*([0-9.]+)\s*(mW|W)")
        sys_w = comb_w if comb_w is not None else (cpu_w + gpu_w + ane_w)

        orbit_ms, orbit_ei, all_ei = 0.0, 0.0, 0.0
        for line in chunk.splitlines():
            parts = line.split()
            if len(parts) >= 3 and parts[0] == "orbit-bench":
                orbit_ms += float(parts[2])
                orbit_ei += float(parts[-1])
            elif len(parts) >= 3 and parts[0] == "ALL_TASKS":
                all_ei = float(parts[-1])
        samples.append({"dt": dt, "sys_w": sys_w, "cpu_w": cpu_w, "orbit_ms": orbit_ms, "orbit_ei": orbit_ei, "all_ei": all_ei})
    return samples


def draw_subplot(svg, x0, y0, pw, ph, max_t, max_w, timelines, phases, idle_w, subtitle):
    sx = lambda t: x0 + (min(t, max_t) / max_t) * pw
    sy = lambda v: y0 + ph - (v / max_w) * ph
    svg.append(f'<text x="{x0}" y="{y0 - 8}" font-size="12" font-weight="700" fill="#1e293b">{subtitle}</text>')
    for i in range(5):
        val = max_w * i / 4.0
        y = sy(val)
        svg.append(f'<line x1="{x0}" y1="{y:.1f}" x2="{x0 + pw}" y2="{y:.1f}" stroke="#e2e8f0"/>')
        svg.append(f'<text x="{x0 - 8}" y="{y + 4:.1f}" text-anchor="end" font-size="11" fill="#475569">{val:.1f} W</text>')
    for i in range(9):
        t = max_t * i / 8.0
        x = sx(t)
        svg.append(f'<line x1="{x:.1f}" y1="{y0}" x2="{x:.1f}" y2="{y0 + ph}" stroke="#f1f5f9"/>')
        svg.append(f'<text x="{x:.1f}" y="{y0 + ph + 16}" text-anchor="middle" font-size="11" fill="#475569">{t:.1f} s</text>')
    yi = sy(idle_w)
    svg.append(f'<line x1="{x0}" y1="{yi:.1f}" x2="{x0 + pw}" y2="{yi:.1f}" stroke="#64748b" stroke-dasharray="5,4" stroke-width="1.4"/>')
    svg.append(f'<text x="{x0 + pw - 6}" y="{yi - 5:.1f}" text-anchor="end" font-size="11" fill="#475569">P_idle = {idle_w:.2f} W</text>')
    for phase in phases:
        pts = [(t, p) for t, p in timelines.get(phase, []) if t <= max_t * 1.02]
        if pts:
            coords = " ".join(f"{sx(t):.1f},{sy(p):.1f}" for t, p in pts)
            area = f"{sx(pts[0][0]):.1f},{sy(0):.1f} {coords} {sx(pts[-1][0]):.1f},{sy(0):.1f}"
            svg.append(f'<polygon points="{area}" fill="{COLORS[phase]}" fill-opacity="0.12"/>')
            svg.append(f'<polyline points="{coords}" fill="none" stroke="{COLORS[phase]}" stroke-width="2.2"/>')
    svg.append(f'<rect x="{x0}" y="{y0}" width="{pw}" height="{ph}" fill="none" stroke="#94a3b8"/>')


def write_timeline_svg(out_path, timelines, idle_w):
    w, h, pad_l, pw = 920, 620, 70, 820
    max_all_t = max((pts[-1][0] for pts in timelines.values() if pts), default=10.0) * 1.03
    rel_t = max((timelines[p][-1][0] for p in ["baseline_release", "optimized_release"] if timelines.get(p)), default=10.0) * 1.08
    max_w = max((max(p[1] for p in pts) for pts in timelines.values() if pts), default=10.0) * 1.18
    svg = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" font-family="system-ui, sans-serif">',
        f'<rect width="{w}" height="{h}" fill="#ffffff"/>',
        f'<text x="{w/2}" y="28" text-anchor="middle" font-size="16" font-weight="700" fill="#0f172a">System Power Over Time During orbit-bench on Apple M5 (powermetrics)</text>',
    ]
    for idx, phase in enumerate(["baseline_debug", "baseline_release", "optimized_release"]):
        ox = pad_l + idx * 285
        svg.append(f'<rect x="{ox}" y="44" width="14" height="10" rx="2" fill="{COLORS[phase]}"/>')
        svg.append(f'<text x="{ox + 20}" y="53" font-size="12" fill="#1e293b">{LABELS[phase]}</text>')
    draw_subplot(svg, pad_l, 82, pw, 210, max_all_t, max_w, timelines, ["baseline_debug", "baseline_release", "optimized_release"], idle_w, "Full Timeline (All 3 Variants — Shaded Area = Total Energy in Joules)")
    draw_subplot(svg, pad_l, 345, pw, 215, rel_t, max_w, timelines, ["baseline_release", "optimized_release"], idle_w, "Zoomed View: Release Variants (AoS -O3 vs SoA + SIMD -O3)")
    svg.append(f'<text x="{w/2}" y="{h - 14}" text-anchor="middle" font-size="12" font-weight="600" fill="#334155">Execution Time t (seconds)</text>')
    svg.append(f'<text x="18" y="320" text-anchor="middle" font-size="12" font-weight="600" fill="#334155" transform="rotate(-90 18 320)">System Power P (Watts)</text></svg>\n')
    out_path.write_text("\n".join(svg))


def write_comparison_svg(out_path, summary):
    w, h, top_y, chart_h, panel_w, gap = 920, 420, 70, 285, 260, 35
    variants = ["baseline_debug", "baseline_release", "optimized_release"]
    short = {"baseline_debug": "debug (-O0)", "baseline_release": "release (AoS)", "optimized_release": "optimized (SoA)"}
    panels = [("Execution Time (s)", "duration_s", "s"), ("Process Power P_delta (W)", "prog_delta_w", "W"), ("Process Energy E_delta (J)", "prog_delta_j", "J")]
    svg = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" font-family="system-ui, sans-serif">',
        f'<rect width="{w}" height="{h}" fill="#ffffff"/>',
        f'<text x="{w/2}" y="28" text-anchor="middle" font-size="16" font-weight="700" fill="#0f172a">Time, Average Power, and Total Energy Comparison on Apple M5</text>',
    ]
    for p_idx, (title, key, unit) in enumerate(panels):
        px = 45 + p_idx * (panel_w + gap)
        max_v = max([summary[v][key] for v in variants if v in summary] + [0.1]) * 1.22
        svg.append(f'<text x="{px + panel_w/2}" y="{top_y - 14}" text-anchor="middle" font-size="13" font-weight="700" fill="#1e293b">{title}</text>')
        svg.append(f'<rect x="{px}" y="{top_y}" width="{panel_w}" height="{chart_h}" fill="#f8fafc" stroke="#cbd5e1"/>')
        for b_idx, v in enumerate(variants):
            val = summary[v][key]
            bh = (val / max_v) * (chart_h - 35)
            bx, by = px + 24.5 + b_idx * 78.5, top_y + chart_h - bh
            svg.append(f'<rect x="{bx:.1f}" y="{by:.1f}" width="54" height="{bh:.1f}" rx="4" fill="{COLORS[v]}"/>')
            svg.append(f'<text x="{bx + 27:.1f}" y="{by - 7:.1f}" text-anchor="middle" font-size="11" font-weight="700" fill="#0f172a">{val:.2f} {unit}</text>')
            svg.append(f'<text x="{bx + 27:.1f}" y="{top_y + chart_h + 18}" text-anchor="middle" font-size="11" fill="#334155">{short[v]}</text>')
    svg.append("</svg>\n")
    out_path.write_text("\n".join(svg))


def main():
    raw_dir = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path("/tmp/orbit_energy_raw")
    out_dir = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else pathlib.Path("results/energy")
    out_dir.mkdir(parents=True, exist_ok=True)

    parsed = {}
    for phase in PHASES:
        p = raw_dir / f"{phase}.log"
        if p.exists():
            s = parse_log(p)
            active = [x for x in s if x["orbit_ms"] > 5.0] if phase != "idle" else s
            parsed[phase] = active or s

    if "idle" not in parsed:
        sys.exit(f"error: raw powermetrics logs not found in {raw_dir} (run ./scripts/measure_energy.sh)")
    idle_s = parsed["idle"]
    idle_w = sum(s["sys_w"] * s["dt"] for s in idle_s) / sum(s["dt"] for s in idle_s)

    summary, timelines, timeline_rows = {}, {}, []
    for phase in PHASES:
        samples = parsed.get(phase, [])
        if not samples:
            continue
        t_acc = sys_j = cpu_j = delta_j = task_j = share_acc = 0.0
        pts = []
        for idx, s in enumerate(samples, 1):
            dt, sys_w, cpu_w = s["dt"], s["sys_w"], s["cpu_w"]
            t_acc += dt
            delta_w = 0.0 if phase == "idle" else max(0.0, sys_w - idle_w)
            share = 0.0 if phase == "idle" else (min(1.0, s["orbit_ei"] / max(s["all_ei"], s["orbit_ei"], 1e-6)) if s["orbit_ei"] > 0 else 1.0)
            task_w = cpu_w * share
            sys_j += sys_w * dt
            cpu_j += cpu_w * dt
            delta_j += delta_w * dt
            task_j += task_w * dt
            share_acc += share * dt
            pts.append((t_acc, sys_w))
            timeline_rows.append([phase, idx, f"{t_acc:.3f}", f"{sys_w:.4f}", f"{cpu_w:.4f}", f"{delta_w:.4f}", f"{task_w:.4f}", f"{s['orbit_ms']:.1f}", f"{share*100:.1f}"])
        timelines[phase] = pts
        summary[phase] = {
            "samples": len(samples), "duration_s": t_acc, "sys_avg_w": sys_j / t_acc, "sys_energy_j": sys_j,
            "prog_delta_w": delta_j / t_acc, "prog_delta_j": delta_j, "prog_task_w": task_j / t_acc,
            "prog_task_j": task_j, "ei_share_pct": (share_acc / t_acc) * 100.0,
        }

    with (out_dir / "timeline.csv").open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["phase", "sample", "t_s", "sys_W", "cpu_W", "prog_delta_W", "prog_task_W", "orbit_cpu_ms_s", "ei_share_pct"])
        w.writerows(timeline_rows)

    with (out_dir / "summary.csv").open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["phase", "samples", "duration_s", "sys_avg_W", "sys_energy_J", "prog_delta_W", "prog_delta_J", "prog_task_W", "prog_task_J", "ei_share_pct"])
        for phase, m in summary.items():
            w.writerow([phase, m["samples"], f"{m['duration_s']:.3f}", f"{m['sys_avg_w']:.3f}", f"{m['sys_energy_j']:.3f}", f"{m['prog_delta_w']:.3f}", f"{m['prog_delta_j']:.3f}", f"{m['prog_task_w']:.3f}", f"{m['prog_task_j']:.3f}", f"{m['ei_share_pct']:.1f}"])

    lines = [f"{'phase':<18} {'samples':>7} {'time_s':>8} {'sys_W':>8} {'sys_J':>9} {'prog_dW':>8} {'prog_dJ':>9} {'task_W':>8} {'task_J':>9} {'EI_%':>7}"]
    for phase, m in summary.items():
        lines.append(f"{phase:<18} {m['samples']:>7d} {m['duration_s']:>8.2f} {m['sys_avg_w']:>8.3f} {m['sys_energy_j']:>9.2f} {m['prog_delta_w']:>8.3f} {m['prog_delta_j']:>9.2f} {m['prog_task_w']:>8.3f} {m['prog_task_j']:>9.2f} {m['ei_share_pct']:>6.1f}%")
    txt = "\n".join(lines) + "\n"
    (out_dir / "summary.txt").write_text(txt)
    print(txt)
    write_timeline_svg(out_dir / "power_timeline.svg", timelines, idle_w)
    write_comparison_svg(out_dir / "energy_comparison.svg", summary)


if __name__ == "__main__":
    main()
