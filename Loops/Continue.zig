// https://rosettacode.org/wiki/Loops/Continue
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    for (1..11) |i| {
        try stdout.print("{}", .{i});
        if (i % 5 == 0) {
            try stdout.writeByte('\n');
            continue;
        }
        try stdout.writeAll(", ");
    }
    try stdout.flush();
}
