// https://rosettacode.org/wiki/String_case
// {{works with|Zig|0.15.1}}

// Note: could use https://codeberg.org/dude_the_builder/zigstr
// Copied from rosettacode
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const string = "alphaBETA";
    var lower: [string.len]u8 = undefined;
    var upper: [string.len]u8 = undefined;
    for (string, &lower, &upper) |char, *lo, *up| {
        lo.* = std.ascii.toLower(char);
        up.* = std.ascii.toUpper(char);
    }
    try stdout.print("lower: {s}\n", .{lower});
    try stdout.print("upper: {s}\n", .{upper});

    try stdout.flush();
}
