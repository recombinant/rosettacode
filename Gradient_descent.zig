// https://rosettacode.org/wiki/Gradient_descent
// Translated from Go
const std = @import("std");
const math = std.math;
const mem = std.mem;
const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
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
fn steepestDescent(allocator: mem.Allocator, x: []f64, alpha_: f64, tolerance: f64) !void {
    var alpha = alpha_;
    var g0 = g(x); // Initial estimate of result.

    // Calculate initial gradient.
    var fi = try gradG(allocator, x);

    // Calculate initial norm.
    var delG: f64 = 0;
    for (fi) |fi_|
        delG += fi_ * fi_;

    delG = math.sqrt(delG);
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

        delG = math.sqrt(delG);
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
fn gradG(allocator: mem.Allocator, p: []const f64) ![]const f64 {
    const z: []f64 = try allocator.alloc(f64, p.len);
    const x = p[0];
    const y = p[1];
    z[0] = 2 * (x - 1) * math.exp(-y * y) -
        4 * x * math.exp(-2 * x * x) * y * (y + 2);

    z[1] = -2 * (x - 1) * (x - 1) * y * math.exp(-y * y) +
        math.exp(-2 * x * x) * (y + 2) +
        math.exp(-2 * x * x) * y;
    return z;
}

/// Method to provide function g(x).
fn g(x: []f64) f64 {
    return (x[0] - 1) * (x[0] - 1) * math.exp(-x[1] * x[1]) +
        x[1] * (x[1] + 2) * math.exp(-2 * x[0] * x[0]);
}
