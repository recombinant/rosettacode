// https://rosettacode.org/wiki/Return_multiple_values
const std = @import("std");

/// Every functions returns one value (or error union).
/// The conventional way to return multiple values is to bundle
/// them into a struct.
fn addsub(x: i32, y: i32) struct { sum: i32, difference: i32 } {
    return .{ .sum = x + y, .difference = x - y };
}

/// Alternatively with an anonymous struct without any
/// field names (a.k.a. tuple).
fn addsub2(x: i32, y: i32) struct { i32, i32 } {
    return .{ x + y, x - y };
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const result = addsub(33, 12);
    try stdout.print("33 + 12 = {d}\n", .{result.sum});
    try stdout.print("33 - 12 = {d}\n\n", .{result.difference});

    const result2 = addsub2(33, 12);
    try stdout.print("33 + 12 = {d}\n", .{result2[0]});
    try stdout.print("33 - 12 = {d}\n\n", .{result2[1]});

    // with aggregate destructuring
    const sum, const difference = addsub2(33, 12);
    try stdout.print("33 + 12 = {d}\n", .{sum});
    try stdout.print("33 - 12 = {d}\n", .{difference});
}
