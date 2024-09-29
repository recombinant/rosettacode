// https://rosettacode.org/wiki/Append_numbers_at_same_position_in_strings
const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;
const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() !void {
    // ---------------------------------------------------- allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------

    const list1 = [_]u32{ 1, 2, 3, 4, 5, 6, 7, 8, 9 };
    const list2 = [_]u32{ 10, 11, 12, 13, 14, 15, 16, 17, 18 };
    const list3 = [_]u32{ 19, 20, 21, 22, 23, 24, 25, 26, 27 };

    const lists = [_][]const u32{ &list1, &list2, &list3 };

    const result = try concatenateLists(allocator, lists[0..]);
    defer {
        for (result) |list| allocator.free(list);
        allocator.free(result);
    }

    const s = try mem.join(allocator, ",", result);
    print("list=[{s}]\n", .{s});
    allocator.free(s);
}

/// Return result as slice of strings. Caller owns returned memory.
fn concatenateLists(allocator: mem.Allocator, lists: []const []const u32) ![][]const u8 {
    for (lists[1..]) |list| assert(list.len == lists[0].len);

    var result = std.ArrayList([]const u8).init(allocator);

    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();
    const writer = buffer.writer();

    for (0..lists[0].len) |i| {
        buffer.clearRetainingCapacity();
        for (lists) |list|
            try fmt.formatInt(list[i], 10, .lower, .{}, writer);
        try result.append(try allocator.dupe(u8, buffer.items));
    }
    return try result.toOwnedSlice();
}
