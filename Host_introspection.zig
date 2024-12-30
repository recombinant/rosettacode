// https://rosettacode.org/wiki/Host_introspection
const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    const writer = std.io.getStdOut().writer();

    try writer.print("word size  : {}\n", .{@sizeOf(usize)});
    try writer.print("endianness : {s}\n", .{@tagName(builtin.cpu.arch.endian())});
}
