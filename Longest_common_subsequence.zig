// https://rosettacode.org/wiki/Longest_common_subsequence
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    // ------------------------------------------ allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ------------------------------------------------ lcs
    const a = "thisisatest";
    const b = "testing123testing";

    const result = try lcs(allocator, a, b);
    defer allocator.free(result);
    // ---------------------------------------------- print
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("{s}\n", .{result});

    try stdout.flush();
}

/// Caller owns returned slice memory.
fn lcs(allocator: std.mem.Allocator, a: []const u8, b: []const u8) ![]const u8 {
    // generate matrix of length of longest common subsequence for substrings of both strings
    const ls = try allocator.alloc([]usize, a.len + 1);
    defer allocator.free(ls);

    const array = try allocator.alloc(usize, (a.len + 1) * (b.len + 1));
    defer allocator.free(array);
    @memset(array, 0);
    // slice `array` for `ls` to create matrix
    for (ls, 0..) |*p, i| {
        const start = i * (b.len + 1);
        const end = (i + 1) * (b.len + 1);
        p.* = array[start..end];
    }

    for (a, 0..) |x, i|
        for (b, 0..) |y, j| {
            if (x == y)
                ls[i + 1][j + 1] = ls[i][j] + 1
            else
                ls[i + 1][j + 1] = @max(ls[i + 1][j], ls[i][j + 1]);
        };

    var result: std.ArrayList(u8) = .empty;
    var tmp: std.ArrayList(u8) = .empty;
    defer tmp.deinit(allocator);

    // read a substring from the matrix
    var x = a.len;
    var y = b.len;
    while (x > 0 and y > 0) {
        if (ls[x][y] == ls[x - 1][y])
            x -= 1
        else if (ls[x][y] == ls[x][y - 1])
            y -= 1
        else {
            std.debug.assert(a[x - 1] == b[y - 1]);
            tmp.clearAndFree(allocator);
            try tmp.append(allocator, a[x - 1]);
            try tmp.appendSlice(allocator, result.items);
            std.mem.swap(std.ArrayList(u8), &result, &tmp);
            x -= 1;
            y -= 1;
        }
    }
    return try result.toOwnedSlice(allocator);
}

const testing = std.testing;

test lcs {
    const data_array = [_]struct { a: []const u8, b: []const u8, expected: []const u8 }{
        .{ .a = "", .b = "", .expected = "" },
        .{ .a = "", .b = "other", .expected = "" },
        .{ .a = "other", .b = "", .expected = "" },
        .{ .a = "a1b2c3d4e5", .b = "12345", .expected = "12345" },
        .{ .a = "12345", .b = "a1b2c3d4e5", .expected = "12345" },
        .{ .a = "raisethysword", .b = "rosettacode", .expected = "rsetod" },
        .{ .a = "rosettacode", .b = "raisethysword", .expected = "rsetod" },
        .{ .a = "testing123testing", .b = "thisisatest", .expected = "tsitest" },
        .{ .a = "thisisatest", .b = "testing123testing", .expected = "tsitest" },
    };

    for (data_array) |test_data| {
        const result = try lcs(testing.allocator, test_data.a, test_data.b);
        defer testing.allocator.free(result);

        try testing.expectEqualStrings(test_data.expected, result);
    }
}

// /// Caller owns returned slice memory.
// fn longestCommonSubsequence(allocator: mem.Allocator, a: []const u8, b: []const u8) ![]u8 {
//     var lengths = try Matrix.init(allocator, a.len + 1, b.len + 1);
//     defer lengths.deinit();
//
//     for (a, 0..) |x, i|
//         for (b, 0..) |y, j| {
//             if (x == y)
//                 lengths.set(i + 1, j + 1).* = lengths.at(i, j) + 1
//             else
//                 lengths.set(i + 1, j + 1).* = @max(lengths.at(i + 1, j), lengths.at(i, j + 1));
//         };
//
//     var i = a.len;
//     var j = b.len;
//     var reversed:std.ArrayList(u8) = try .initCapacity(allocator, lengths.at(i, j));
//     while (i != 0 and j != 0) {
//         if (lengths.at(i, j) == lengths.at(i - 1, j))
//             i -= 1
//         else if (lengths.at(i, j) == lengths.at(i, j - 1))
//             j -= 1
//         else {
//             assert(a[i - 1] == b[j - 1]);
//             try reversed.append(a[i - 1]);
//             i -= 1;
//             j -= 1;
//         }
//     }
//
//     const result = try reversed.toOwnedSlice();
//     mem.reverse(u8, result);
//     return result;
// }
//
// const Matrix = struct {
//     data: []u8 = undefined,
//     allocator: mem.Allocator,
//     m: usize,
//     n: usize, // not read
//
//     fn init(allocator: mem.Allocator, m: usize, n: usize) !Matrix {
//         const data = try allocator.alloc(u8, m * n);
//         // simple to zero entirety
//         // (for lcs only row 0 and column 0 need to be zeroed)
//         @memset(data, 0);
//         return Matrix{
//             .data = data,
//             .allocator = allocator,
//             .m = m,
//             .n = n,
//         };
//     }
//     fn deinit(self: *Matrix) void {
//         self.allocator.free(self.data);
//     }
//     fn set(self: *Matrix, i: usize, j: usize) *u8 {
//         return &self.data[i + j * self.m];
//     }
//     fn at(self: *const Matrix, i: usize, j: usize) u8 {
//         return self.data[i + j * self.m];
//     }
// };
