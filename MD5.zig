// https://rosettacode.org/wiki/MD5
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;
const Md5 = std.crypto.hash.Md5;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var buf: [Md5.digest_length]u8 = undefined;
    Md5.hash("The quick brown fox jumped over the lazy dog's back", buf[0..], .{});

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    for (buf) |c|
        try stdout.print("{x}", .{c});
    try stdout.writeByte('\n');

    try stdout.flush();
}
