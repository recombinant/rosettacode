// https://rosettacode.org/wiki/Convert_seconds_to_compound_duration
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    for ([_]u32{ 7259, 86400, 6_000_000 }) |seconds| {
        const str = try duration(allocator, seconds);
        defer allocator.free(str);
        try stdout.print("{d:>7} sec = {s}\n", .{ seconds, str });
    }

    try stdout.flush();
}

/// Caller owns returned memory.
fn duration(allocator: std.mem.Allocator, seconds: u32) ![]const u8 {
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

    var a: std.Io.Writer.Allocating = .init(allocator);
    defer a.deinit();

    var sep: []const u8 = "";
    for (remainders, units) |n, unit|
        if (n != 0) {
            try a.writer.print("{s}{d} {s}", .{ sep, n, unit });
            sep = ", ";
        };

    return a.toOwnedSlice();
}
