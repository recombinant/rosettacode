// https://rosettacode.org/wiki/Repeat_a_string
const std = @import("std");
const heap = std.heap;
const mem = std.mem;
const print = std.debug.print;

pub fn main() !void {
    // comptime
    print("{s}\n", .{"ha" ** 5});

    // dynamically allocated
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const repeated = try repeat(allocator, "ha", 5);
    defer allocator.free(repeated);
    print("{s}\n", .{repeated});
}

/// Caller owns returned slice memory.
fn repeat(allocator: mem.Allocator, s: []const u8, n: usize) ![]u8 {
    var buffer = try std.ArrayList(u8).initCapacity(allocator, s.len * n);
    for (0..n) |_|
        try buffer.appendSlice(s);

    return buffer.toOwnedSlice();
}
