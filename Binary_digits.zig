// https://rosettacode.org/wiki/Binary_digits
const std = @import("std");

pub fn main() void {
    std.debug.print("{b}\n", .{0});
    std.debug.print("{b}\n", .{5});
    std.debug.print("{b}\n", .{50});
    std.debug.print("{b}\n", .{9000});
}
