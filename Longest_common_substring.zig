// https://rosettacode.org/wiki/Longest_common_substring
// {{works with|Zig|0.16.0}}

// from the Go and Java examples
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;
    // ----------------------------------------------------
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    // --------------------------------------------- stdout
    var t0: Io.Timestamp = .now(io, .real);

    const result1 = try longestCommonSubstringWithAlloc(
        gpa,
        "thisisatest",
        "testing123testing",
    );

    try stdout.writeAll(result1);
    try stdout.writeByte('\n');
    try stdout.flush();
    std.log.info("longestCommonSubstringWithAlloc() processed in {f}", .{t0.untilNow(io, .real)});

    var t1: Io.Timestamp = .now(io, .real);

    const result2 = longestCommonSubstring(
        "thisisatest",
        "testing123testing",
    );

    try stdout.writeAll(result2);
    try stdout.writeByte('\n');
    try stdout.flush();
    std.log.info("longestCommonSubstring() processed in {f}", .{t1.untilNow(io, .real)});
}

fn longestCommonSubstringWithAlloc(allocator: Allocator, a: []const u8, b: []const u8) ![]const u8 {
    var result: []const u8 = "";
    var lengths = try allocator.alloc(usize, a.len * b.len); // lengths matrix
    defer allocator.free(lengths);
    @memset(lengths, 0);
    var max: usize = 0;
    for (a, 0..) |x, i| {
        for (b, 0..) |y, j| {
            if (x == y) {
                const offset = i + j * a.len;
                lengths[offset] = if (i == 0 or j == 0) 1 else lengths[(i - 1) + (j - 1) * a.len] + 1;
                if (lengths[offset] > max) {
                    max = lengths[offset];
                    result = a[(i + 1 - max) .. i + 1];
                }
            }
        }
    }
    return result;
}

fn longestCommonSubstring(a: []const u8, b: []const u8) []const u8 {
    if (a.len == 0 or b.len == 0) return "";

    var result: []const u8 = "";

    for (0..a.len) |i| {
        for (i..a.len + 1) |j| {
            if (result.len >= j - i)
                continue;
            if (std.mem.indexOf(u8, b, a[i..j]) != null)
                result = a[i..j];
        }
    }
    return result;
}

const test_data = [_]struct { a: []const u8, b: []const u8, result: []const u8 }{
    .{ .a = "", .b = "", .result = "" },
    .{ .a = "thisisatest", .b = "testing123testing", .result = "test" },
    .{ .a = "WEASELS", .b = "WARDANCE", .result = "W" },
    .{ .a = "blank", .b = "", .result = "" },
    .{ .a = "", .b = "blank", .result = "" },
    .{ .a = "bookend", .b = "end", .result = "end" },
    .{ .a = "end", .b = "bookend", .result = "end" },
    .{ .a = "start", .b = "startswith", .result = "start" },
    .{ .a = "startswith", .b = "start", .result = "start" },
    .{ .a = "equal", .b = "equal", .result = "equal" },
    .{
        .a = "The quick brown fox jumps over the lazy dog",
        .b = "The quick red fox jumps over the sleeping dog",
        .result = " fox jumps over the ",
    },
};

const testing = std.testing;

test longestCommonSubstring {
    for (test_data) |data| {
        const result = longestCommonSubstring(data.a, data.b);
        try testing.expectEqualStrings(result, data.result);
    }
}

test longestCommonSubstringWithAlloc {
    const allocator = testing.allocator;

    for (test_data) |data| {
        const result = try longestCommonSubstringWithAlloc(allocator, data.a, data.b);
        try testing.expectEqualStrings(result, data.result);
    }
}
