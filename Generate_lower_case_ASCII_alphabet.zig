// https://rosettacode.org/wiki/Generate_lower_case_ASCII_alphabet
// {{works with|Zig|0.15.1}}
// Copied from rosettacode
const std = @import("std");

pub fn main() !void {
    const cnt_lower = 26;
    var lower: [cnt_lower]u8 = undefined;
    comptime var i = 0;
    inline while (i < cnt_lower) : (i += 1)
        lower[i] = i + 'a';

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    for (lower) |l|
        try stdout.print("{c} ", .{l});
    try stdout.writeByte('\n');

    try stdout.flush();
}
