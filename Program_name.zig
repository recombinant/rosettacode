// https://rosettacode.org/wiki/Program_name
// {{works with|Zig|0.16.0}}

// Copied from rosettacode
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    const args = try init.minimal.args.toSlice(init.arena.allocator());
    const program_name = if (args.len > 0) std.fs.path.basename(args[0]) else "unknown";

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("{s}\n", .{program_name});

    try stdout.flush();
}
