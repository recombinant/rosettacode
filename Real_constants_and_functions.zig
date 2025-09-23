// https://rosettacode.org/wiki/Real_constants_and_functions
// {{works with|Zig|0.15.1}}

// Copied from rosettacode
const std = @import("std");

pub fn main() void {
    std.debug.print("e = {d}\n", .{std.math.e});
    std.debug.print("pi = {d}\n", .{std.math.pi});
    // For floating point numbers
    const x: f64 = -1.2345;
    std.debug.print("sqrt(4.0) = {d}\n", .{@sqrt(4.0)});
    std.debug.print("ln(e) = {d}\n", .{@log(std.math.e)});
    std.debug.print("exp(x) = {d}\n", .{@exp(x)});
    std.debug.print("abs(x) = {d}\n", .{@abs(x)});
    std.debug.print("floor(x) = {d}\n", .{@floor(x)});
    std.debug.print("ceil(x) = {d}\n", .{@ceil(x)});
    std.debug.print("pow(f64, -x, x) = {d}\n", .{std.math.pow(f64, -x, x)});
    // For integers
    const n: u64 = 42;
    std.debug.print("sqrt(n) = {d}\n", .{std.math.sqrt(n)});
    std.debug.print("ln(n) = {d}\n", .{@as(u64, @intFromFloat(@log(@as(f64, @floatFromInt(n)))))});
    std.debug.print("exp(n) = {d}\n", .{@as(u64, @intFromFloat(@exp(@as(f64, @floatFromInt(n)))))});
    std.debug.print("abs(n) = {d}\n", .{@abs(n)});
    std.debug.print("pow(i64, n, 3) = {d}\n", .{std.math.pow(i64, n, 3)});
}
