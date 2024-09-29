// https://rosettacode.org/wiki/Golden_ratio/Convergence#C
const std = @import("std");
const math = std.math;

pub fn main() !void {
    try calcGoldenRatio(f16);
    try calcGoldenRatio(f32);
    try calcGoldenRatio(f64);
    try calcGoldenRatio(f80);
    try calcGoldenRatio(f128);
}

fn calcGoldenRatio(comptime T: type) !void {
    var count: usize = 0;
    var phi0: T = 1;
    var phi1: T = undefined;
    while (true) {
        phi1 = 1 + (1 / phi0);
        const difference = @abs(phi1 - phi0);
        phi0 = phi1;
        count += 1;
        if (difference <= 1.0e-5) break;
    }

    const stdout = std.io.getStdOut().writer();
    // Zig 0.13 prints f64, convert to f64 for printing
    const phi: f64 = @floatCast(phi1);
    try stdout.print("Using type {s} --\n", .{@typeName(T)});
    try stdout.print("Result: {d} after {d} iterations\n", .{ phi, count });
    // use f128 for maximum precision
    const err: f64 = @floatCast(@as(f128, @floatCast(phi1)) - math.phi);
    try stdout.print("The error is approximately {d}\n\n", .{err});
}
