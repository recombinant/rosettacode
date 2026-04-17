// https://rosettacode.org/wiki/Count_in_octal
// {{works with|Zig|0.16.0}}
// copied from rosettacode
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    var i: u5 = 0;
    while (true) : (i += 1) {
        try stdout.print("{o}\n", .{i});
        if (i == std.math.maxInt(@TypeOf(i)))
            break;
    }

    try stdout.flush();
}
