// https://rosettacode.org/wiki/Base_16_numbers_needing_a_to_f
// {{works with|Zig|0.16.0}}
// {{trans|C}}
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    var h: u16 = 0;
    while (h != 512) : (h += 16) {
        var l: u16 = if (h & 0xff < 0xa0) 10 else 0;
        while (l != 16) : (l += 1) {
            const n = h | l;
            if (n > 500) {
                try stdout.writeByte('\n');
                return;
            }
            try stdout.print(" {d}", .{n});
        }
    }

    try stdout.flush();
}
