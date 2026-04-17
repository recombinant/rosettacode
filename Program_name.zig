// https://rosettacode.org/wiki/Program_name
// {{works with|Zig|0.16.0}}

// Copied from rosettacode
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const args: std.process.Args = init.minimal.args;
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    var it = try args.iterateAllocator(gpa);
    defer it.deinit();

    const program_name = if (it.next()) |arg| std.fs.path.basename(arg) else "unknown";

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("{s}\n", .{program_name});

    try stdout.flush();
}
