// https://rosettacode.org/wiki/Symmetric_difference
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    const a = [_][]const u8{ "John", "Bob", "Mary", "Serena" };
    const b = [_][]const u8{ "Jim", "Mary", "John", "Bob" };

    const a_dupe = [_][]const u8{ "John", "Serena", "Bob", "Mary", "Serena" };
    const b_dupe = [_][]const u8{ "Jim", "Mary", "John", "Jim", "Bob" };

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll("Without duplicate items:\n");
    try printSymmetricDifference(gpa, &a, &b, stdout);
    try printSymmetricDifference(gpa, &b, &a, stdout);

    try stdout.writeAll("\nWith duplicate items:\n");
    try printSymmetricDifference(gpa, &a_dupe, &b_dupe, stdout);
    try printSymmetricDifference(gpa, &b_dupe, &a_dupe, stdout);

    try stdout.flush();
}

fn printSymmetricDifference(allocator: Allocator, a: []const []const u8, b: []const []const u8, w: *Io.Writer) !void {
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
