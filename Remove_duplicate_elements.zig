// https://rosettacode.org/wiki/Remove_duplicate_elements
// {{works with|Zig|0.15.1}}
const std = @import("std");

const testing = std.testing;
const print = std.debug.print;

pub fn main() anyerror!void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var a1 = [_]u16{ 1, 2, 3, 4, 1, 2, 3, 5, 1, 2, 3, 4, 5 };
    var a2: [a1.len]u16 = undefined;
    var a3: [a1.len]u16 = undefined;
    @memcpy(&a2, &a1);
    @memcpy(&a3, &a1);

    print("Original: {any}\n", .{a1});
    print("Method 1: {any}\n", .{try removeDuplicates1(allocator, &a1)});
    print("Method 2: {any}\n", .{removeDuplicates2(&a2)});
    print("Method 3: {any}\n", .{removeDuplicates3(&a3)});
}

fn removeDuplicates1(allocator: std.mem.Allocator, a: []u16) ![]u16 {
    if (a.len <= 1) return a;

    var map: std.AutoHashMapUnmanaged(u16, void) = .empty;
    defer map.deinit(allocator);

    for (a) |number|
        try map.put(allocator, number, {});

    var result = a;
    var it = map.keyIterator();
    var i: usize = 0;
    while (it.next()) |k| : (i += 1)
        result[i] = k.*;
    return result[0..i];
}

// TODO: counting down would be result in less copying with duplicates.
fn removeDuplicates2(a: []u16) []u16 {
    if (a.len <= 1) return a;

    var result = a;
    std.mem.sortUnstable(u16, result, {}, std.sort.asc(u16));

    var i: usize = result.len;
    while (i != 1) {
        i -= 1;
        if (a[i] == a[i - 1]) {
            for (a[i .. a.len - 1], a[i + 1 .. a.len]) |*dest, source|
                dest.* = source;
            result = result[0 .. result.len - 1];
        }
    }
    return result;
}

// TODO: counting down would be result in less copying with duplicates.
fn removeDuplicates3(a: []u16) []u16 {
    if (a.len <= 1) return a;

    var result = a;

    var i: usize = 0;
    var j: usize = 0;
    while (i < result.len - 1) {
        j = i + 1;
        while (j < result.len) {
            if (result[i] == result[j]) {
                for (result[j .. result.len - 1], result[j + 1 ..]) |*dest, source|
                    dest.* = source;
                result = result[0 .. result.len - 1];
            } else {
                j += 1;
            }
        }
        i += 1;
    }
    return result[0..j];
}

// Arrays are modified in-place, hence the separate tests

test "method1" {
    var a0 = [_]u16{};
    var a1 = [_]u16{1};
    var a2 = [_]u16{ 1, 1 };
    var a3a = [_]u16{ 1, 2, 1 };
    var a3b = [_]u16{ 1, 1, 2 };
    var a3c = [_]u16{ 2, 1, 1 };

    const allocator = testing.allocator;
    const b0 = try removeDuplicates1(allocator, &a0);
    const b1 = try removeDuplicates1(allocator, &a1);
    const b2 = try removeDuplicates1(allocator, &a2);
    const b3a = try removeDuplicates1(allocator, &a3a);
    const b3b = try removeDuplicates1(allocator, &a3b);
    const b3c = try removeDuplicates1(allocator, &a3c);
    // sort result as removeDuplicates1() cannot guarantee order
    std.mem.sortUnstable(u16, b0, {}, std.sort.asc(u16));
    std.mem.sortUnstable(u16, b1, {}, std.sort.asc(u16));
    std.mem.sortUnstable(u16, b2, {}, std.sort.asc(u16));
    std.mem.sortUnstable(u16, b3a, {}, std.sort.asc(u16));
    std.mem.sortUnstable(u16, b3b, {}, std.sort.asc(u16));
    std.mem.sortUnstable(u16, b3c, {}, std.sort.asc(u16));

    try testing.expectEqualSlices(u16, &[0]u16{}, b0);
    try testing.expectEqualSlices(u16, &[1]u16{1}, b1);
    try testing.expectEqualSlices(u16, &[1]u16{1}, b2);
    try testing.expectEqualSlices(u16, &[2]u16{ 1, 2 }, b3a);
    try testing.expectEqualSlices(u16, &[2]u16{ 1, 2 }, b3b);
    try testing.expectEqualSlices(u16, &[2]u16{ 1, 2 }, b3c);
}

test "method2" {
    var a0 = [_]u16{};
    var a1 = [_]u16{1};
    var a2 = [_]u16{ 1, 1 };
    var a3a = [_]u16{ 1, 2, 1 };
    var a3b = [_]u16{ 1, 1, 2 };
    var a3c = [_]u16{ 2, 1, 1 };

    try testing.expectEqualSlices(u16, &[0]u16{}, removeDuplicates2(&a0));
    try testing.expectEqualSlices(u16, &[1]u16{1}, removeDuplicates2(&a1));
    try testing.expectEqualSlices(u16, &[1]u16{1}, removeDuplicates2(&a2));
    try testing.expectEqualSlices(u16, &[2]u16{ 1, 2 }, removeDuplicates2(&a3a));
    try testing.expectEqualSlices(u16, &[2]u16{ 1, 2 }, removeDuplicates2(&a3b));
    try testing.expectEqualSlices(u16, &[2]u16{ 1, 2 }, removeDuplicates2(&a3c));
}

test "method3" {
    var a0 = [_]u16{};
    var a1 = [_]u16{1};
    var a2 = [_]u16{ 1, 1 };
    var a3a = [_]u16{ 1, 2, 1 };
    var a3b = [_]u16{ 1, 1, 2 };
    var a3c = [_]u16{ 2, 1, 1 };

    try testing.expectEqualSlices(u16, &[0]u16{}, removeDuplicates3(&a0));
    try testing.expectEqualSlices(u16, &[1]u16{1}, removeDuplicates3(&a1));
    try testing.expectEqualSlices(u16, &[1]u16{1}, removeDuplicates3(&a2));
    try testing.expectEqualSlices(u16, &[2]u16{ 1, 2 }, removeDuplicates3(&a3a));
    try testing.expectEqualSlices(u16, &[2]u16{ 1, 2 }, removeDuplicates3(&a3b));
    try testing.expectEqualSlices(u16, &[2]u16{ 2, 1 }, removeDuplicates3(&a3c));
}
