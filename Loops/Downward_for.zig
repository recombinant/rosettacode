// https://rosettacode.org/wiki/Loops/Downward_for
const std = @import("std");

pub fn main() void {
    var n: u8 = 11;
    while (n != 0) {
        n -= 1;
        std.debug.print("{}{s}", .{ n, if (n == 0) "\n" else ", " });
    }
}
