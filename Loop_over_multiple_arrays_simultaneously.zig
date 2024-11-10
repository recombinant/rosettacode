// https://rosettacode.org/wiki/Loop_over_multiple_arrays_simultaneously
const std = @import("std");

pub fn main() void {
    const a1 = [3]u8{ 'a', 'b', 'c' };
    const a2 = [3]u8{ 'A', 'B', 'C' };
    const a3 = [3]u32{ 1, 2, 3 };

    for (a1, a2, a3) |v1, v2, v3|
        std.debug.print("{c}{c}{}\n", .{ v1, v2, v3 });
}
