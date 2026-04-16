// https://rosettacode.org/wiki/Host_introspection
// {{works with|Zig|0.16.0}}
const std = @import("std");
const builtin = @import("builtin");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("word size  : {}\n", .{@sizeOf(usize)});
    try stdout.print("endianness : {s}\n", .{@tagName(builtin.cpu.arch.endian())});

    try stdout.flush();
}
