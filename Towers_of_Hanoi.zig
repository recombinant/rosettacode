// https://rosettacode.org/wiki/Towers_of_Hanoi
const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    move(4, 1, 2, 3);
}

fn move(n: u16, from: u16, via: u16, to: u16) void {
    if (n > 1) {
        move(n - 1, from, to, via);
        print("Move disk from pole {} to pole {}\n", .{ from, to });
        move(n - 1, via, from, to);
    } else {
        print("Move disk from pole {} to pole {}\n", .{ from, to });
    }
}
