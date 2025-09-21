// https://rosettacode.org/wiki/Permutations_with_some_identical_elements
// {{works with|Zig|0.15.1}}
// {{trans|Go}}

// Based of C++ code from https://www.geeksforgeeks.org/distinct-permutations-string-set-2/
// with original comments.
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // --------------------------------
    const nums2 = &[_]u8{ 2, 1 };
    try printPermutations(allocator, nums2, '1', stdout);
    // --------------------------------
    const nums3 = &[_]u8{ 2, 3, 1 };
    try printPermutations(allocator, nums3, 'A', stdout);
    try printPermutations(allocator, nums3, '1', stdout);
    // --------------------------------
    try stdout.flush();
}

fn printPermutations(allocator: std.mem.Allocator, input: []const u8, start: u8, writer: *std.Io.Writer) !void {
    try writer.print("{any}\n[ ", .{input});

    const slice = try createSlice(allocator, input, start);
    defer allocator.free(slice);

    try findPermutations(slice, 0, slice.len, writer);

    try writer.print("]\n\n", .{});
}

fn createSlice(allocator: std.mem.Allocator, nums: []const u8, start: u8) ![]u8 {
    var len: usize = 0;
    for (nums) |n|
        len += n;

    var slice: std.ArrayList(u8) = try .initCapacity(allocator, len);
    for (nums, start..) |n, i|
        try slice.appendNTimes(allocator, @intCast(i), n);

    return slice.toOwnedSlice(allocator);
}

// Prints all distinct permutations in str[0..n-1]
fn findPermutations(str: []u8, index: usize, n: usize, writer: *std.Io.Writer) !void {
    if (index >= n) {
        try writer.print("{s} ", .{str});
        return;
    }
    for (index..n) |i| {
        // Proceed further for str[i] only if it
        // doesn't match with any of the characters
        // after str[index]
        const check = std.mem.indexOfScalar(u8, str[index..i], str[i]) == null;
        if (check) {
            std.mem.swap(u8, &str[index], &str[i]);
            try findPermutations(str, index + 1, n, writer);
            std.mem.swap(u8, &str[index], &str[i]);
        }
    }
}
