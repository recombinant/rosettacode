// https://rosettacode.org/wiki/Jewels_and_stones
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("{}\n", .{countJewels("aAAbbbb", "aA")});
    try stdout.print("{}\n", .{countJewels("ZZ", "z")});
    try stdout.print("{}\n", .{countJewels("pack my box with five dozen liquor jugs", "aeiou")});
}

fn countJewels(stones: []const u8, jewels: []const u8) usize {
    var sum: usize = 0;
    for (jewels) |j|
        for (stones) |s|
            if (s == j) {
                sum += 1;
            };
    return sum;
}
