// https://rosettacode.org/wiki/Permutations_with_some_identical_elements
// {{works with|Zig|0.16.0}}
// {{trans|Go}}

// Based of C++ code from https://www.geeksforgeeks.org/distinct-permutations-string-set-2/
// with original comments.
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;
    // --------------------------------
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    // --------------------------------
    const nums2 = &[_]u8{ 2, 1 };
    try printPermutations(gpa, nums2, '1', stdout);
    // --------------------------------
    const nums3 = &[_]u8{ 2, 3, 1 };
    try printPermutations(gpa, nums3, 'A', stdout);
    try printPermutations(gpa, nums3, '1', stdout);
    // --------------------------------
    try stdout.flush();
}

fn printPermutations(allocator: Allocator, input: []const u8, start: u8, writer: *Io.Writer) !void {
    try writer.print("{any}\n[ ", .{input});

    const slice = try createSlice(allocator, input, start);
    defer allocator.free(slice);

    try findPermutations(slice, 0, slice.len, writer);

    try writer.print("]\n\n", .{});
}

fn createSlice(allocator: Allocator, nums: []const u8, start: u8) ![]u8 {
    var len: usize = 0;
    for (nums) |n|
        len += n;

    var slice: std.ArrayList(u8) = try .initCapacity(allocator, len);
    for (nums, start..) |n, i|
        try slice.appendNTimes(allocator, @intCast(i), n);

    return slice.toOwnedSlice(allocator);
}

// Prints all distinct permutations in str[0..n-1]
fn findPermutations(str: []u8, index: usize, n: usize, writer: *Io.Writer) !void {
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
