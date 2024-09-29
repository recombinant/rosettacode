// https://www.rosettacode.org/wiki/Strip_a_set_of_characters_from_a_string
const std = @import("std");
const mem = std.mem;

pub fn main() !void {
    // ------------------------------------------------------- stdout
    const stdout = std.io.getStdOut().writer();
    // ---------------------------------------------------- allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------
    const s = try strip(allocator, "She was a soul stripper. She took my heart!", "aei");
    defer allocator.free(s);

    try stdout.print("{s}\n", .{s});
}

/// Caller owns returned slice memory.
fn strip2(allocator: mem.Allocator, s: []const u8, remove: []const u8) ![]const u8 {
    var buffer = std.ArrayList(u8).init(allocator);
    const writer = buffer.writer();

    var it = mem.tokenizeAny(u8, s, remove);
    while (it.next()) |substring|
        try writer.writeAll(substring);

    return try buffer.toOwnedSlice();
}

/// Caller owns returned slice memory.
fn strip(allocator: mem.Allocator, s: []const u8, remove: []const u8) ![]const u8 {
    // Determine size of stripped result.
    var size: usize = 0;
    for (s) |c|
        if (mem.indexOfScalar(u8, remove, c) == null) {
            size += 1;
        };

    var stripped = try allocator.alloc(u8, size);
    var index: usize = 0;
    for (s) |c|
        if (mem.indexOfScalar(u8, remove, c) == null) {
            stripped[index] = c;
            index += 1;
        };

    return stripped;
}

const testing = std.testing;

test "strip vs strip2" {
    const s1 = try strip(testing.allocator, "She was a soul stripper. She took my heart!", "aei");
    defer testing.allocator.free(s1);
    const s2 = try strip2(testing.allocator, "She was a soul stripper. She took my heart!", "aei");
    defer testing.allocator.free(s2);

    try testing.expectEqualStrings(s1, s2);
}
