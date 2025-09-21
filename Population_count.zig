// https://rosettacode.org/wiki/Population_count
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const limit = 30;
    var buffer1: [limit]u16 = undefined;
    var buffer2: [limit]u16 = undefined;

    {
        try stdout.writeAll("       : ");
        var n: u64 = 1; // 3 ^ 0
        for (0..limit) |_| {
            try stdout.print("{d:2} ", .{@popCount(n)});
            n *= 3;
        }
        try stdout.writeByte('\n');
    }
    {
        var od: std.ArrayList(u16) = .initBuffer(&buffer1);
        var ev: std.ArrayList(u16) = .initBuffer(&buffer2);

        {
            var n: u16 = 0;
            while (ev.items.len < limit or od.items.len < limit) : (n += 1) {
                if (@popCount(n) & 1 == 0) {
                    if (ev.items.len < limit)
                        try ev.appendBounded(n);
                } else {
                    if (od.items.len < limit)
                        try od.appendBounded(n);
                }
            }
        }

        try stdout.writeAll("evil   :");
        for (ev.items) |n| try stdout.print(" {d:2}", .{n});
        try stdout.writeByte('\n');

        try stdout.writeAll("odious :");
        for (od.items) |n| try stdout.print(" {d:2}", .{n});
        try stdout.writeByte('\n');
    }

    try stdout.flush();
}
