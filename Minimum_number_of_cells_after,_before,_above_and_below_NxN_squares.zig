// https://rosettacode.org/wiki/Minimum_number_of_cells_after,_before,_above_and_below_NxN_squares
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try minab(stdout, 10);

    try stdout.flush();
}

fn minab(w: *std.Io.Writer, n: usize) !void {
    try w.print("Minimum number of cells after, before, above and below {} x {} square:\n", .{ n, n });

    for (0..n) |i| {
        for (0..n) |j|
            try w.print("{d:2} ", .{@min(@min(i, n - 1 - i), @min(j, n - 1 - j))});
        try w.writeByte('\n');
    }
}
