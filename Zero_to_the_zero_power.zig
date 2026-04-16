// https://rosettacode.org/wiki/Zero_to_the_zero_power
// {{works with|Zig|0.16.0}}
// Copied from rosettacode
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("0^0 = {d:.8}\n", .{comptime std.math.pow(f32, 0, 0)});

    try stdout.flush();
}
