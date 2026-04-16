// https://rosettacode.org/wiki/Command-line_arguments
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;
    const gpa: Allocator = init.gpa;
    const args = init.minimal.args;
    // ------------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ---------------------------------------------------
    var it = try args.iterateAllocator(gpa);
    defer it.deinit();
    //
    var i: usize = 0;
    while (it.next()) |arg| {
        try stdout.print("arg {}: {s}\n", .{ i, arg });
        i += 1;
    }
    try stdout.flush();
}
