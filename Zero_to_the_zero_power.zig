// https://rosettacode.org/wiki/Zero_to_the_zero_power
// {{works with|Zig|0.15.1}}
// Copied from rosettacode
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("0^0 = {d:.8}\n", .{comptime std.math.pow(f32, 0, 0)});

    try stdout.flush();
}
