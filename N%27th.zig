// https://rosettacode.org/wiki/N%27th
// Translation of: C
const std = @import("std");
const heap = std.heap;
const math = std.math;
const mem = std.mem;

const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ranges = [_][2]usize{ .{ 0, 25 }, .{ 250, 265 }, .{ 1000, 1025 } };
    for (ranges) |range|
        try printRange(allocator, range[0], range[1]);
}

fn printRange(allocator: mem.Allocator, lo: usize, hi: usize) !void {
    print("Set [{},{}] :\n", .{ lo, hi });
    for (lo..hi + 1) |n| {
        const s = try nth(allocator, n, .{});
        defer allocator.free(s);
        print("{s} ", .{s});
    }
    print("\n\n", .{});
}

const NthOptions = struct {
    apostrophe: bool = false,
};

/// Caller owns returned slice memory.
fn nth(allocator: mem.Allocator, n: usize, options: NthOptions) ![]const u8 {
    const apostrophe: []const u8 = if (options.apostrophe) "'" else "";

    // Calculate the precise amount of memory required to
    // eliminate realloc() and potentially reduce memory
    // fragmentation in allocator.
    // Verified with LoggingAllocator.

    // count of digits + (1? for apostrophe) (2 for length of suffix)
    const len = (if (n == 0) 1 else math.log10_int(n) + 1) + apostrophe.len + 2;

    var result = try std.ArrayList(u8).initCapacity(allocator, len);
    const writer = result.writer();

    try writer.print("{d}{s}{s}", .{ n, apostrophe, getSuffix(n) });

    return result.toOwnedSlice();
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
