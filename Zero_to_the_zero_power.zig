// https://rosettacode.org/wiki/Zero_to_the_zero_power
// Copied from rosettacode
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("0^0 = {d:.8}\n", .{comptime std.math.pow(f32, 0, 0)});
}
