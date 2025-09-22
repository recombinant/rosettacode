// https://rosettacode.org/wiki/Shortest_common_supersequence
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    // ------------------------------------------ allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ------------------------------------------------ scs
    const seq1 = "abcbdab";
    const seq2 = "abdcaba";
    const result = try shortestCommonSupersequence(allocator, seq1, seq2);
    defer allocator.free(result);
    // ---------------------------------------------- print
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("{s}\n", .{result});

    try stdout.flush();
}

fn shortestCommonSupersequence(allocator: std.mem.Allocator, u: []const u8, v: []const u8) ![]u8 {
    const lcs = try longestCommonSubsequence(allocator, u, v);
    defer allocator.free(lcs);
    var ui: usize = 0;
    var vi: usize = 0;
    var result: std.ArrayList(u8) = .empty;
    for (lcs) |ch| {
        while (ui < u.len and u[ui] != ch) {
            try result.append(allocator, u[ui]);
            ui += 1;
        }
        while (vi < v.len and v[vi] != ch) {
            try result.append(allocator, v[vi]);
            vi += 1;
        }
        try result.append(allocator, ch);
        ui += 1;
        vi += 1;
    }
    if (ui < u.len) try result.appendSlice(allocator, u[ui..]);
    if (vi < v.len) try result.appendSlice(allocator, v[vi..]);

    return result.toOwnedSlice(allocator);
}

/// Caller owns returned slice memory.
fn longestCommonSubsequence(allocator: std.mem.Allocator, a: []const u8, b: []const u8) ![]u8 {
    var lengths = try Matrix.init(allocator, a.len + 1, b.len + 1);
    defer lengths.deinit();

    for (a, 0..) |x, i| {
        for (b, 0..) |y, j| {
            if (x == y)
                lengths.set(i + 1, j + 1).* = lengths.at(i, j) + 1
            else
                lengths.set(i + 1, j + 1).* = @max(lengths.at(i + 1, j), lengths.at(i, j + 1));
        }
    }

    var i = a.len;
    var j = b.len;
    var reversed: std.ArrayList(u8) = try .initCapacity(allocator, lengths.at(i, j));
    while (i != 0 and j != 0) {
        if (lengths.at(i, j) == lengths.at(i - 1, j))
            i -= 1
        else if (lengths.at(i, j) == lengths.at(i, j - 1))
            j -= 1
        else {
            std.debug.assert(a[i - 1] == b[j - 1]);
            try reversed.append(allocator, a[i - 1]);
            i -= 1;
            j -= 1;
        }
    }

    const result = try reversed.toOwnedSlice(allocator);
    std.mem.reverse(u8, result);
    return result;
}

const Matrix = struct {
    data: []u8 = undefined,
    allocator: std.mem.Allocator,
    m: usize,
    n: usize, // not read

    fn init(allocator: std.mem.Allocator, m: usize, n: usize) !Matrix {
        const data = try allocator.alloc(u8, m * n);
        // simple to zero entirety (only row 0 and column 0 need to be zeroed)
        @memset(data, 0);
        return Matrix{
            .data = data,
            .allocator = allocator,
            .m = m,
            .n = n,
        };
    }
    fn deinit(self: *Matrix) void {
        self.allocator.free(self.data);
    }
    fn set(self: *Matrix, i: usize, j: usize) *u8 {
        return &self.data[i + j * self.m];
    }
    fn at(self: *const Matrix, i: usize, j: usize) u8 {
        return self.data[i + j * self.m];
    }
};

const testing = std.testing;

test "shortest common super sequence" {
    const allocator = testing.allocator;

    {
        const a = "abcbdab";
        const b = "abdcaba";
        const result = try shortestCommonSupersequence(allocator, a, b);
        defer allocator.free(result);

        try testing.expectEqualStrings("abdcabdab", result);
    }
    {
        const a = "WEASELS";
        const b = "WARDANCE";
        const result = try shortestCommonSupersequence(allocator, a, b);
        defer allocator.free(result);

        try testing.expectEqualStrings("WEASRDANCELS", result);
    }
}
