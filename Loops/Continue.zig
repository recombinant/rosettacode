// https://rosettacode.org/wiki/Loops/Continue
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    for (1..11) |i| {
        try stdout.print("{}", .{i});
        if (i % 5 == 0) {
            try stdout.writeByte('\n');
            continue;
        }
        try stdout.writeAll(", ");
    }
}
