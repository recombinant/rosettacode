// https://rosettacode.org/wiki/Numerical_integration/Romberg_integration
// {{works with|Zig|0.17.1}}
// {{trans|Rust}}
// copied from rosettacode and tweaked
const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;

pub fn main(init: std.process.Init) !void {
    const allocator: Allocator = init.gpa;

    const result1 = try rombergIntegration(
        allocator,
        sinFunction,
        0.0,
        1.0,
        10,
        1e-9,
    );

    print("Integral = {d:.8} (converged at depth {d})\n", .{ result1.result, result1.depth });

    const result2 = try rombergIntegration(
        allocator,
        expFunction,
        -3.0,
        3.0,
        10,
        1e-8,
    );

    print("Integral = {d:.7} (converged at depth {d})\n", .{ result2.result, result2.depth });
}

const InvalidArgumentError = error{
    InvalidMaxDepth,
};

const RombergResult = struct {
    result: f64,
    depth: usize,
};

fn rombergIntegration(
    allocator: Allocator,
    comptime func: fn (f64) f64,
    a_input: f64,
    b_input: f64,
    max_depth: usize,
    tol: f64,
) !RombergResult {
    if (max_depth < 1)
        return InvalidArgumentError.InvalidMaxDepth;

    var a = a_input;
    var b = b_input;

    if (a == b)
        return .{ .result = 0.0, .depth = 0 };

    if (a > b)
        std.mem.swap(f64, &a, &b);

    // Create 2D array for Romberg table
    var r = try allocator.alloc([]f64, max_depth + 1);
    defer allocator.free(r);

    for (r) |*row|
        row.* = try allocator.alloc(f64, max_depth + 1);

    defer {
        for (r) |row|
            allocator.free(row);
    }

    // Initialize first element
    r[0][0] = 0.5 * (b - a) * (func(a) + func(b));
    var h = b - a;

    for (1..max_depth + 1) |i| {
        h /= 2.0;
        var sum: f64 = 0.0;
        const num_new_points = @as(usize, 1) << @intCast(i - 1);

        for (1..num_new_points + 1) |k| {
            const x = a + @as(f64, @floatFromInt(2 * k - 1)) * h;
            sum += func(x);
        }

        r[i][0] = 0.5 * r[i - 1][0] + sum * h;

        for (1..i + 1) |j| {
            const factor = std.math.pow(f64, 4.0, @as(f64, @floatFromInt(j)));
            r[i][j] = (factor * r[i][j - 1] - r[i - 1][j - 1]) / (factor - 1.0);
        }

        if (@abs(r[i][i] - r[i - 1][i - 1]) < tol)
            return RombergResult{ .result = r[i][i], .depth = i };
    }

    return RombergResult{ .result = r[max_depth][max_depth], .depth = max_depth };
}

fn sinFunction(x: f64) f64 {
    return @sin(x);
}

fn expFunction(x: f64) f64 {
    return @exp(x);
}
