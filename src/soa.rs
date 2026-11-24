use crate::aos::{init_galaxy, Star};
use crate::{Config, SimOutput, DT, G, SOFTENING_SQ};

const LANES: usize = 8;

#[inline(always)]
fn fma(a: f32, b: f32, c: f32) -> f32 {
    if cfg!(any(target_arch = "aarch64", target_feature = "fma")) {
        a.mul_add(b, c)
    } else {
        a * b + c
    }
}

pub struct GalaxySoa {
    pub x: Vec<f32>,
    pub y: Vec<f32>,
    pub z: Vec<f32>,
    pub mass: Vec<f32>,
    pub vx: Vec<f32>,
    pub vy: Vec<f32>,
    pub vz: Vec<f32>,
    pub ax: Vec<f32>,
    pub ay: Vec<f32>,
    pub az: Vec<f32>,
    pub temp: Vec<f32>,
}

impl GalaxySoa {
    pub fn from_aos(stars: &[Star]) -> Self {
        let n = stars.len();
        Self {
            x: stars.iter().map(|s| s.x).collect(),
            y: stars.iter().map(|s| s.y).collect(),
            z: stars.iter().map(|s| s.z).collect(),
            mass: stars.iter().map(|s| s.mass).collect(),
            vx: stars.iter().map(|s| s.vx).collect(),
            vy: stars.iter().map(|s| s.vy).collect(),
            vz: stars.iter().map(|s| s.vz).collect(),
            ax: vec![0.0; n],
            ay: vec![0.0; n],
            az: vec![0.0; n],
            temp: stars.iter().map(|s| s.temp).collect(),
        }
    }
}

#[inline(never)]
pub fn compute_forces(soa: &mut GalaxySoa) {
    let n = soa.x.len();
    let (x, y, z, mass) = (&soa.x[..n], &soa.y[..n], &soa.z[..n], &soa.mass[..n]);
    let (ax_out, ay_out, az_out) = (&mut soa.ax[..n], &mut soa.ay[..n], &mut soa.az[..n]);
    let tail_start = n - n % LANES;

    for base in (0..tail_start).step_by(LANES) {
        let xi: [f32; LANES] = x[base..base + LANES].try_into().unwrap();
        let yi: [f32; LANES] = y[base..base + LANES].try_into().unwrap();
        let zi: [f32; LANES] = z[base..base + LANES].try_into().unwrap();
        let mut ax_acc = [0.0f32; LANES];
        let mut ay_acc = [0.0f32; LANES];
        let mut az_acc = [0.0f32; LANES];

        for j in 0..n {
            let gmj = G * mass[j];
            for k in 0..LANES {
                let dx = x[j] - xi[k];
                let dy = y[j] - yi[k];
                let dz = z[j] - zi[k];
                let dist_sq = fma(dz, dz, fma(dy, dy, fma(dx, dx, SOFTENING_SQ)));
                let inv_dist = 1.0 / dist_sq.sqrt();
                let s = gmj * (inv_dist * inv_dist * inv_dist);
                ax_acc[k] = fma(dx, s, ax_acc[k]);
                ay_acc[k] = fma(dy, s, ay_acc[k]);
                az_acc[k] = fma(dz, s, az_acc[k]);
            }
        }

        ax_out[base..base + LANES].copy_from_slice(&ax_acc);
        ay_out[base..base + LANES].copy_from_slice(&ay_acc);
        az_out[base..base + LANES].copy_from_slice(&az_acc);
    }

    for i in tail_start..n {
        let (mut ax, mut ay, mut az) = (0.0f32, 0.0f32, 0.0f32);
        for j in 0..n {
            let dx = x[j] - x[i];
            let dy = y[j] - y[i];
            let dz = z[j] - z[i];
            let dist_sq = fma(dz, dz, fma(dy, dy, fma(dx, dx, SOFTENING_SQ)));
            let inv_dist = 1.0 / dist_sq.sqrt();
            let s = (G * mass[j]) * (inv_dist * inv_dist * inv_dist);
            ax = fma(dx, s, ax);
            ay = fma(dy, s, ay);
            az = fma(dz, s, az);
        }
        ax_out[i] = ax;
        ay_out[i] = ay;
        az_out[i] = az;
    }
}

#[inline(never)]
pub fn integrate_motion(soa: &mut GalaxySoa, dt: f32) {
    for i in 0..soa.x.len() {
        soa.vx[i] += soa.ax[i] * dt;
        soa.vy[i] += soa.ay[i] * dt;
        soa.vz[i] += soa.az[i] * dt;
        soa.x[i] += soa.vx[i] * dt;
        soa.y[i] += soa.vy[i] * dt;
        soa.z[i] += soa.vz[i] * dt;
    }
}

#[inline(never)]
pub fn compute_total_energy(soa: &GalaxySoa) -> f64 {
    let n = soa.x.len();
    let mut kinetic = 0.0f64;
    for i in 0..n {
        let (vx, vy, vz) = (soa.vx[i] as f64, soa.vy[i] as f64, soa.vz[i] as f64);
        kinetic += 0.5 * (soa.mass[i] as f64) * (vx * vx + vy * vy + vz * vz);
    }

    let (g, eps2) = (G as f64, SOFTENING_SQ as f64);
    let (x, y, z, mass) = (&soa.x[..n], &soa.y[..n], &soa.z[..n], &soa.mass[..n]);
    let mut potential = 0.0f64;
    for i in 0..n {
        let (xi, yi, zi) = (x[i] as f64, y[i] as f64, z[i] as f64);
        for j in (i + 1)..n {
            let dx = x[j] as f64 - xi;
            let dy = y[j] as f64 - yi;
            let dz = z[j] as f64 - zi;
            let dist = (dx * dx + dy * dy + dz * dz + eps2).sqrt();
            potential -= g * (mass[i] as f64) * (mass[j] as f64) / dist;
        }
    }
    kinetic + potential
}

#[inline(never)]
pub fn run(cfg: &Config) -> SimOutput {
    let mut soa = GalaxySoa::from_aos(&init_galaxy(cfg.stars));
    let initial_energy = compute_total_energy(&soa);
    let mut final_energy = initial_energy;

    for step in 1..=cfg.steps {
        compute_forces(&mut soa);
        integrate_motion(&mut soa, DT);
        if step % cfg.energy_every == 0 || step == cfg.steps {
            final_energy = compute_total_energy(&soa);
        }
    }

    let positions = (0..soa.x.len())
        .map(|i| (soa.x[i], soa.y[i], soa.temp[i]))
        .collect();
    SimOutput {
        initial_energy,
        final_energy,
        positions,
    }
}
