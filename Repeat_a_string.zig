// https://rosettacode.org/wiki/Repeat_a_string
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    // comptime
    try stdout.print("{s}\n", .{"ha" ** 5});

    // runtime using writeSplat()
    _ = try stdout.writeSplat(&.{"ha"}, 5);
    try stdout.writeByte('\n');

    // dynamically allocated
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const repeated = try repeat(allocator, "ha", 5);
    defer allocator.free(repeated);
    try stdout.print("{s}\n", .{repeated});

    try stdout.flush();
}

/// Caller owns returned slice memory.
fn repeat(allocator: std.mem.Allocator, s: []const u8, n: usize) ![]u8 {
    var buffer: std.ArrayList(u8) = try .initCapacity(allocator, s.len * n);
    for (0..n) |_|
        try buffer.appendSlice(allocator, s);

    return buffer.toOwnedSlice(allocator);
}
