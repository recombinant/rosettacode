// https://rosettacode.org/wiki/Numbers_in_base-16_representation_that_cannot_be_written_with_decimal_digits
const std = @import("std");

pub fn main() !void {
    const writer = std.io.getStdOut().writer();

    for (0..16) |q| {
        for (10..16) |r| {
            try writer.print("{d} ", .{16 * q + r});
        }
    }
}
