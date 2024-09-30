// https://rosettacode.org/wiki/Gaussian_elimination
// Translation of C
const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const assert = std.debug.assert;

pub fn main() !void {
    const b = [_]f128{ -0.01, 0.61, 0.91, 0.99, 0.60, 0.02 };
    const a = [b.len * b.len]f128{
        1.00, 0.00, 0.00, 0.00,  0.00,  0.00,
        1.00, 0.63, 0.39, 0.25,  0.16,  0.10,
        1.00, 1.26, 1.58, 1.98,  2.49,  3.13,
        1.00, 1.88, 3.55, 6.70,  12.62, 23.80,
        1.00, 2.51, 6.32, 15.88, 39.90, 100.28,
        1.00, 3.14, 9.87, 31.01, 97.41, 306.02,
    };
    var matrix = Matrix(f128, 6){ .a = a };

    const x: [b.len]f128 = matrix.gaussEliminate(&b);

    const stdout = std.io.getStdOut().writer();
    for (x) |value|
        try stdout.print("{d}\n", .{@as(f64, @floatCast(value))});
}

/// Simple n x n square matrix.
fn Matrix(comptime T: type, comptime n: usize) type {
    return struct {
        const Self = @This();
        a: [n * n]T,

        fn at(self: *Self, y: usize, x: usize) T {
            return self.a[y * n + x];
        }

        fn atPtr(self: *Self, y: usize, x: usize) *T {
            return &self.a[y * n + x];
        }

        fn gaussEliminate(self: *Self, b_: *const [n]T) [n]T {
            assert(b_.len == n);
            var b: [n]T = b_.*;

            for (0..n) |dia| {
                var max_row = dia;
                var max_val = @abs(self.at(max_row, dia));
                for (dia + 1..n) |row| {
                    const val = @abs(self.at(row, dia));
                    if (val > max_val) {
                        max_row = row;
                        max_val = val;
                    }
                }

                self.swapRow(&b, dia, max_row);

                for (dia + 1..n) |row| {
                    const f = self.at(row, dia) / self.at(dia, dia);
                    for (dia + 1..n) |col|
                        self.atPtr(row, col).* -= f * self.at(dia, col);
                    self.atPtr(row, dia).* = 0;
                    b[row] -= f * b[dia];
                }
            }
            // self.a is now in row echelon form.
            // Perform back substitution.
            var x: [n]T = undefined;
            var row = n;
            while (row > 0) {
                row -= 1;
                var f = b[row];
                var col = n;
                while (col > row) {
                    col -= 1;
                    f -= x[col] * self.at(row, col);
                }
                assert(row == col);
                x[row] = f / self.at(row, col);
            }
            return x;
        }

        fn swapRow(self: *Self, b: []T, r1: usize, r2: usize) void {
            if (r1 == r2) return;

            for (0..n) |col| {
                const p1 = self.atPtr(r1, col);
                const p2 = self.atPtr(r2, col);
                mem.swap(T, p1, p2);
            }
            mem.swap(T, &b[r1], &b[r2]);
        }
    };
}

test "swap row" {
    const a = [9]u8{
        1, 2, 3,
        4, 5, 6,
        7, 8, 9,
    };
    var b = [3]u8{ 10, 11, 12 };
    var matrix = Matrix(u8, 3){ .a = a };

    matrix.swapRow(&b, 0, 0);
    try testing.expectEqual(matrix.a, a);
    try testing.expectEqual(b, [3]u8{ 10, 11, 12 });

    matrix.swapRow(&b, 0, 1);
    try testing.expectEqual(matrix.a, [9]u8{ 4, 5, 6, 1, 2, 3, 7, 8, 9 });
    try testing.expectEqual(b, [3]u8{ 11, 10, 12 });

    matrix.swapRow(&b, 0, 1);
    try testing.expectEqual(matrix.a, a);
    try testing.expectEqual(b, [3]u8{ 10, 11, 12 });

    matrix.swapRow(&b, 2, 1);
    try testing.expectEqual(matrix.a, [9]u8{ 1, 2, 3, 7, 8, 9, 4, 5, 6 });
    try testing.expectEqual(b, [3]u8{ 10, 12, 11 });
}

test "at" {
    const a = [4]u8{
        1, 2,
        3, 4,
    };
    var matrix = Matrix(u8, 2){ .a = a };
    try testing.expectEqual(matrix.at(0, 0), 1);
    try testing.expectEqual(matrix.at(0, 1), 2);
    try testing.expectEqual(matrix.at(1, 0), 3);
    try testing.expectEqual(matrix.at(1, 1), 4);
}

test "atPtr" {
    const a = [4]u8{
        1, 2,
        3, 4,
    };
    var matrix = Matrix(u8, 2){ .a = a };

    try testing.expectEqual(matrix.atPtr(0, 0).*, 1);
    try testing.expectEqual(matrix.atPtr(0, 1).*, 2);
    try testing.expectEqual(matrix.atPtr(1, 0).*, 3);
    try testing.expectEqual(matrix.atPtr(1, 1).*, 4);

    matrix.atPtr(0, 1).* = 5;
    matrix.atPtr(1, 0).* = 6;
    try testing.expectEqual(matrix.at(0, 1), 5);
    try testing.expectEqual(matrix.at(1, 0), 6);
}

test "gauss eliminate" {
    var b = [_]f32{ -1, -7, -6 };
    const a = [b.len * b.len]f32{
        -3, 2,  -1,
        6,  -6, 7,
        3,  -4, 4,
    };
    var matrix = Matrix(f32, 3){ .a = a };
    const x: [b.len]f32 = matrix.gaussEliminate(&b);
    // TODO: This is floating point, so may not work with
    //       all targets.
    try testing.expectEqual([_]f32{ 2, 2, -1 }, x);
}

// var b = [_]f64{ 8, -11, -3 };
// var a = [b.len * b.len]f64{
//     2,  1,  -1,
//     -3, -1, 2,
//     -2, 1,  2,
// };
// var matrix = Matrix(f64, 3){ .a = a };
// var x: [b.len]f64 = matrix.gaussEliminate(&b);
