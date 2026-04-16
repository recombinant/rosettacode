// https://rosettacode.org/wiki/Generic_swap
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;

/// Copy of std.mem.swap
fn swap(T: type, a: *T, b: *T) void {
    const tmp = a.*;
    a.* = b.*;
    b.* = tmp;
}

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var a: []const u8 = "hello";
    var b: []const u8 = "world";

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("{s} {s}\n", .{ a, b });

    swap([]const u8, &a, &b);
    try stdout.print("{s} {s}\n", .{ a, b });

    swap([]const u8, &a, &b);
    try stdout.print("{s} {s}\n", .{ a, b });

    try stdout.flush();
}
