// https://rosettacode.org/wiki/Permutations_with_some_identical_elements
// Translation of: Go
// Based of C++ code from https://www.geeksforgeeks.org/distinct-permutations-string-set-2/
const std = @import("std");
const mem = std.mem;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ----------------------------------------------------------
    const stdout = std.io.getStdOut().writer();
    // ----------------------------------------------------------
    const nums2 = &[_]u8{ 2, 1 };
    try printPermutations(allocator, nums2, '1', stdout);
    // ----------------------------------------------------------
    const nums3 = &[_]u8{ 2, 3, 1 };
    try printPermutations(allocator, nums3, 'A', stdout);
    try printPermutations(allocator, nums3, '1', stdout);
}

fn printPermutations(allocator: mem.Allocator, input: []const u8, start: u8, writer: anytype) !void {
    try writer.print("{any}\n[ ", .{input});

    const slice = try createSlice(allocator, input, start);
    defer allocator.free(slice);

    try findPermutations(slice, 0, slice.len, writer);
    try writer.print("]\n\n", .{});
}

fn createSlice(allocator: mem.Allocator, nums: []const u8, start: u8) ![]u8 {
    var len: usize = 0;
    for (nums) |n|
        len += n;

    var slice = try std.ArrayList(u8).initCapacity(allocator, len);
    for (nums, start..) |n, i|
        try slice.appendNTimes(@intCast(i), n);

    return slice.toOwnedSlice();
}

// Prints all distinct permutations in str[0..n-1]
fn findPermutations(str: []u8, index: usize, n: usize, writer: anytype) !void {
    if (index >= n) {
        try writer.print("{s} ", .{str});
        return;
    }

    for (index..n) |i| {
        // Proceed further for str[i] only if it
        // doesn't match with any of the characters
        // after str[index]
        const check = shouldSwap(str, index, i);
        if (check) {
            mem.swap(u8, &str[index], &str[i]);
            try findPermutations(str, index + 1, n, writer);
            mem.swap(u8, &str[index], &str[i]);
        }
    }
}

// Returns true if str[curr] does not matches with any of the
// characters after str[start]
fn shouldSwap(str: []const u8, start: usize, curr: usize) bool {
    const c2 = str[curr];
    for (str[start..curr]) |c1|
        if (c1 == c2)
            return false;
    return true;
}
