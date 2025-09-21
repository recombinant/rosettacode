// https://rosettacode.org/wiki/Host_introspection
// {{works with|Zig|0.15.1}}
const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("word size  : {}\n", .{@sizeOf(usize)});
    try stdout.print("endianness : {s}\n", .{@tagName(builtin.cpu.arch.endian())});

    try stdout.flush();
}
