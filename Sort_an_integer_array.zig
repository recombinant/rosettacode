// https://rosettacode.org/wiki/Sort_an_integer_array
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() void {
    var nums = [_]c_int{ 6, 2, 7, 8, 3, 1, 10, 5, 4, 9 };
    std.mem.sort(c_int, &nums, {}, std.sort.asc(c_int));

    std.debug.print("{any}\n", .{nums});
}
