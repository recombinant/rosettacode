// https://rosettacode.org/wiki/Compare_a_list_of_strings
// from https://github.com/tiehuis/zig-rosetta
const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const print = std.debug.print;

fn stringsAreEqual(list: []const []const u8) bool {
    for (list) |s|
        if (!mem.eql(u8, list[0], s)) {
            return false;
        };
    return true;
}

fn stringsAreInAscendingOrder(list: []const []const u8) bool {
    for (list[0 .. list.len - 1], list[1..list.len]) |a, b|
        if (mem.order(u8, a, b) != .lt) {
            return false;
        };
    return true;
}

pub fn main() void {
    const lists = &[_][]const []const u8{
        &[_][]const u8{ "AA", "BB", "CC" },
        &[_][]const u8{ "AA", "AA", "AA" },
        &[_][]const u8{ "AA", "CC", "BB" },
        &[_][]const u8{ "AA", "ACB", "BB", "CC" },
        &[_][]const u8{"single_element"},
    };

    for (lists) |list| {
        print("                   list: ", .{});
        for (list) |e|
            print("{s} ", .{e});
        print("\n", .{});

        print("lexicographically equal: {}\n", .{stringsAreEqual(list)});
        print(" strict ascending order: {}\n", .{stringsAreInAscendingOrder(list)});
        print("\n", .{});
    }
}

// Translation of Go tests

test stringsAreEqual {
    const eq_tests = [_]struct { desc: []const u8, list: []const []const u8, expected: bool }{
        .{ .desc = "just one string", .list = &[_][]const u8{"a"}, .expected = true },
        .{ .desc = "2 equal", .list = &[_][]const u8{ "a", "a" }, .expected = true },
        .{ .desc = "2 unequal", .list = &[_][]const u8{ "a", "b" }, .expected = false },
    };
    for (eq_tests) |tc|
        try testing.expectEqual(tc.expected, stringsAreEqual(tc.list));
}

test stringsAreInAscendingOrder {
    const lt_tests = [_]struct { desc: []const u8, list: []const []const u8, expected: bool }{
        .{ .desc = "just one string", .list = &[_][]const u8{"a"}, .expected = true },
        .{ .desc = "2 ordered", .list = &[_][]const u8{ "a", "b" }, .expected = true },
        .{ .desc = "2 not strictly ordered", .list = &[_][]const u8{ "a", "a" }, .expected = false },
    };
    for (lt_tests) |tc|
        try testing.expectEqual(tc.expected, stringsAreInAscendingOrder(tc.list));
}
