// https://rosettacode.org/wiki/Count_in_octal
// copied from rosettacode
const std = @import("std");

pub fn main() !void {
    const writer = std.io.getStdOut().writer();

    var i: u5 = 0;
    while (true) : (i += 1) {
        try writer.print("{o}\n", .{i});
        if (i == std.math.maxInt(@TypeOf(i)))
            break;
    }
}
