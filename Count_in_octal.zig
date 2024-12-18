// https://rosettacode.org/wiki/Count_in_octal
// copied from rosettacode
const std = @import("std");

pub fn main() void {
    for (0..255) |i| {
        std.debug.print("{o}\n", .{i});
    }
}
