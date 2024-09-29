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
        var buffer: [2 * limit * @sizeOf(u16)]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buffer);
        const allocator = fba.allocator();

        var od = try std.ArrayList(u16).initCapacity(allocator, limit);
        // defer od.deinit(); // not necessary with stack based allocation
        var ev = try std.ArrayList(u16).initCapacity(allocator, limit);
        // defer ev.deinit(); // not necessary with stack based allocation

        {
            var n: u16 = 0;
            while (ev.items.len < limit or od.items.len < limit) : (n += 1) {
                if (@popCount(n) & 1 == 0) {
                    if (ev.items.len < limit)
                        try ev.append(n);
                } else {
                    if (od.items.len < limit)
                        try od.append(n);
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

    try bw.flush();
}
