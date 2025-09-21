// https://rosettacode.org/wiki/Gradient_descent
// {{works with|Zig|0.15.1}}
// {{trans|Go}}
const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const tolerance: f64 = 0.0000006;
    const alpha: f64 = 0.1;

    // Initial guesses of location of minimums
    var x = [2]f64{ 0.1, -1 };

    try steepestDescent(allocator, &x, alpha, tolerance);

    print("Testing steepest descent method\n", .{});
    print("The minimum is at x = {d:.6}, y = {d:.6} for which f(x, y) = {d:.6}\n", .{ x[0], x[1], g(&x) });
}

/// Using the steepest-descent method to search
/// for minimum values of a multi-variable function
fn steepestDescent(allocator: std.mem.Allocator, x: []f64, alpha_: f64, tolerance: f64) !void {
    var alpha = alpha_;
    var g0 = g(x); // Initial estimate of result.

    // Calculate initial gradient.
    var fi = try gradG(allocator, x);

    // Calculate initial norm.
    var delG: f64 = 0;
    for (fi) |fi_|
        delG += fi_ * fi_;

    delG = std.math.sqrt(delG);
    var b = alpha / delG;

    // Iterate until value is <= tolerance.
    while (delG > tolerance) {
        // Calculate next value.
        for (x, fi) |*x_, fi_|
            x_.* -= b * fi_;

        allocator.free(fi);
        // Calculate next gradient.
        fi = try gradG(allocator, x);

        // Calculate next norm.
        delG = 0;
        for (fi) |fi_|
            delG += fi_ * fi_;

        delG = std.math.sqrt(delG);
        b = alpha / delG;

        // Calculate next value.
        const g1 = g(x);

        // Adjust parameter.
        if (g1 > g0)
            alpha /= 2
        else
            g0 = g1;
    }
    allocator.free(fi);
}

/// Provides a rough calculation of gradient g(p).
fn gradG(allocator: std.mem.Allocator, p: []const f64) ![]const f64 {
    const z: []f64 = try allocator.alloc(f64, p.len);
    const x = p[0];
    const y = p[1];
    z[0] = 2 * (x - 1) * std.math.exp(-y * y) -
        4 * x * std.math.exp(-2 * x * x) * y * (y + 2);

    z[1] = -2 * (x - 1) * (x - 1) * y * std.math.exp(-y * y) +
        std.math.exp(-2 * x * x) * (y + 2) +
        std.math.exp(-2 * x * x) * y;
    return z;
}

/// Method to provide function g(x).
fn g(x: []f64) f64 {
    return (x[0] - 1) * (x[0] - 1) * std.math.exp(-x[1] * x[1]) +
        x[1] * (x[1] + 2) * std.math.exp(-2 * x[0] * x[0]);
}
