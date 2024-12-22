// https://rosettacode.org/wiki/Eban_numbers
// Translation of D
const std = @import("std");

/// start, end, print
const Interval = struct { u64, u64, bool };
pub fn main() !void {
    const intervals = [_]Interval{
        .{ 2, 1_000, true },
        .{ 1_000, 4_000, true },
        .{ 2, 10_000, false },
        .{ 2, 100_000, false },
        .{ 2, 1_000_000, false },
        .{ 2, 10_000_000, false },
        .{ 2, 100_000_000, false },
        .{ 2, 1_000_000_000, false },
    };
    const writer = std.io.getStdOut().writer();
    for (intervals) |interval| {
        const start, const end, const print = interval;
        if (start == 2)
            try writer.print("eban numbers up to an including {}:\n", .{end})
        else
            try writer.print("eban numbers between {} and {} (inclusive):\n", .{ start, end });

        var count: usize = 0;
        var i: u64 = start;
        while (i <= end) : (i += 2) {
            const b = i / 1_000_000_000;
            var r = i % 1_000_000_000;
            var m = r / 1_000_000;
            r = i % 1_000_000;
            var t = r / 1_000;
            r %= 1_000;
            if (m >= 30 and m <= 66) m %= 10;
            if (t >= 30 and t <= 66) t %= 10;
            if (r >= 30 and r <= 66) r %= 10;
            if (b == 0 or b == 2 or b == 4 or b == 6)
                if (m == 0 or m == 2 or m == 4 or m == 6)
                    if (t == 0 or t == 2 or t == 4 or t == 6)
                        if (r == 0 or r == 2 or r == 4 or r == 6) {
                            if (print)
                                try writer.print("{} ", .{i});
                            count += 1;
                        };
        }
        if (print)
            try writer.writeByte('\n');
        try writer.print("count = {}\n\n", .{count});
    }
}
