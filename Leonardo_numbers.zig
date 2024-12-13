// https://rosettacode.org/wiki/Leonardo_numbers
// Translation of C
const std = @import("std");

// --------------------------------------- normal leonardo series
// Enter first two Leonardo numbers and increment step : 1 1 1
// First 25 Leonardo numbers :
//  1 1 3 5 9 15 25 41 67 109 177 287 465 753 1219 1973 3193 5167 8361 13529 21891 35421 57313 92735 150049

// --------------------------------------------- fibonacci series
// Enter first two Leonardo numbers and increment step : 0 1 0
// First 25 Leonardo numbers :
//  0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610 987 1597 2584 4181 6765 10946 17711 28657 46368

// --------------------------------------------------------------
pub fn main() !void {
    const writer = std.io.getStdOut().writer();
    const reader = std.io.getStdIn().reader();

    try writer.writeAll("Enter first two Leonardo numbers and increment step : ");

    var buffer: [1024]u8 = undefined;
    const line = try reader.readUntilDelimiter(&buffer, '\n');

    var ba = try std.BoundedArray(u64, 3).init(0);
    var it = std.mem.splitAny(u8, line, " \t\r\n");
    while (it.next()) |word| {
        if (word.len == 0)
            continue;
        const number = try std.fmt.parseInt(u64, word, 10);
        ba.append(number) catch return error.TooManyNumbers;
    }
    if (ba.len != 3) return error.InsufficientNumbers;

    const a = ba.get(0);
    const b = ba.get(1);
    const step = ba.get(2);

    try leonardo(a, b, step, 25, writer);
}

fn leonardo(a_: u64, b_: u64, step: u64, num: u64, writer: anytype) !void {
    var a = a_;
    var b = b_;

    try writer.writeAll("First 25 Leonardo numbers : \n");

    var i: u64 = 1;
    while (i <= num) : (i += 1) {
        switch (i) {
            1 => try writer.print(" {d}", .{a}),
            2 => try writer.print(" {d}", .{b}),
            else => {
                try writer.print(" {d}", .{a + b + step});
                std.mem.swap(u64, &a, &b);
                b += a + step;
            },
        }
    }
}
