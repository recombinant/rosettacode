// https://rosettacode.org/wiki/Klarner-Rado_sequence
// {{works with|Zig|0.16.0}}
// {{trans|C}}
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stderr_buffer: [1024]u8 = undefined;
    var stderr_writer = Io.File.stderr().writer(io, &stderr_buffer);
    const stderr = &stderr_writer.interface;

    var stdout_buffer: [128]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    var t0: Io.Timestamp = .now(io, .real);

    const kr = klarnerRado(1_000_000);

    // Task 1
    try stdout.writeAll("First 100 elements of Klarner-Rado sequence:\n");
    for (kr[0..100], 1..) |value, i| {
        try stdout.print("{d:3} ", .{value});
        if (i % 10 == 0) try stdout.writeByte('\n');
    }
    try stdout.writeByte('\n');

    // Tasks 2 & 3
    const limits = [_]usize{ 1_000, 10_000, 100_000, 1_000_000 };
    for (limits) |limit|
        try stdout.print("The {}{s} element: {d}\n", .{ limit, if (limit == 1) "st" else "th", kr[limit - 1] });
    try stdout.flush();

    try stderr.print("\nprocessed in {f}\n", .{t0.untilNow(io, .real)});
    try stderr.flush();
}

fn klarnerRado(comptime n: usize) [n]u32 {
    var dst: [n]u32 = @splat(0);
    var i_2: usize = 0;
    var i_3: usize = 0;
    var m2: u32 = 1;
    var m3: u32 = 1;
    for (0..n) |i| {
        const m = @min(m2, m3);
        dst[i] = m;
        if (m2 == m) {
            m2 = dst[i_2] << 1 | 1;
            i_2 += 1;
        }
        if (m3 == m) {
            m3 = dst[i_3] * 3 + 1;
            i_3 += 1;
        }
    }
    return dst;
}
