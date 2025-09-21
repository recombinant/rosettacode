// https://rosettacode.org/wiki/Jewels_and_stones
// {{works with|Zig|0.15.1}}
// {{trans|C++}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("{}\n", .{countJewels("aAAbbbb", "aA")});
    try stdout.print("{}\n", .{countJewels("ZZ", "z")});
    try stdout.print("{}\n", .{countJewels("pack my box with five dozen liquor jugs", "aeiou")});

    try stdout.flush();
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
