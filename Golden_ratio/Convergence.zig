// https://rosettacode.org/wiki/Golden_ratio/Convergence#C
// {{works with|Zig|0.15.1}}
const std = @import("std");

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

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Using type {s} --\n", .{@typeName(T)});
    try stdout.print("Result: {d} after {d} iterations\n", .{ phi1, count });

    const err = phi1 - std.math.phi;
    try stdout.print("The error is approximately {d}\n\n", .{err});

    try stdout.flush();
}
