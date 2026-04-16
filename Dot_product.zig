// https://rosettacode.org/wiki/Dot_product
// {{works with|Zig|0.16.0}}
// Copied from rosettacode
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    const a = @Vector(3, i32){ 1, 3, -5 };
    const b = @Vector(3, i32){ 4, -2, -1 };
    const dot: i32 = @reduce(.Add, a * b);

    try stdout.print("{d}\n", .{dot});

    try stdout.flush();
}
