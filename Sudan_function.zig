// https://rosettacode.org/wiki/Sudan_function

// requires utf-8 terminal for printing to work.

const std = @import("std");

fn sudan(n: u64, x: u64, y: u64) u64 {
    if (n == 0) return x + y;
    if (y == 0) return x;
    const z = sudan(n, x, y - 1);
    return sudan(n - 1, z, z + y);
}

const SudanError = error{
    PrintableSubscriptOutOfRange,
};

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    const parameters = [_]struct { n: u64, x: u64, y: u64 }{
        .{ .n = 0, .x = 0, .y = 0 }, .{ .n = 1, .x = 1, .y = 1 },
        .{ .n = 2, .x = 1, .y = 1 }, .{ .n = 2, .x = 2, .y = 1 },
        .{ .n = 2, .x = 2, .y = 2 }, .{ .n = 3, .x = 1, .y = 1 },
    };

    for (parameters) |p| {
        if (p.n > 9)
            return SudanError.PrintableSubscriptOutOfRange;

        // select subscript for printing (₀ to ₉)
        const subscript_n: []const u8 = &[3]u8{ 0xe2, 0x82, 0x80 + @as(u8, @truncate(p.n)) };

        _ = try stdout.print(
            "F{s}({d}, {d}) = {d}\n",
            .{ subscript_n, p.x, p.y, sudan(p.n, p.x, p.y) },
        );
    }
}
