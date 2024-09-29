// https://rosettacode.org/wiki/Van_Eck_sequence
const std = @import("std");
const mem = std.mem;

const max = 1_000;

// evaluated at compile time
const a: [max]u16 = calc: {
    @setEvalBranchQuota(max * max);
    var tmp: [max]u16 = mem.zeroes([max]u16);

    for (0..max - 1) |n| {
        var m = n;
        while (m != 0) {
            m -= 1;
            if (tmp[m] == tmp[n]) {
                tmp[n + 1] = @intCast(n - m);
                break;
            }
        }
    }
    break :calc tmp;
};

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.writeAll("The first ten terms of the Van Eck sequence are:\n");
    for (a[0..9]) |n|
        try stdout.print("{} ", .{n});
    try stdout.writeAll("\n\nTerms 991 to 1000 of the sequence are:\n");
    for (a[990..]) |n|
        try stdout.print("{} ", .{n});
    try stdout.writeByte('\n');
}
