// https://rosettacode.org/wiki/Convert_seconds_to_compound_duration
// Translation of C
const std = @import("std");
const mem = std.mem;

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    for ([_]u32{ 7259, 86400, 6_000_000 }) |seconds| {
        const str = try duration(allocator, seconds);
        defer allocator.free(str);
        try stdout.print("{d:>7} sec = {s}\n", .{ seconds, str });
    }

    try bw.flush();
}

/// Caller owns returned memory.
fn duration(allocator: mem.Allocator, seconds: u32) ![]const u8 {
    var quotient = seconds;
    var remainders: [5]u32 = undefined;
    const divisors: [4]u32 = .{ 60, 60, 24, 7 };

    for (divisors, remainders[0 .. remainders.len - 1]) |dm, *tptr| {
        const m = quotient % dm;
        quotient /= dm;
        tptr.* = m;
    }
    remainders[remainders.len - 1] = quotient;
    mem.reverse(u32, &remainders);

    const units = [_][]const u8{ "wk", "d", "hr", "min", "sec" };

    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();
    const writer = result.writer();

    var sep: []const u8 = "";
    for (&remainders, units) |n, unit| {
        if (n != 0) {
            try writer.print("{s}{d} {s}", .{ sep, n, unit });
            sep = ", ";
        }
    }
    return result.toOwnedSlice();
}
