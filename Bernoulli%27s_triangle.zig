// https://rosettacode.org/wiki/Bernoulli%27s_triangle
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const ROWS = 15;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;
    const gpa: Allocator = init.gpa;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout: *Io.Writer = &stdout_writer.interface;

    var row: std.ArrayList(u32) = try .initCapacity(gpa, ROWS);
    defer row.deinit(gpa);

    var prev_row: std.ArrayList(u32) = try .initCapacity(gpa, ROWS);
    defer prev_row.deinit(gpa);

    for (0..ROWS) |n| {
        row.clearRetainingCapacity();

        for (0..n + 1) |k| {
            if (k == 0)
                row.appendAssumeCapacity(1)
            else if (k < n)
                row.appendAssumeCapacity(prev_row.items[k] + prev_row.items[k - 1])
            else
                row.appendAssumeCapacity(std.math.shl(u32, 1, n));
        }

        for (row.items) |item|
            try stdout.print(" {d:>5}", .{item});
        try stdout.writeByte('\n');

        std.mem.swap(std.ArrayList(u32), &row, &prev_row);
    }
    try stdout.flush();
}
