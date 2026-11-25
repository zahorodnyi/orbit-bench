mod aos;
mod soa;

use std::env;
use std::fs::File;
use std::io::{self, BufWriter, Write};
use std::process;
use std::time::Instant;

pub const G: f32 = 1.0;
pub const SOFTENING_SQ: f32 = 0.05;
pub const DT: f32 = 0.005;
pub const ENERGY_EVERY: usize = 10;
pub const SEED: u64 = 0x5EED_CAFE_1337_BEEF;

const USAGE: &str =
    "Usage: orbit-bench [--mode aos|soa] [--stars N] [--steps S] [--render PATH.ppm]";

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Mode {
    Aos,
    Soa,
}

pub struct Config {
    pub mode: Mode,
    pub stars: usize,
    pub steps: usize,
    pub render_path: Option<String>,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            mode: Mode::Aos,
            stars: 5120,
            steps: 280,
            render_path: None,
        }
    }
}

pub struct SimOutput {
    pub initial_energy: f64,
    pub final_energy: f64,
    pub positions: Vec<(f32, f32, f32)>,
}

fn write_ppm(path: &str, positions: &[(f32, f32, f32)], size: usize) -> io::Result<()> {
    let extent = 28.0f32;
    let mut fb = vec![[4.0f32, 6.0, 14.0]; size * size];

    for &(x, y, temp) in positions {
        let u = (x + extent) / (2.0 * extent);
        let v = (y + extent) / (2.0 * extent);
        if !(0.0..1.0).contains(&u) || !(0.0..1.0).contains(&v) {
            continue;
        }
        let px = (u * size as f32) as isize;
        let py = ((1.0 - v) * size as f32) as isize;
        let t = ((temp - 3_200.0) / 10_800.0).clamp(0.0, 1.0);
        let rgb = [255.0 * (1.0 - 0.3 * t), 200.0 + 55.0 * t, 130.0 + 125.0 * t];

        for dy in -1..=1isize {
            for dx in -1..=1isize {
                let (nx, ny) = (px + dx, py + dy);
                if nx < 0 || ny < 0 || nx >= size as isize || ny >= size as isize {
                    continue;
                }
                let w = [0.95, 0.35, 0.15][(dx.abs() + dy.abs()) as usize];
                let pixel = &mut fb[ny as usize * size + nx as usize];
                for c in 0..3 {
                    pixel[c] += rgb[c] * w;
                }
            }
        }
    }

    let bytes: Vec<u8> = fb
        .iter()
        .flatten()
        .map(|&c| (255.0 * (1.0 - (-c / 210.0).exp())) as u8)
        .collect();
    let mut out = BufWriter::new(File::create(path)?);
    write!(out, "P6\n{size} {size}\n255\n")?;
    out.write_all(&bytes)
}

fn parse_args() -> Result<Config, String> {
    let mut args = env::args().skip(1);
    let mut cfg = Config::default();

    while let Some(arg) = args.next() {
        match arg.as_str() {
            "--mode" => {
                cfg.mode = match args.next().as_deref() {
                    Some("aos") => Mode::Aos,
                    Some("soa") => Mode::Soa,
                    _ => return Err("--mode expects aos or soa".into()),
                };
            }
            "--stars" => {
                cfg.stars = args
                    .next()
                    .and_then(|v| v.parse().ok())
                    .ok_or("missing or invalid --stars")?;
            }
            "--steps" => {
                cfg.steps = args
                    .next()
                    .and_then(|v| v.parse().ok())
                    .ok_or("missing or invalid --steps")?;
            }
            "--render" => {
                cfg.render_path = Some(args.next().ok_or("missing --render")?);
            }
            "-h" | "--help" => {
                println!("{USAGE}");
                process::exit(0);
            }
            other => return Err(format!("unknown argument: {other}")),
        }
    }

    if cfg.stars < 2 || cfg.steps < 1 {
        return Err("--stars must be >= 2 and --steps must be >= 1".into());
    }
    Ok(cfg)
}

fn main() {
    let cfg = parse_args().unwrap_or_else(|e| {
        eprintln!("error: {e}\n{USAGE}");
        process::exit(2);
    });

    let start = Instant::now();
    let res = match cfg.mode {
        Mode::Aos => aos::run(&cfg),
        Mode::Soa => soa::run(&cfg),
    };
    let elapsed = start.elapsed().as_secs_f64();

    let drift_pct = ((res.final_energy - res.initial_energy) / res.initial_energy).abs() * 100.0;
    let pairs = (cfg.stars as f64).powi(2) * cfg.steps as f64;

    println!(
        "profile={} mode={} sizeof_star={}B stars={} steps={}",
        if cfg!(debug_assertions) {
            "debug"
        } else {
            "release"
        },
        if cfg.mode == Mode::Aos { "aos" } else { "soa" },
        std::mem::size_of::<aos::Star>(),
        cfg.stars,
        cfg.steps,
    );
    println!(
        "elapsed={elapsed:.4}s throughput={:.2}Mpairs/s",
        pairs / 1.0e6 / elapsed
    );
    println!(
        "energy_init={:.6} energy_final={:.6} drift={drift_pct:.6}%",
        res.initial_energy, res.final_energy
    );

    if let Some(path) = &cfg.render_path {
        if let Err(e) = write_ppm(path, &res.positions, 1024) {
            eprintln!("render error: {e}");
            process::exit(1);
        }
        println!("rendered={path}");
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn aos_and_soa_match_energy() {
        for stars in [256, 133] {
            let mut cfg = Config {
                stars,
                steps: 20,
                ..Config::default()
            };
            let a = aos::run(&cfg);
            cfg.mode = Mode::Soa;
            let s = soa::run(&cfg);

            assert!((a.initial_energy - s.initial_energy).abs() < 1e-6);
            assert!(((a.final_energy - s.final_energy) / a.final_energy).abs() < 1e-5);
        }
    }
}
