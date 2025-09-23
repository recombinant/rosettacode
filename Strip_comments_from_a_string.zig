// https://rosettacode.org/wiki/Strip_comments_from_a_string
// {{works with|Zig|0.15.1}}
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    const strings = [_][]const u8{
        " apples, pears # and bananas",
        " apples, pears ; and bananas",
        " apples, pears \t     ",
    };
    const markers = "#;";

    for (strings) |s| {
        const intermediate = if (std.mem.indexOfAny(u8, s, markers)) |idx| s[0..idx] else s;
        const stripped = std.mem.trim(u8, intermediate, "\t ");

        print("'{s}' -> '{s}'\n", .{ s, stripped });
    }
}
