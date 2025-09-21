// https://rosettacode.org/wiki/N%27th
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&buffer);
    const stdout = &stdout_writer.interface;

    const ranges = [_][2]usize{ .{ 0, 25 }, .{ 250, 265 }, .{ 1000, 1025 } };
    for (ranges) |range|
        try printRange(allocator, range[0], range[1], stdout);

    try stdout.flush();
}

fn printRange(allocator: std.mem.Allocator, lo: usize, hi: usize, w: *std.Io.Writer) !void {
    try w.print("Set [{},{}] :\n", .{ lo, hi });
    for (lo..hi + 1) |n| {
        const s = try nth(allocator, n, .{});
        defer allocator.free(s);
        try w.print("{s} ", .{s});
    }
    try w.print("\n\n", .{});
}

const NthOptions = struct {
    apostrophe: bool = false,
};

/// Caller owns returned slice memory.
fn nth(allocator: std.mem.Allocator, n: usize, options: NthOptions) ![]const u8 {
    const apostrophe: []const u8 = if (options.apostrophe) "'" else "";

    // Calculate the precise amount of memory required to
    // eliminate realloc() and potentially reduce memory
    // fragmentation in allocator.
    // Verified with LoggingAllocator.

    // count of digits + (1? for apostrophe) (2 for length of suffix)
    const len = (if (n == 0) 1 else std.math.log10_int(n) + 1) + apostrophe.len + 2;

    var a: std.Io.Writer.Allocating = try .initCapacity(allocator, len);
    defer a.deinit();
    const w = &a.writer;

    try w.print("{d}{s}{s}", .{ n, apostrophe, getSuffix(n) });

    return a.toOwnedSlice();
}

fn getSuffix(n: usize) []const u8 {
    const suffixes = [4][]const u8{
        "th", "st", "nd", "rd",
    };
    return suffixes[
        switch (n % 10) {
            1 => if (n % 100 == 11) 0 else 1,
            2 => if (n % 100 == 12) 0 else 2,
            3 => if (n % 100 == 13) 0 else 3,
            else => 0,
        }
    ];
}

const testing = std.testing;

test getSuffix {
    try testing.expectEqualSlices(u8, "rd", getSuffix(3));
    try testing.expectEqualSlices(u8, "nd", getSuffix(42));
}

test nth {
    const actual1 = try nth(testing.allocator, 3, .{ .apostrophe = true });
    try testing.expectEqualSlices(u8, "3'rd", actual1);
    testing.allocator.free(actual1);

    const actual2 = try nth(testing.allocator, 42, .{});
    try testing.expectEqualSlices(u8, "42nd", actual2);
    testing.allocator.free(actual2);
}
