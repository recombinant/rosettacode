// https://rosettacode.org/wiki/Sum_of_first_n_cubes
// {{works with|Zig|0.15.1}}
// Copied from rosettacode
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var sum: u32 = 0;
    var i: u32 = 0;

    while (i < 50) : (i += 1) {
        sum += i * i * i;
        try stdout.print("{d:8}", .{sum});
        if (i % 5 == 4) try stdout.writeByte('\n');
    }
    try stdout.flush();
}
