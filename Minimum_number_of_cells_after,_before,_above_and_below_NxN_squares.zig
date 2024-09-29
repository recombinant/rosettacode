// https://rosettacode.org/wiki/Minimum_number_of_cells_after,_before,_above_and_below_NxN_squares
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try minab(stdout, 10);
}

fn minab(writer: anytype, n: usize) !void {
    try writer.print("Minimum number of cells after, before, above and below {} x {} square:\n", .{ n, n });

    for (0..n) |i| {
        for (0..n) |j|
            try writer.print("{d:2} ", .{@min(@min(i, n - 1 - i), @min(j, n - 1 - j))});
        try writer.print("\n", .{});
    }
}
