// https://rosettacode.org/wiki/A%2BB
// Copied from rosettacode
const std = @import("std");

pub fn main() !void {
    var buf: [1024]u8 = undefined;
    const reader = std.io.getStdIn().reader();
    const input = try reader.readUntilDelimiter(&buf, '\n');
    const text = std.mem.trimRight(u8, input, "\r\n");

    var values = try std.BoundedArray([]const u8, 2).init(0);
    var it = std.mem.tokenizeScalar(u8, text, ' ');
    while (it.next()) |number|
        try values.append(number);

    const a = try std.fmt.parseInt(u64, values.get(0), 10);
    const b = try std.fmt.parseInt(u64, values.get(1), 10);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{a + b});
}
