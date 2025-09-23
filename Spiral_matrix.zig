// https://rosettacode.org/wiki/Spiral_matrix
// {{works with|Zig|0.15.1}}
// {{trans|Python}}
const std = @import("std");

pub fn main() void {
    for (spiral_matrix(5)) |i|
        std.debug.print("{any:2}\n", .{i});
}

fn spiral_matrix(comptime n: usize) [n][n]usize {
    var m: [n][n]usize = undefined;
    for (&m) |*row|
        @memset(row, 0);

    // for use with wraparound arithmetic
    const neg_one: usize = @bitCast(@as(isize, -1));

    const dx = [4]usize{ 0, 1, 0, neg_one };
    const dy = [4]usize{ 1, 0, neg_one, 0 };
    var x, var y, var c = [_]usize{ 0, neg_one, 1 };
    for (0..n + n - 1) |i|
        for (0..(n + n - i) / 2) |_| {
            x +%= dx[i % 4];
            y +%= dy[i % 4];
            m[x][y] = c;
            c += 1;
        };
    return m;
}
