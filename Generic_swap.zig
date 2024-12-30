// https://rosettacode.org/wiki/Generic_swap
const std = @import("std");

/// Copy of std.mem.swap
fn swap(T: type, a: *T, b: *T) void {
    const tmp = a.*;
    a.* = b.*;
    b.* = tmp;
}

pub fn main() !void {
    var a: []const u8 = "hello";
    var b: []const u8 = "world";

    const writer = std.io.getStdOut().writer();
    try writer.print("{s} {s}\n", .{ a, b });

    swap([]const u8, &a, &b);
    try writer.print("{s} {s}\n", .{ a, b });

    swap([]const u8, &a, &b);
    try writer.print("{s} {s}\n", .{ a, b });
}
