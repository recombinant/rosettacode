// https://www.rosettacode.org/wiki/Cantor_set
const std = @import("std");

const WIDTH = 81;
const HEIGHT = 5;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var cantor = CantorSet(WIDTH, HEIGHT){};
    cantor.cantor(0, WIDTH, 1);
    try cantor.print(stdout);
}

fn CantorSet(comptime width: usize, comptime height: usize) type {
    return struct {
        const Self = @This();
        lines: [width * height]u8 = [1]u8{'*'} ** (width * height),

        fn cantor(self: *Self, start: usize, len: usize, index: usize) void {
            const seg = len / 3;
            if (seg == 0) return;
            for (index..height) |i| {
                for (start + seg..start + seg * 2) |j|
                    self.lines[i * width + j] = ' ';
            }
            self.cantor(start, seg, index + 1);
            self.cantor(start + seg * 2, seg, index + 1);
        }

        fn print(self: *const Self, writer: anytype) !void {
            for (0..height) |i| {
                try writer.writeAll(self.lines[i * width .. (i + 1) * width]);
                try writer.writeByte('\n');
            }
        }
    };
}
