// https://rosettacode.org/wiki/MD5
const std = @import("std");
const Md5 = std.crypto.hash.Md5;

pub fn main() !void {
    var buf: [Md5.digest_length]u8 = undefined;
    Md5.hash("The quick brown fox jumped over the lazy dog's back", buf[0..], .{});

    const writer = std.io.getStdOut().writer();
    for (buf) |c|
        try writer.print("{x}", .{c});
    try writer.writeByte('\n');
}
