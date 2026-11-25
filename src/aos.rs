use crate::{Config, SimOutput, DT, ENERGY_EVERY, G, SEED, SOFTENING_SQ};

#[repr(C)]
#[derive(Clone, Copy, Default)]
pub struct Star {
    pub x: f32,
    pub y: f32,
    pub z: f32,
    pub mass: f32,
    pub vx: f32,
    pub vy: f32,
    pub vz: f32,
    pub ax: f32,
    pub ay: f32,
    pub az: f32,
    pub temp: f32,
    pub _pad: [f32; 5],
}

fn next_f32(state: &mut u64) -> f32 {
    let mut x = *state;
    x ^= x << 13;
    x ^= x >> 7;
    x ^= x << 17;
    *state = x;
    ((x >> 40) as f32) / ((1u64 << 24) as f32)
}

#[inline(never)]
pub fn init_galaxy(count: usize) -> Vec<Star> {
    let mut rng = SEED;
    let core_mass = 250.0f32;
    let mut stars = vec![Star {
        mass: core_mass,
        temp: 25_000.0,
        ..Star::default()
    }];

    for i in 1..count {
        let arm = (i % 3) as f32;
        let r = 1.5 + 22.5 * next_f32(&mut rng).powf(0.85);
        let theta =
            arm * (std::f32::consts::TAU / 3.0) + 0.28 * r + (next_f32(&mut rng) - 0.5) * 0.55;
        let enclosed = core_mass + 0.02 * (count as f32) * (r / 24.0);
        let v = (G * enclosed / (r * r + SOFTENING_SQ).sqrt()).sqrt()
            * (1.0 + (next_f32(&mut rng) - 0.5) * 0.06);

        stars.push(Star {
            x: r * theta.cos(),
            y: r * theta.sin(),
            z: (next_f32(&mut rng) - 0.5) * (1.2 / (1.0 + 0.08 * r)),
            mass: 0.02 + 0.23 * next_f32(&mut rng),
            vx: -theta.sin() * v,
            vy: theta.cos() * v,
            vz: (next_f32(&mut rng) - 0.5) * 0.08 * v,
            temp: 3_200.0 + 10_800.0 * next_f32(&mut rng),
            ..Star::default()
        });
    }
    stars
}

#[inline]
fn pair_gravity(target: &Star, source: &Star) -> (f32, f32, f32) {
    let dx = source.x - target.x;
    let dy = source.y - target.y;
    let dz = source.z - target.z;
    let dist_sq = dx * dx + dy * dy + dz * dz + SOFTENING_SQ;
    let inv_dist = 1.0 / dist_sq.sqrt();
    let s = G * source.mass * inv_dist * inv_dist * inv_dist;
    (dx * s, dy * s, dz * s)
}

#[inline(never)]
#[allow(clippy::needless_range_loop)]
pub fn compute_forces(stars: &mut [Star]) {
    let n = stars.len();
    for i in 0..n {
        let target = stars[i];
        let (mut ax, mut ay, mut az) = (0.0f32, 0.0f32, 0.0f32);
        for j in 0..n {
            if i == j {
                continue;
            }
            let (fx, fy, fz) = pair_gravity(&target, &stars[j]);
            ax += fx;
            ay += fy;
            az += fz;
        }
        stars[i].ax = ax;
        stars[i].ay = ay;
        stars[i].az = az;
    }
}

#[inline(never)]
pub fn integrate_motion(stars: &mut [Star], dt: f32) {
    for s in stars.iter_mut() {
        s.vx += s.ax * dt;
        s.vy += s.ay * dt;
        s.vz += s.az * dt;
        s.x += s.vx * dt;
        s.y += s.vy * dt;
        s.z += s.vz * dt;
    }
}

#[inline(never)]
#[allow(clippy::needless_range_loop)]
pub fn compute_total_energy(stars: &[Star]) -> f64 {
    let n = stars.len();
    let mut kinetic = 0.0f64;
    for s in stars {
        let (vx, vy, vz) = (s.vx as f64, s.vy as f64, s.vz as f64);
        kinetic += 0.5 * (s.mass as f64) * (vx * vx + vy * vy + vz * vz);
    }

    let (g, eps2) = (G as f64, SOFTENING_SQ as f64);
    let mut potential = 0.0f64;
    for i in 0..n {
        let (xi, yi, zi) = (stars[i].x as f64, stars[i].y as f64, stars[i].z as f64);
        for j in (i + 1)..n {
            let dx = stars[j].x as f64 - xi;
            let dy = stars[j].y as f64 - yi;
            let dz = stars[j].z as f64 - zi;
            let dist = (dx * dx + dy * dy + dz * dz + eps2).sqrt();
            potential -= g * (stars[i].mass as f64) * (stars[j].mass as f64) / dist;
        }
    }
    kinetic + potential
}

#[inline(never)]
pub fn run(cfg: &Config) -> SimOutput {
    let mut stars = init_galaxy(cfg.stars);
    let initial_energy = compute_total_energy(&stars);
    let mut final_energy = initial_energy;

    for step in 1..=cfg.steps {
        compute_forces(&mut stars);
        integrate_motion(&mut stars, DT);
        if step % ENERGY_EVERY == 0 || step == cfg.steps {
            final_energy = compute_total_energy(&stars);
        }
    }

    let positions = stars.iter().map(|s| (s.x, s.y, s.temp)).collect();
    SimOutput {
        initial_energy,
        final_energy,
        positions,
    }
}
