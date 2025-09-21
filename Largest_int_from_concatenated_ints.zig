// https://www.rosettacode.org/wiki/Largest_int_from_concatenated_ints
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

pub fn main() !void {
    // ------------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
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

    try stdout.flush();
}

fn catcmp(_: void, lhs: u64, rhs: u64) bool {
    if (lhs == 0) return false;
    if (rhs == 0) return true;

    const a = std.math.log10_int(lhs);
    const b = std.math.log10_int(rhs);
    if (a == b)
        return lhs > rhs;

    const ab = std.math.pow(u64, 10, b + 1) * lhs + rhs;
    const ba = std.math.pow(u64, 10, a + 1) * rhs + lhs;

    return ab > ba;
}

fn maxcat(a: []u64, writer: *std.Io.Writer) !void {
    std.mem.sortUnstable(u64, a, {}, catcmp);

    for (a) |n|
        try writer.print("{d}", .{n});
    try writer.writeByte('\n');
}
