use std::convert::TryInto;

pub const G: f32 = 1.0;
pub const SOFTENING_SQ: f32 = 0.05;
const LANES: usize = 8;

#[inline(always)]
fn fma(a: f32, b: f32, c: f32) -> f32 {
    if cfg!(any(target_arch = "aarch64", target_feature = "fma")) {
        a.mul_add(b, c)
    } else {
        a * b + c
    }
}

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

pub struct GalaxySoa {
    pub x: Vec<f32>,
    pub y: Vec<f32>,
    pub z: Vec<f32>,
    pub mass: Vec<f32>,
    pub ax: Vec<f32>,
    pub ay: Vec<f32>,
    pub az: Vec<f32>,
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

#[no_mangle]
#[inline(never)]
pub fn aos_compute_forces(stars: &mut [Star]) {
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

#[no_mangle]
#[inline(never)]
pub fn soa_compute_forces(soa: &mut GalaxySoa) {
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
