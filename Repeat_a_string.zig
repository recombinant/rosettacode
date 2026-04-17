// https://rosettacode.org/wiki/Repeat_a_string
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    // comptime
    try stdout.print("{s}\n", .{"ha" ** 5});

    // runtime using writeSplat()
    _ = try stdout.writeSplat(&.{"ha"}, 5);
    try stdout.writeByte('\n');

    const repeated = try repeat(gpa, "ha", 5);
    defer gpa.free(repeated);
    try stdout.print("{s}\n", .{repeated});

    try stdout.flush();
}

/// Caller owns returned slice memory.
fn repeat(allocator: Allocator, s: []const u8, n: usize) ![]u8 {
    var buffer: std.ArrayList(u8) = try .initCapacity(allocator, s.len * n);
    for (0..n) |_|
        try buffer.appendSlice(allocator, s);

    return buffer.toOwnedSlice(allocator);
}
