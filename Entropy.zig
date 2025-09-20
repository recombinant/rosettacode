// https://rosettacode.org/wiki/Entropy
// {{works with|Zig|0.15.1}}
// Copied from rosettacode
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("{d:.12}\n", .{H("1223334444")});

    try stdout.flush();
}

fn H(s: []const u8) f64 {
    var counts: [256]u16 = @splat(0);
    for (s) |ch|
        counts[ch] += 1;

    var h: f64 = 0;
    for (counts) |c|
        if (c != 0) {
            const p = @as(f64, @floatFromInt(c)) / @as(f64, @floatFromInt(s.len));
            h -= p * @log2(p);
        };

    return h;
}
