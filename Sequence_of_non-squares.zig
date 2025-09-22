// https://rosettacode.org/wiki/Sequence_of_non-squares
// {{works with|Zig|0.15.1}}
const std = @import("std");

fn nonSquare(n: usize) usize {
    return n + @as(usize, @intFromFloat(0.5 + @sqrt(@as(f64, @floatFromInt(n)))));
}

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    for (1..23) |i|
        try stdout.print("{} ", .{nonSquare(i)});
    try stdout.writeByte('\n');

    try stdout.flush();
}

test "test non-square" {
    for (1..1_000_000) |i| {
        const j = @sqrt(@as(f64, @floatFromInt(nonSquare(i))));
        try std.testing.expect(j != @floor(j));
    }
}
