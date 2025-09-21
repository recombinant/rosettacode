// https://rosettacode.org/wiki/Loops/Foreach
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const list = [_][]const u8{ "Red", "Green", "Blue", "Black", "White" };
    for (list) |item|
        try stdout.print("{s}\n", .{item});

    try stdout.flush();
}
