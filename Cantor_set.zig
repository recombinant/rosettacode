// https://www.rosettacode.org/wiki/Cantor_set
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;

const WIDTH = 81;
const HEIGHT = 5;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    var cantor: CantorSet(WIDTH, HEIGHT) = .{};
    cantor.cantor(0, WIDTH, 1);
    try cantor.print(stdout);

    try stdout.flush();
}

fn CantorSet(comptime width: usize, comptime height: usize) type {
    return struct {
        const Self = @This();
        lines: [width * height]u8 = @splat('*'),

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

        fn print(self: *const Self, writer: *Io.Writer) !void {
            for (0..height) |i| {
                try writer.writeAll(self.lines[i * width .. (i + 1) * width]);
                try writer.writeByte('\n');
            }
        }
    };
}
