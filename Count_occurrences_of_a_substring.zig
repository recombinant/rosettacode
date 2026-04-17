// https://rosettacode.org/wiki/Count_occurrences_of_a_substring
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("{d}\n", .{std.mem.count(u8, "the three truths", "th")});
    try stdout.print("{d}\n", .{std.mem.count(u8, "abababababa", "abab")});
    try stdout.print("{d}\n", .{std.mem.count(u8, "abaabba*bbaba*bbab", "a*b")});

    try stdout.flush();
}
