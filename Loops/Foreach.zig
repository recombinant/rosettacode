// https://rosettacode.org/wiki/Loops/Foreach
// {{works with|Zig|0.16.1}}
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    const list = [_][]const u8{ "Red", "Green", "Blue", "Black", "White" };
    for (list) |item|
        try stdout.print("{s}\n", .{item});

    try stdout.flush();
}
