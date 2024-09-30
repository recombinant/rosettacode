// https://www.rosettacode.org/wiki/Largest_int_from_concatenated_ints
// Translation of C
const std = @import("std");
const io = std.io;
const math = std.math;
const mem = std.mem;
const sort = std.sort;

pub fn main() !void {
    // ------------------------------------------------------- stdout
    const stdout = io.getStdOut().writer();
    // --------------------------------------------------------------
    var arr1 = [_]u64{ 1, 34, 3, 98, 9, 76, 45, 4 };
    var arr2 = [_]u64{ 54, 546, 548, 60 };
    var arr3 = [_]u64{ 60, 54, 545454546, 0 };
    var arr4 = [_]u64{ 212, 21221 };
    var arr5 = [_]u64{ 0, 1, 0 };
    var arr6 = [_]u64{ 0, 2121212122, 21, 60 };

    try maxcat(&arr1, stdout);
    try maxcat(&arr2, stdout);
    try maxcat(&arr3, stdout);
    try maxcat(&arr4, stdout);
    try maxcat(&arr5, stdout);
    try maxcat(&arr6, stdout);
}

fn catcmp(_: void, lhs: u64, rhs: u64) bool {
    if (lhs == 0) return false;
    if (rhs == 0) return true;

    const a = math.log10_int(lhs);
    const b = math.log10_int(rhs);
    if (a == b)
        return lhs > rhs;

    const ab = math.pow(u64, 10, b + 1) * lhs + rhs;
    const ba = math.pow(u64, 10, a + 1) * rhs + lhs;

    return ab > ba;
}

fn maxcat(a: []u64, writer: anytype) !void {
    sort.pdq(u64, a, {}, catcmp);

    for (a) |n|
        try writer.print("{d}", .{n});
    try writer.writeByte('\n');
}
