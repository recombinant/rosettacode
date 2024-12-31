// https://rosettacode.org/wiki/Sierpinski_triangle
const std = @import("std");

const ORDER = 4;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const size = 1 << ORDER;
    var y: usize = size;
    while (y != 0) {
        y -= 1;
        for (0..y) |_|
            try stdout.writeByte(' ');

        var x: usize = 0;
        while (x + y < size) : (x += 1) {
            if (x & y != 0)
                try stdout.writeAll("  ")
            else
                try stdout.writeAll("* ");
        }
        try stdout.writeByte('\n');
    }
}
