// https://rosettacode.org/wiki/Extreme_floating_point_values
const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const inf: f64 = std.math.floatMax(f64) / std.math.floatMin(f64);
    const minus_inf: f64 = -std.math.floatMax(f64) / std.math.floatMin(f64);
    const zero: f64 = 0.0;
    const minus_zero: f64 = -zero;
    const nan: f64 = zero * inf;
    const minus_nan: f64 = inf + minus_inf;

    print("positive infinity: {d}\n", .{inf});
    print("negative infinity: {d}\n", .{minus_inf});
    print("negative zero: {d}\n", .{minus_zero});
    print("not a number: {d}\n", .{nan});
    print("negative not a number: {d}\n", .{minus_nan});

    // some arithmetic

    print("+inf + 2.0 = {d}\n", .{inf + 2.0});
    print("+inf - 10.1 = {d}\n", .{inf - 10.1});
    print("+inf + -inf = {d}\n", .{inf + minus_inf});
    print("0.0 * +inf = {d}\n", .{0.0 * inf});
    print("1.0/-0.0 = {d}\n", .{1.0 / minus_zero});
    print("NaN + 1.0 = {d}\n", .{nan + 1.0});
    print("NaN + NaN = {d}\n", .{nan + nan});
    print("-NaN - 1.0 = {d}\n", .{minus_nan + 1.0});
    print("-NaN + -NaN = {d}\n", .{minus_nan + minus_nan});

    // some comparisons

    print("NaN == NaN = {}\n", .{nan == nan});
    print("-NaN == -NaN = {}\n", .{minus_nan == minus_nan});
    print("+inf == +inf = {}\n", .{inf == inf});
    print("-inf == -inf = {}\n", .{minus_inf == minus_inf});
    print("+inf == -(-inf) = {}\n", .{inf == -(minus_inf)});
    print("-inf == -(+inf) = {}\n", .{minus_inf == -(inf)});
    print("0.0 == -0.0 = {}\n", .{0.0 == minus_zero});

    // print("isFinite(+inf) = {}\n", .{std.math.isFinite(inf)});
    // print("isFinite(-inf) = {}\n", .{std.math.isFinite(minus_inf)});
    // print("isFinite(+0) = {}\n", .{std.math.isFinite(zero)});
    // print("isFinite(-0) = {}\n", .{std.math.isFinite(minus_zero)});
    // print("isInf(+inf) = {}\n", .{std.math.isInf(inf)});
    // print("isInf(-inf) = {}\n", .{std.math.isInf(minus_inf)});
    // print("isPositiveInf(+inf) = {}\n", .{std.math.isPositiveInf(inf)});
    // print("isNegativeInf(-inf) = {}\n", .{std.math.isNegativeInf(minus_inf)});
    // print("isPositiveZero(0) = {}\n", .{std.math.isPositiveZero(zero)});
    // print("isNegativeZero(-0) = {}\n", .{std.math.isNegativeZero(minus_zero)});
}
