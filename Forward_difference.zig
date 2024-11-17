// https://rosettacode.org/wiki/Forward_difference
//
// Original C binomCoeff example trundles off the end of the array with k + j
//
const std = @import("std");
const mem = std.mem;

pub fn main() !void {
    try main1();
    try main2();
}

// --------------------------------------------------------------

pub fn main1() !void {
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const x: []const f64 = &[_]f64{ 90, 47, 58, 29, 22, 32, 55, 5, 55, 73 };

    for (0..x.len) |p| {
        const y = try fwdDiff(allocator, x, p);
        defer allocator.free(y);
        for (y) |n|
            try stdout.print("{d:5} ", .{n});
        try stdout.writeByte('\n');
    }

    try stdout.writeByte('\n');
}

const FwdDiffError = error{
    OrderTooHigh,
};

fn fwdDiff(allocator: mem.Allocator, x_: []const f64, order: usize) ![]f64 {
    // handle two special cases
    if (order >= x_.len) return FwdDiffError.OrderTooHigh;

    var y = try allocator.dupe(f64, x_);
    if (order == 0) return y;

    var len = x_.len;
    var x2 = x_;
    // first order diff goes from x->y, later ones go from y->y
    for (0..order) |_| {
        len -= 1;
        for (0..len) |i|
            y[i] = x2[i + 1] - x2[i];
        x2 = y;
    }
    return try allocator.realloc(y, len);
}

fn binomCoeff(allocator: mem.Allocator, n: i32) ![]i32 {
    var b = try allocator.alloc(i32, 1 + @as(usize, @intCast(n)));
    b[0] = if (@rem(n, 2) == 0) 1 else -1;

    var j: usize = 1;
    while (j <= n) : (j += 1) {
        const jj: i32 = @intCast(j);
        b[j] = @divTrunc(-b[j - 1] * (n + 1 - jj), jj);
    }

    return b;
}

// --------------------------------------------------------------
/// Use method with Pascal triangle, binomial coefficients are pre-computed
pub fn main2() !void {
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const original = [_]f64{ 90, 47, 58, 29, 22, 32, 55, 5, 55, 73 };
    var array: [original.len]f64 = undefined;

    for (0..array.len) |p| {
        @memcpy(&array, &original);
        // pre-compute binomial coefficients for order p
        const b = try binomCoeff(allocator, @intCast(p));
        defer allocator.free(b);

        // compute p-th difference
        for (0..array.len) |k| {
            array[k] *= @as(f64, @floatFromInt(b[0]));
            var j: usize = 1;
            while (j <= p) : (j += 1) {
                if (k + j < array.len)
                    array[k] += @as(f64, @floatFromInt(b[j])) * array[k + j];
            }
        }

        // resulting series is shorter by p elements
        for (array[0 .. array.len - p]) |n|
            try stdout.print("{d:5} ", .{n});
        try stdout.writeByte('\n');
    }
}
