// https://rosettacode.org/wiki/Jewels_and_stones
// {{works with|Zig|0.16.0}}
// {{trans|C++}}
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
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
