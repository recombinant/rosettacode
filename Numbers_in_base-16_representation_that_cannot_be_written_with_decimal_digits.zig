// https://rosettacode.org/wiki/Numbers_in_base-16_representation_that_cannot_be_written_with_decimal_digits
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    for (0..16) |q| {
        for (10..16) |r| {
            try stdout.print("{d} ", .{16 * q + r});
        }
    }

    try stdout.flush();
}
