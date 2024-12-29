// https://rosettacode.org/wiki/Forbidden_numbers
// Translation of C
const std = @import("std");

fn isForbidden(n: anytype) bool {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("isForbidden() expected unsigned integer argument, found " ++ @typeName(T));

    var m = n;
    var v: T = 0;
    while (m > 1 and m % 4 == 0) : (v += 1) {
        m /= 4;
    }
    const p = std.math.pow(T, 4, v);
    return n / p % 8 == 7;
}

pub fn main() !void {
    const writer = std.io.getStdOut().writer();
    {
        try writer.writeAll("The first 50 forbidden numbers are:\n");
        var count: usize = 0;
        var i: u16 = 0;
        while (count < 50) : (i += 1) {
            if (isForbidden(i)) {
                count += 1;
                const sep: u8 = if (count % 10 == 0) '\n' else ' ';
                try writer.print("{d:3}{c}", .{ i, sep });
            }
        }
    }
    {
        try writer.writeAll("\n\n");
        var limit: usize = 500;
        var count: usize = 0;
        var i: u32 = 0;
        while (true) : (i += 1) {
            if (isForbidden(i))
                count += 1;
            if (i == limit) {
                try writer.print("Forbidden number count <= {d:11}: {d:10}\n", .{ limit, count });
                if (limit == 500_000_000)
                    break;
                limit *= 10;
            }
        }
    }
}
