// https://www.rosettacode.org/wiki/Strip_a_set_of_characters_from_a_string
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;
    // ------------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    // --------------------------------------------------------------
    const s = try strip(gpa, "She was a soul stripper. She took my heart!", "aei");
    defer gpa.free(s);

    try stdout.print("{s}\n", .{s});

    try stdout.flush();
}

/// Caller owns returned slice memory.
fn strip2(allocator: Allocator, s: []const u8, remove: []const u8) ![]const u8 {
    var a: Io.Writer.Allocating = .init(allocator);
    defer a.deinit();

    var it = std.mem.tokenizeAny(u8, s, remove);
    while (it.next()) |substring|
        try a.writer.writeAll(substring);

    return try a.toOwnedSlice();
}

/// Caller owns returned slice memory.
fn strip(allocator: Allocator, s: []const u8, remove: []const u8) ![]const u8 {
    // Determine size of stripped result.
    var size: usize = 0;
    for (s) |c|
        if (std.mem.indexOfScalar(u8, remove, c) == null) {
            size += 1;
        };

    var stripped = try allocator.alloc(u8, size);
    var index: usize = 0;
    for (s) |c|
        if (std.mem.indexOfScalar(u8, remove, c) == null) {
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
