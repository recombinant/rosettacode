// https://rosettacode.org/wiki/Van_Eck_sequence
// {{works with|Zig|0.15.1}}
const std = @import("std");

const max = 1_000;

// evaluated at compile time
const a: [max]u16 = calc: {
    @setEvalBranchQuota(max * max);
    var tmp: [max]u16 = std.mem.zeroes([max]u16);

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
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll("The first ten terms of the Van Eck sequence are:\n");
    for (a[0..9]) |n|
        try stdout.print("{} ", .{n});
    try stdout.writeAll("\n\nTerms 991 to 1000 of the sequence are:\n");
    for (a[990..]) |n|
        try stdout.print("{} ", .{n});
    try stdout.writeByte('\n');

    try stdout.flush();
}
