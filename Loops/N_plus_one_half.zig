// https://rosettacode.org/wiki/Loops/N_plus_one_half
const std = @import("std");

pub fn main() void {
    for (0..11) |i|
        std.debug.print("{}{s}", .{ i, if (i == 10) "\n" else ", " });
}
