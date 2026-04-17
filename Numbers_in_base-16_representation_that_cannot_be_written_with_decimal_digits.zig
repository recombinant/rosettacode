// https://rosettacode.org/wiki/Numbers_in_base-16_representation_that_cannot_be_written_with_decimal_digits
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    for (0..16) |q| {
        for (10..16) |r| {
            try stdout.print("{d} ", .{16 * q + r});
        }
    }

    try stdout.flush();
}
