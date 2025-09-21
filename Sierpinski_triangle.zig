// https://rosettacode.org/wiki/Sierpinski_triangle
// {{works with|Zig|0.15.1}}
const std = @import("std");

const ORDER = 4;

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

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

    try stdout.flush();
}
