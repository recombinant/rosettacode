// https://rosettacode.org/wiki/Symmetric_difference
const std = @import("std");

pub fn main() !void {
    const a = [_][]const u8{ "John", "Bob", "Mary", "Serena" };
    const b = [_][]const u8{ "Jim", "Mary", "John", "Bob" };

    const a_dupe = [_][]const u8{ "John", "Serena", "Bob", "Mary", "Serena" };
    const b_dupe = [_][]const u8{ "Jim", "Mary", "John", "Jim", "Bob" };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const writer = std.io.getStdOut().writer();

    try writer.writeAll("Without duplicate items:\n");
    try printSymmetricDifference(allocator, &a, &b, writer);
    try printSymmetricDifference(allocator, &b, &a, writer);
    try writer.writeAll("\nWith duplicate items:\n");
    try printSymmetricDifference(allocator, &a_dupe, &b_dupe, writer);
    try printSymmetricDifference(allocator, &b_dupe, &a_dupe, writer);
}

fn printSymmetricDifference(allocator: std.mem.Allocator, a: []const []const u8, b: []const []const u8, writer: anytype) !void {
    var set = std.StringArrayHashMap(void).init(allocator);
    defer set.deinit();
    for (a) |string|
        try set.put(string, {});
    var set_a = try set.clone();
    defer set_a.deinit();

    for (b) |string| {
        if (set_a.contains(string))
            _ = set.swapRemove(string)
        else
            try set.put(string, {});
    }

    const output = try std.mem.join(allocator, ", ", set.keys());
    defer allocator.free(output);

    try writer.print("  {s}\n", .{output});
}
