// https://rosettacode.org/wiki/Towers_of_Hanoi
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() void {
    move(4, 1, 2, 3);
}

fn move(n: u16, from: u16, via: u16, to: u16) void {
    if (n > 1) {
        move(n - 1, from, to, via);
        std.debug.print("Move disk from pole {} to pole {}\n", .{ from, to });
        move(n - 1, via, from, to);
    } else {
        std.debug.print("Move disk from pole {} to pole {}\n", .{ from, to });
    }
}
