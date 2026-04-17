// https://rosettacode.org/wiki/Golden_ratio/Convergence#C
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try printGoldenRatio(f16, stdout);
    try printGoldenRatio(f32, stdout);
    try printGoldenRatio(f64, stdout);
    try printGoldenRatio(f80, stdout);
    try printGoldenRatio(f128, stdout);

    try stdout.flush();
}

fn printGoldenRatio(comptime T: type, w: *Io.Writer) !void {
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

    try w.print("Using type {s} --\n", .{@typeName(T)});
    try w.print("Result: {d} after {d} iterations\n", .{ phi1, count });

    const err = phi1 - std.math.phi;
    try w.print("The error is approximately {d}\n\n", .{err});
}
