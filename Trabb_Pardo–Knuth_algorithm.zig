// https://rosettacode.org/wiki/Trabb_Pardo%E2%80%93Knuth_algorithm
const std = @import("std");

// 10 -1 1 2 3 4 4.3 4.305 4.303 4.302 4.301
pub fn main() !void {
    const check = 400;

    const writer = std.io.getStdOut().writer();
    const reader = std.io.getStdIn().reader();

    var buffer: [1024]u8 = undefined;
    const line = try reader.readUntilDelimiter(&buffer, '\n');

    var ba = try std.BoundedArray(f64, 11).init(0);
    var it = std.mem.splitAny(u8, line, " \t\r\n");
    while (it.next()) |word| {
        if (word.len == 0)
            continue;
        const number = try std.fmt.parseFloat(f64, word);
        ba.append(number) catch return error.TooManyNumbers;
    }
    if (ba.len != 11) return error.InsufficientNumbers;

    const s = ba.slice();
    std.mem.reverse(f64, s);
    for (s) |n| {
        const result = @sqrt(@abs(n)) + 5 * std.math.pow(f64, n, 3);

        try writer.print("f({d:7.4}) = ", .{n});

        if (result > check)
            try writer.writeAll("Overflow!\n")
        else
            try writer.print("{d:8.4}\n", .{result});
    }
}
