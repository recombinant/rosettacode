// https://rosettacode.org/wiki/Symmetric_difference
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    const a = [_][]const u8{ "John", "Bob", "Mary", "Serena" };
    const b = [_][]const u8{ "Jim", "Mary", "John", "Bob" };

    const a_dupe = [_][]const u8{ "John", "Serena", "Bob", "Mary", "Serena" };
    const b_dupe = [_][]const u8{ "Jim", "Mary", "John", "Jim", "Bob" };

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll("Without duplicate items:\n");
    try printSymmetricDifference(allocator, &a, &b, stdout);
    try printSymmetricDifference(allocator, &b, &a, stdout);
    try stdout.writeAll("\nWith duplicate items:\n");
    try printSymmetricDifference(allocator, &a_dupe, &b_dupe, stdout);
    try printSymmetricDifference(allocator, &b_dupe, &a_dupe, stdout);

    try stdout.flush();
}

fn printSymmetricDifference(allocator: std.mem.Allocator, a: []const []const u8, b: []const []const u8, w: *std.Io.Writer) !void {
    var set: std.StringArrayHashMapUnmanaged(void) = .empty;
    defer set.deinit(allocator);
    for (a) |string|
        try set.put(allocator, string, {});
    var set_a = try set.clone(allocator);
    defer set_a.deinit(allocator);

    for (b) |string| {
        if (set_a.contains(string))
            _ = set.swapRemove(string)
        else
            try set.put(allocator, string, {});
    }

    const output = try std.mem.join(allocator, ", ", set.keys());
    defer allocator.free(output);

    try w.print("  {s}\n", .{output});
}
