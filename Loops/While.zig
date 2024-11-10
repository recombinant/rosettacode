// https://rosettacode.org/wiki/Loops/While
// Copied from rosettacode
const std = @import("std");

pub fn main() void {
    var i: u11 = 1024;
    while (i > 0) : (i /= 2)
        std.debug.print("{}\n", .{i});
}
