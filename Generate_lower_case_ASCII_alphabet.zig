// https://rosettacode.org/wiki/Generate_lower_case_ASCII_alphabet
// {{works with|Zig|0.16.0}}
// Copied from rosettacode
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    const cnt_lower = 26;
    var lower: [cnt_lower]u8 = undefined;
    comptime var i = 0;
    inline while (i < cnt_lower) : (i += 1)
        lower[i] = i + 'a';

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    for (lower) |l|
        try stdout.print("{c} ", .{l});
    try stdout.writeByte('\n');

    try stdout.flush();
}
