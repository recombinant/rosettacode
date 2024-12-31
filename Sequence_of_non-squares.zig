// https://rosettacode.org/wiki/Sequence_of_non-squares
const std = @import("std");

fn nonSquare(n: usize) usize {
    return n + @as(usize, @intFromFloat(0.5 + @sqrt(@as(f64, @floatFromInt(n)))));
}

pub fn main() !void {
    const writer = std.io.getStdOut().writer();
    for (1..23) |i|
        try writer.print("{} ", .{nonSquare(i)});
    try writer.print("\n", .{});
}

test "test non-square" {
    for (1..1_000_000) |i| {
        const j = @sqrt(@as(f64, @floatFromInt(nonSquare(i))));
        try std.testing.expect(j != @floor(j));
    }
}
