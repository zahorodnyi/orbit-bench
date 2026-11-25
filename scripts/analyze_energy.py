#!/usr/bin/env python3
import csv
import pathlib
import re
import sys

PHASES = ["idle", "baseline_debug", "baseline_release", "optimized_release"]
COLORS = {
    "idle": "#64748b",
    "baseline_debug": "#dc2626",
    "baseline_release": "#d97706",
    "optimized_release": "#16a34a",
}
LABELS = {
    "idle": "idle (system baseline)",
    "baseline_debug": "baseline_debug (AoS, -O0)",
    "baseline_release": "baseline_release (AoS, -O3)",
    "optimized_release": "optimized_release (SoA + SIMD, -O3)",
}


def to_watts(val_str, unit_str):
    v = float(val_str)
    return v / 1000.0 if unit_str.lower() == "mw" else v


def parse_log(path):
    text = path.read_text(errors="replace")
    chunks = re.split(r"\*\*\* Sampled system activity", text)[1:]
    samples = []
    for chunk in chunks:
        m_dt = re.search(r"\(([0-9.]+)\s*ms elapsed\)", chunk)
        dt = float(m_dt.group(1)) / 1000.0 if m_dt else 0.1

        def find_power(pattern):
            m = re.search(pattern, chunk, re.I)
            return to_watts(m.group(1), m.group(2)) if m else None

        cpu_w = find_power(r"CPU Power:\s*([0-9.]+)\s*(mW|W)")
        gpu_w = find_power(r"GPU Power:\s*([0-9.]+)\s*(mW|W)") or 0.0
        ane_w = find_power(r"ANE Power:\s*([0-9.]+)\s*(mW|W)") or 0.0
        comb_w = find_power(r"Combined Power[^:]*:\s*([0-9.]+)\s*(mW|W)")
        pkg_w = find_power(r"Package Power:\s*([0-9.]+)\s*(mW|W)")

        if cpu_w is None and comb_w is not None:
            cpu_w = max(0.0, comb_w - gpu_w - ane_w)
        if cpu_w is None:
            cpu_w = pkg_w or 0.0
        sys_w = comb_w if comb_w is not None else (pkg_w if pkg_w is not None else cpu_w + gpu_w + ane_w)

        orbit_ms = 0.0
        orbit_ei = 0.0
        all_tasks_ei = 0.0
        for line in chunk.splitlines():
            s = line.strip()
            if s.startswith("orbit-bench"):
                parts = s.split()
                if len(parts) >= 3:
                    try:
                        orbit_ms += float(parts[2])
                    except ValueError:
                        pass
                    try:
                        orbit_ei += float(parts[-1])
                    except ValueError:
                        pass
            elif s.startswith("ALL_TASKS"):
                parts = s.split()
                if len(parts) >= 3:
                    try:
                        all_tasks_ei = float(parts[-1])
                    except ValueError:
                        pass

        samples.append({
            "dt": dt,
            "sys_w": sys_w,
            "cpu_w": cpu_w,
            "gpu_w": gpu_w,
            "orbit_ms": orbit_ms,
            "orbit_ei": orbit_ei,
            "all_tasks_ei": all_tasks_ei,
        })
    return samples


def filter_active(phase, samples):
    if phase == "idle" or not samples:
        return samples
    active = [s for s in samples if s["orbit_ms"] > 5.0]
    return active if active else samples


def draw_subplot(svg, x0, y0, pw, ph, max_t, max_w, timelines, phases, idle_sys_w, subtitle):
    def sx(t):
        return x0 + (min(t, max_t) / max_t) * pw

    def sy(val):
        return y0 + ph - (val / max_w) * ph

    svg.append(f'<text x="{x0}" y="{y0 - 8}" font-size="12" font-weight="700" fill="#1e293b">{subtitle}</text>')

    for i in range(5):
        val = max_w * i / 4.0
        y = sy(val)
        svg.append(f'<line x1="{x0}" y1="{y:.1f}" x2="{x0 + pw}" y2="{y:.1f}" stroke="#e2e8f0" stroke-width="1"/>')
        svg.append(f'<text x="{x0 - 8}" y="{y + 4:.1f}" text-anchor="end" font-size="11" fill="#475569">{val:.1f} W</text>')

    steps_t = 8
    for i in range(steps_t + 1):
        t = max_t * i / steps_t
        x = sx(t)
        svg.append(f'<line x1="{x:.1f}" y1="{y0}" x2="{x:.1f}" y2="{y0 + ph}" stroke="#f1f5f9" stroke-width="1"/>')
        svg.append(f'<text x="{x:.1f}" y="{y0 + ph + 16}" text-anchor="middle" font-size="11" fill="#475569">{t:.1f} s</text>')

    y_idle = sy(idle_sys_w)
    svg.append(f'<line x1="{x0}" y1="{y_idle:.1f}" x2="{x0 + pw}" y2="{y_idle:.1f}" stroke="#64748b" stroke-dasharray="5,4" stroke-width="1.4"/>')
    svg.append(f'<text x="{x0 + pw - 6}" y="{y_idle - 5:.1f}" text-anchor="end" font-size="11" fill="#475569">P_idle = {idle_sys_w:.2f} W</text>')

    for phase in phases:
        pts = [(t, p) for t, p in timelines.get(phase, []) if t <= max_t * 1.02]
        if not pts:
            continue
        color = COLORS[phase]
        coords = " ".join(f"{sx(t):.1f},{sy(p):.1f}" for t, p in pts)
        area = f"{sx(pts[0][0]):.1f},{sy(0):.1f} " + coords + f" {sx(pts[-1][0]):.1f},{sy(0):.1f}"
        svg.append(f'<polygon points="{area}" fill="{color}" fill-opacity="0.12"/>')
        svg.append(f'<polyline points="{coords}" fill="none" stroke="{color}" stroke-width="2.2"/>')

    svg.append(f'<rect x="{x0}" y="{y0}" width="{pw}" height="{ph}" fill="none" stroke="#94a3b8" stroke-width="1"/>')


def write_timeline_svg(out_path, timelines, idle_sys_w):
    w, h = 920, 620
    pad_l, pad_r = 70, 30
    pw = w - pad_l - pad_r

    max_all_t = max((pts[-1][0] for pts in timelines.values() if pts), default=10.0) * 1.03
    rel_t = max(
        (timelines[p][-1][0] for p in ["baseline_release", "optimized_release"] if timelines.get(p)),
        default=10.0,
    ) * 1.08
    max_w = max((max(p[1] for p in pts) for pts in timelines.values() if pts), default=10.0) * 1.18

    svg = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" font-family="system-ui, -apple-system, sans-serif">',
        f'<rect width="{w}" height="{h}" fill="#ffffff"/>',
        f'<text x="{w/2}" y="28" text-anchor="middle" font-size="16" font-weight="700" fill="#0f172a">System Power Over Time During orbit-bench on Apple M5 (powermetrics)</text>',
    ]

    lx = pad_l
    for idx, phase in enumerate(["baseline_debug", "baseline_release", "optimized_release"]):
        ox = lx + idx * 285
        svg.append(f'<rect x="{ox}" y="44" width="14" height="10" rx="2" fill="{COLORS[phase]}"/>')
        svg.append(f'<text x="{ox + 20}" y="53" font-size="12" fill="#1e293b">{LABELS[phase]}</text>')

    draw_subplot(
        svg, pad_l, 82, pw, 210, max_all_t, max_w, timelines,
        ["baseline_debug", "baseline_release", "optimized_release"],
        idle_sys_w, "Full Timeline (All 3 Variants — Shaded Area = Total Energy in Joules)"
    )
    draw_subplot(
        svg, pad_l, 345, pw, 215, rel_t, max_w, timelines,
        ["baseline_release", "optimized_release"],
        idle_sys_w, "Zoomed View: Release Variants (AoS -O3 vs SoA + SIMD -O3)"
    )

    svg.append(f'<text x="{w/2}" y="{h - 14}" text-anchor="middle" font-size="12" font-weight="600" fill="#334155">Execution Time t (seconds)</text>')
    svg.append(f'<text x="18" y="320" text-anchor="middle" font-size="12" font-weight="600" fill="#334155" transform="rotate(-90 18 320)">System Power P (Watts)</text>')
    svg.append("</svg>\n")
    out_path.write_text("\n".join(svg))


def write_comparison_svg(out_path, summary):
    w, h = 920, 420
    svg = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" font-family="system-ui, -apple-system, sans-serif">',
        f'<rect width="{w}" height="{h}" fill="#ffffff"/>',
        f'<text x="{w/2}" y="28" text-anchor="middle" font-size="16" font-weight="700" fill="#0f172a">Time, Average Power, and Total Energy Comparison on Apple M5</text>',
    ]

    panels = [
        ("Execution Time (s)", "duration_s", "s"),
        ("Process Power P_delta (W)", "prog_delta_w", "W"),
        ("Process Energy E_delta (J)", "prog_delta_j", "J"),
    ]
    variants = ["baseline_debug", "baseline_release", "optimized_release"]
    short = {
        "baseline_debug": "debug (-O0)",
        "baseline_release": "release (AoS)",
        "optimized_release": "optimized (SoA)",
    }

    panel_w = 260
    gap = 35
    start_x = 45
    top_y = 70
    chart_h = 285

    for p_idx, (title, key, unit) in enumerate(panels):
        px = start_x + p_idx * (panel_w + gap)
        vals = [summary[v][key] for v in variants if v in summary]
        max_v = max(vals + [0.1]) * 1.22

        svg.append(f'<text x="{px + panel_w/2}" y="{top_y - 14}" text-anchor="middle" font-size="13" font-weight="700" fill="#1e293b">{title}</text>')
        svg.append(f'<rect x="{px}" y="{top_y}" width="{panel_w}" height="{chart_h}" fill="#f8fafc" stroke="#cbd5e1" stroke-width="1"/>')

        bar_w = 54
        spacing = (panel_w - len(variants) * bar_w) / (len(variants) + 1)

        for b_idx, v in enumerate(variants):
            if v not in summary:
                continue
            val = summary[v][key]
            bh = (val / max_v) * (chart_h - 35)
            bx = px + spacing + b_idx * (bar_w + spacing)
            by = top_y + chart_h - bh
            svg.append(f'<rect x="{bx:.1f}" y="{by:.1f}" width="{bar_w}" height="{bh:.1f}" rx="4" fill="{COLORS[v]}"/>')
            svg.append(f'<text x="{bx + bar_w/2:.1f}" y="{by - 7:.1f}" text-anchor="middle" font-size="11" font-weight="700" fill="#0f172a">{val:.2f} {unit}</text>')
            svg.append(f'<text x="{bx + bar_w/2:.1f}" y="{top_y + chart_h + 18}" text-anchor="middle" font-size="11" fill="#334155">{short[v]}</text>')

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
            parsed[phase] = filter_active(phase, parse_log(p))

    if "idle" not in parsed or not parsed["idle"]:
        raise SystemExit("error: idle.log missing or contains no samples")

    idle_samples = parsed["idle"]
    idle_dt = sum(s["dt"] for s in idle_samples)
    idle_sys_w = sum(s["sys_w"] * s["dt"] for s in idle_samples) / idle_dt

    summary = {}
    timelines = {}
    timeline_rows = []

    for phase in PHASES:
        samples = parsed.get(phase, [])
        if not samples:
            continue
        t_acc = 0.0
        sys_j = 0.0
        cpu_j = 0.0
        delta_j = 0.0
        task_j = 0.0
        share_acc = 0.0
        pts = []

        for idx, s in enumerate(samples, 1):
            dt = s["dt"]
            t_acc += dt
            sys_w = s["sys_w"]
            cpu_w = s["cpu_w"]
            if phase == "idle":
                delta_w = 0.0
                task_w = 0.0
                share = 0.0
            else:
                delta_w = max(0.0, sys_w - idle_sys_w)
                denom = max(s["all_tasks_ei"], s["orbit_ei"], 1e-6)
                share = min(1.0, s["orbit_ei"] / denom) if s["orbit_ei"] > 0 else 1.0
                task_w = cpu_w * share

            sys_j += sys_w * dt
            cpu_j += cpu_w * dt
            delta_j += delta_w * dt
            task_j += task_w * dt
            share_acc += share * dt
            pts.append((t_acc, sys_w))
            timeline_rows.append([
                phase, idx, f"{t_acc:.3f}", f"{sys_w:.4f}", f"{cpu_w:.4f}",
                f"{delta_w:.4f}", f"{task_w:.4f}", f"{s['orbit_ms']:.1f}", f"{share*100:.1f}"
            ])

        timelines[phase] = pts
        summary[phase] = {
            "samples": len(samples),
            "duration_s": t_acc,
            "sys_avg_w": sys_j / t_acc,
            "sys_energy_j": sys_j,
            "cpu_avg_w": cpu_j / t_acc,
            "prog_delta_w": delta_j / t_acc,
            "prog_delta_j": delta_j,
            "prog_task_w": task_j / t_acc,
            "prog_task_j": task_j,
            "ei_share_pct": (share_acc / t_acc) * 100.0,
        }

    with (out_dir / "timeline.csv").open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["phase", "sample", "t_s", "sys_W", "cpu_W", "prog_delta_W", "prog_task_W", "orbit_cpu_ms_s", "ei_share_pct"])
        w.writerows(timeline_rows)

    with (out_dir / "summary.csv").open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["phase", "samples", "duration_s", "sys_avg_W", "sys_energy_J", "prog_delta_W", "prog_delta_J", "prog_task_W", "prog_task_J", "ei_share_pct"])
        for phase in PHASES:
            if phase not in summary:
                continue
            m = summary[phase]
            w.writerow([
                phase, m["samples"], f"{m['duration_s']:.3f}",
                f"{m['sys_avg_w']:.3f}", f"{m['sys_energy_j']:.3f}",
                f"{m['prog_delta_w']:.3f}", f"{m['prog_delta_j']:.3f}",
                f"{m['prog_task_w']:.3f}", f"{m['prog_task_j']:.3f}",
                f"{m['ei_share_pct']:.1f}"
            ])

    lines = [
        f"{'phase':<18} {'samples':>7} {'time_s':>8} {'sys_W':>8} {'sys_J':>9} {'prog_dW':>8} {'prog_dJ':>9} {'task_W':>8} {'task_J':>9} {'EI_%':>7}"
    ]
    for phase in PHASES:
        if phase not in summary:
            continue
        m = summary[phase]
        lines.append(
            f"{phase:<18} {m['samples']:>7d} {m['duration_s']:>8.2f} "
            f"{m['sys_avg_w']:>8.3f} {m['sys_energy_j']:>9.2f} "
            f"{m['prog_delta_w']:>8.3f} {m['prog_delta_j']:>9.2f} "
            f"{m['prog_task_w']:>8.3f} {m['prog_task_j']:>9.2f} "
            f"{m['ei_share_pct']:>6.1f}%"
        )

    txt = "\n".join(lines) + "\n"
    (out_dir / "summary.txt").write_text(txt)
    print(txt)

    write_timeline_svg(out_dir / "power_timeline.svg", timelines, idle_sys_w)
    write_comparison_svg(out_dir / "energy_comparison.svg", summary)


if __name__ == "__main__":
    main()
