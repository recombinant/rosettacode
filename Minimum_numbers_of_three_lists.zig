// https://rosettacode.org/wiki/Minimum_numbers_of_three_lists
// {{works with|Zig|0.15.1}}
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    const numbers1 = [5]u8{ 5, 45, 23, 21, 67 };
    const numbers2 = [5]u8{ 43, 22, 78, 46, 38 };
    const numbers3 = [5]u8{ 9, 98, 12, 98, 53 };
    var numbers: [5]u8 = undefined;

    for (numbers1, numbers2, numbers3, &numbers) |n1, n2, n3, *n|
        n.* = @min(n1, @min(n2, n3));

    print("{any}\n", .{numbers});
}
