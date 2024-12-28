// https://rosettacode.org/wiki/Entropy
// Copied from rosettacode
// Works with Zig 0.11.0 thru 0.14.0 incl
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d:.12}\n", .{H("1223334444")});
}

fn H(s: []const u8) f64 {
    var counts = [_]u16{0} ** 256;
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
