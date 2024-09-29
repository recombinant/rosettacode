// https://rosettacode.org/wiki/CRC-32
// from https://github.com/tiehuis/zig-rosetta
const std = @import("std");
const hash = std.hash;
const print = std.debug.print;

pub fn main() void {
    const s = "The quick brown fox jumps over the lazy dog";
    print("{x}\n", .{hash.Crc32.hash(s)});
}
