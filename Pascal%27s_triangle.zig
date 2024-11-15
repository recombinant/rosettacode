// https://rosettacode.org/wiki/Pascal%27s_triangle
const std = @import("std");
const mem = std.mem;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const writer = std.io.getStdOut().writer();

    try printPascalsTriangle(allocator, writer, 17);
}

/// Pretty print Pascal's Triangle. The triangle is created as
/// strings so that the length of the final line is known for
/// calculating the padding necessary to center all the lines.
fn printPascalsTriangle(allocator: mem.Allocator, writer: anytype, n: u8) !void {
    // The triangle as numbers
    var triangle1 = try allocator.alloc([]u64, n);
    defer {
        for (triangle1) |row| allocator.free(row);
        allocator.free(triangle1);
    }
    triangle1[0] = try allocator.alloc(u64, 1);
    triangle1[0][0] = 1;
    for (triangle1[1..], 1..) |*row, i| {
        row.* = try allocator.alloc(u64, i + 1);
        @memset(row.*, 0);
        const prev_row = triangle1[i - 1];
        for (prev_row, 0..) |value, j| {
            row.*[j] += value;
            row.*[j + 1] += value;
        }
    }
    // The triangle as strings
    var triangle2 = try allocator.alloc([]const u8, n);
    defer {
        for (triangle2) |line|
            allocator.free(line);
        allocator.free(triangle2);
    }
    for (triangle1, 0..) |values, i| {
        var line = std.ArrayList(u8).init(allocator);
        var line_writer = line.writer();
        for (values, 0..) |value, j| {
            if (j != 0)
                try line_writer.writeByte(' ');
            try line_writer.print("{d}", .{value});
        }
        triangle2[i] = try line.toOwnedSlice();
    }
    // Pretty print the triangle
    const half_len = triangle2[triangle2.len - 1].len / 2;
    for (triangle2) |line| {
        try writer.writeByteNTimes(' ', half_len - line.len / 2);
        try writer.writeAll(line);
        try writer.writeByte('\n');
    }
}
