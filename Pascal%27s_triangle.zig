// https://rosettacode.org/wiki/Pascal%27s_triangle
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try printPascalsTriangle(allocator, stdout, 17);

    try stdout.flush();
}

/// Pretty print Pascal's Triangle. The triangle is created as
/// strings so that the length of the final line is known for
/// calculating the padding necessary to center all the lines.
fn printPascalsTriangle(allocator: std.mem.Allocator, w: *std.Io.Writer, n: u8) !void {
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
        var line: std.Io.Writer.Allocating = .init(allocator);
        defer line.deinit();
        for (values, 0..) |value, j| {
            if (j != 0)
                try line.writer.writeByte(' ');
            try line.writer.print("{d}", .{value});
        }
        triangle2[i] = try line.toOwnedSlice();
    }
    // Pretty print the triangle
    const half_len = triangle2[triangle2.len - 1].len / 2;
    for (triangle2) |line| {
        _ = try w.splatByte(' ', half_len - line.len / 2);
        try w.writeAll(line);
        try w.writeByte('\n');
    }
}
