// https://rosettacode.org/wiki/Convert_seconds_to_compound_duration
// {{works with|Zig|0.16.0}}
// {{trans|C}}
const std = @import("std");

const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;
    const gpa: Allocator = init.gpa;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    for ([_]u32{ 7259, 86400, 6_000_000 }) |seconds| {
        const str = try duration(gpa, seconds);
        defer gpa.free(str);
        try stdout.print("{d:>7} sec = {s}\n", .{ seconds, str });
    }

    try stdout.flush();
}

/// Caller owns returned memory.
fn duration(allocator: Allocator, seconds: u32) ![]const u8 {
    var quotient = seconds;
    var remainders: [5]u32 = undefined;
    const divisors: [4]u32 = .{ 60, 60, 24, 7 };

    for (divisors, remainders[0 .. remainders.len - 1]) |dm, *tptr| {
        const m = quotient % dm;
        quotient /= dm;
        tptr.* = m;
    }
    remainders[remainders.len - 1] = quotient;
    std.mem.reverse(u32, &remainders);

    const units = [_][]const u8{ "wk", "d", "hr", "min", "sec" };

    var a: Io.Writer.Allocating = .init(allocator);
    defer a.deinit();

    var sep: []const u8 = "";
    for (remainders, units) |n, unit|
        if (n != 0) {
            try a.writer.print("{s}{d} {s}", .{ sep, n, unit });
            sep = ", ";
        };

    return a.toOwnedSlice();
}
