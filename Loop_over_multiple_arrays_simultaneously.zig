// https://rosettacode.org/wiki/Loop_over_multiple_arrays_simultaneously
const std = @import("std");

pub fn main() void {
    const array1 = [3]u8{ 'a', 'b', 'c' };
    const array2 = [3]u8{ 'A', 'B', 'C' };
    const array3 = [3]u32{ 1, 2, 3 };

    for (array1, array2, array3) |v1, v2, v3|
        std.debug.print("{c}{c}{}\n", .{ v1, v2, v3 });
}
