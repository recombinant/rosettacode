// https://rosettacode.org/wiki/Generic_swap
// {{works with|Zig|0.15.1}}
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

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("{s} {s}\n", .{ a, b });

    swap([]const u8, &a, &b);
    try stdout.print("{s} {s}\n", .{ a, b });

    swap([]const u8, &a, &b);
    try stdout.print("{s} {s}\n", .{ a, b });

    try stdout.flush();
}
