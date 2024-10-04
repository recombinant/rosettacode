// https://rosettacode.org/wiki/Longest_increasing_subsequence
// Based on O(n log n) method from wikipedia
// https://en.wikipedia.org/wiki/Longest_increasing_subsequence#Efficient_algorithms
const std = @import("std");
const heap = std.heap;
const mem = std.mem;

const print = std.debug.print;

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const data = [2][]const u4{
        &[_]u4{ 3, 2, 6, 4, 5, 1 },
        &[_]u4{ 0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15 },
    };

    for (data) |d| {
        const lis = try getLongestIncreasingSubsequence(allocator, u4, d);
        defer allocator.free(lis);
        print("a L.I.S. of {any} is {any}\n", .{ d, lis });
    }
}

/// Caller owns returned slice memory.
fn getLongestIncreasingSubsequence(allocator: mem.Allocator, T: type, x: []const T) ![]const T {
    const n = x.len;
    switch (n) {
        0, 1 => return try allocator.dupe(T, x),
        else => {
            var p = try allocator.alloc(usize, n);
            defer allocator.free(p);
            var m = try allocator.alloc(usize, n + 1);
            defer allocator.free(m);

            var len: usize = 0;
            for (0..n) |i| {
                var lo: usize = 1;
                var hi: usize = len;
                while (lo <= hi) {
                    const mid = (lo + hi) / 2;
                    if (x[m[mid]] < x[i])
                        lo = mid + 1
                    else
                        hi = mid - 1;
                }

                const new_len = lo;
                p[i] = m[new_len - 1];
                m[new_len] = i;

                if (new_len > len)
                    len = new_len;
            }
            var s = try allocator.alloc(T, len);
            var k = m[len];
            var i = len;
            while (i != 0) {
                i -= 1;
                s[i] = x[k];
                k = p[k];
            }
            return s;
        },
    }
}

const testing = std.testing;

test getLongestIncreasingSubsequence {
    {
        const array0 = &[0]u1{};
        const lis0 = try getLongestIncreasingSubsequence(testing.allocator, u1, array0);
        defer testing.allocator.free(lis0);
        try testing.expectEqualSlices(u1, array0, lis0);
    }
    {
        const array1 = &[1]u64{18446744073709551615};
        const lis1 = try getLongestIncreasingSubsequence(testing.allocator, u64, array1);
        defer testing.allocator.free(lis1);
        try testing.expectEqualSlices(u64, array1, lis1);
    }
}
