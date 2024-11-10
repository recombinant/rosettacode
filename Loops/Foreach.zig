// https://rosettacode.org/wiki/Loops/Foreach
const std = @import("std");

pub fn main() !void {
    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    var writer = bw.writer();

    const list = [_][]const u8{ "Red", "Green", "Blue", "Black", "White" };
    for (list) |item|
        try writer.print("{s}\n", .{item});

    try bw.flush();
}
