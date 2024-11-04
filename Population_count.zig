// https://rosettacode.org/wiki/Population_count
const std = @import("std");

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const limit = 30;

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
        var od = try std.BoundedArray(u16, limit).init(0);
        var ev = try std.BoundedArray(u16, limit).init(0);

        {
            var n: u16 = 0;
            while (ev.len < limit or od.len < limit) : (n += 1) {
                if (@popCount(n) & 1 == 0) {
                    if (ev.len < limit)
                        try ev.append(n);
                } else {
                    if (od.len < limit)
                        try od.append(n);
                }
            }
        }

        try stdout.writeAll("evil   :");
        for (ev.constSlice()) |n| try stdout.print(" {d:2}", .{n});
        try stdout.writeByte('\n');

        try stdout.writeAll("odious :");
        for (od.constSlice()) |n| try stdout.print(" {d:2}", .{n});
        try stdout.writeByte('\n');
    }

    try bw.flush();
}
