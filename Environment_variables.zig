// https://rosettacode.org/wiki/Environment_variables
// {{works with|Zig|0.16.0}}
const std = @import("std");

const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const allocator: Allocator = init.arena.allocator();
    const env: std.process.Environ = init.minimal.environ;
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    for ([_][]const u8{ "PATH", "HOME", "USER", "ZIGPATH" }) |v|
        try stdout.print("{s}={s}\n", .{ v, env.getAlloc(allocator, v) catch "???" });

    try stdout.flush();
}
