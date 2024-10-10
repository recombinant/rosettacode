// https://rosettacode.org/wiki/Steffensen%27s_method
// Translation of C
const std = @import("std");

pub fn main() !void {
    // --------------------------------------------------------------
    const stdout = std.io.getStdOut().writer();
    // --------------------------------------------------------------
    var t0: f64 = 0;
    for (0..11) |_| {
        try stdout.print("t0 = {d:0.1} : ", .{t0});
        if (steffensenAitken(&f, t0, 0.00000001, 1_000)) |t| {
            const x = xConvexLeftParabola(t);
            const y = yConvexRightParabola(t);
            if (@abs(implicitEquation(x, y)) <= 0.000001)
                try stdout.print("intersection at ({d:.6}, {d:.6})\n", .{ x, y })
            else
                try stdout.writeAll("spurious solution\n");
        } else {
            try stdout.writeAll("no answer\n");
        }
        t0 += 0.1;
    }
}

fn aitken(func: *const fn (f64) f64, p0: f64) f64 {
    const p1 = func(p0);
    const p2 = func(p1);
    const p1m0 = p1 - p0;
    return p0 - p1m0 * p1m0 / (p2 - 2.0 * p1 + p0);
}
fn steffensenAitken(func: *const fn (f64) f64, pinit: f64, tolerance: f64, maxiter: usize) ?f64 {
    var p0 = pinit;
    var p = aitken(func, p0);
    var iter: usize = 1;
    while (@abs(p - p0) > tolerance and iter < maxiter) {
        p0 = p;
        p = aitken(func, p0);
        iter += 1;
    }
    if (@abs(p - p0) > tolerance) return null;
    return p;
}
fn deCasteljau(c0: f64, c1: f64, c2: f64, t: f64) f64 {
    const s = 1.0 - t;
    const c01 = s * c0 + t * c1;
    const c12 = s * c1 + t * c2;
    return s * c01 + t * c12;
}
fn xConvexLeftParabola(t: f64) f64 {
    return deCasteljau(2.0, -8.0, 2.0, t);
}
fn yConvexRightParabola(t: f64) f64 {
    return deCasteljau(1.0, 2.0, 3.0, t);
}
fn implicitEquation(x: f64, y: f64) f64 {
    return 5.0 * x * x + y - 5.0;
}
fn f(t: f64) f64 {
    const x = xConvexLeftParabola(t);
    const y = yConvexRightParabola(t);
    return implicitEquation(x, y) + t;
}
