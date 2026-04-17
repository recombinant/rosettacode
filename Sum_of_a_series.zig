// https://rosettacode.org/wiki/Sum_of_a_series
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;

fn f(x: u64) f64 {
    return 1 / @as(f64, @floatFromInt(x * x));
}

fn sum(comptime func: fn (u64) f64, n: u64) f64 {
    var s: f64 = 0.0;
    var i: u64 = n;

    while (i != 0) : (i -= 1)
        s += func(i);

    return s;
}

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("S_1000 = {d:.15}\n", .{sum(f, 1000)});

    try stdout.flush();
}
