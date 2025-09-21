// https://rosettacode.org/wiki/Longest_common_prefix
// {{works with|Zig|0.15.1}}
// {{trans|Wren (alternative version)}}
const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

fn lcp(allocator: std.mem.Allocator, strings: []const []const u8) ![]u8 {
    if (strings.len == 0)
        return try allocator.alloc(u8, 0);
    if (strings.len == 1)
        return try allocator.dupe(u8, strings[0]);

    var max: usize = std.math.maxInt(usize);
    for (strings) |s|
        max = @min(max, s.len);

    if (max == 0)
        return try allocator.alloc(u8, 0);

    var result: std.ArrayList(u8) = .empty;

    outer: for (0..max) |n| {
        const c = strings[0][n];
        for (strings[1..]) |s|
            if (s[n] != c)
                break :outer;
        try result.append(allocator, c);
    }

    return try result.toOwnedSlice(allocator);
}

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const data = [_][]const []const u8{
        &.{ "interspecies", "interstellar", "interstate" },
        &.{ "throne", "throne" },
        &.{ "throne", "dungeon" },
        &.{ "throne", "", "throne" },
        &.{ "prefix", "suffix" },
        &.{ "foo", "foobar" },
        &.{"cheese"},
        &.{},
        &.{""},
        &.{ "", "" },
    };

    for (data) |strings| {
        const result = try lcp(allocator, strings);

        defer allocator.free(result);

        print("Longest common prefix : {s}\n", .{result});
    }
}
