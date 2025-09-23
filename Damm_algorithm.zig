// https://rosettacode.org/wiki/Damm_algorithm
// {{works with|Zig|0.15.1}}
const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

fn damm(digits: []const u8) bool {
    const table: [10][10]u8 = .{
        .{ 0, 3, 1, 7, 5, 9, 8, 6, 4, 2 },
        .{ 7, 0, 9, 2, 1, 5, 4, 8, 6, 3 },
        .{ 4, 2, 0, 6, 8, 7, 1, 3, 5, 9 },
        .{ 1, 7, 5, 0, 9, 8, 3, 4, 2, 6 },
        .{ 6, 1, 2, 3, 0, 4, 5, 9, 7, 8 },
        .{ 3, 6, 7, 4, 2, 0, 9, 5, 8, 1 },
        .{ 5, 8, 6, 9, 7, 2, 0, 1, 3, 4 },
        .{ 8, 9, 4, 5, 3, 6, 2, 0, 1, 7 },
        .{ 9, 4, 3, 8, 6, 1, 7, 2, 0, 5 },
        .{ 2, 5, 8, 1, 4, 3, 6, 7, 9, 0 },
    };

    var interim: u8 = 0;
    for (digits) |c|
        interim = table[interim][c];

    return interim == 0;
}

pub fn main() !void {
    const input: [4]u8 = .{ 5, 7, 2, 4 };
    print("{s}\n", .{if (damm(&input)) "Checksum correct" else "Checksum incorrect"});
}

test "simple test" {
    const allocator = testing.allocator;

    const num_ok = [_]u32{ 5724, 112946 };
    const num_bad = [_]u32{ 5727, 112949 };
    for (num_ok) |num| {
        const digits = try std.fmt.allocPrint(allocator, "{d}", .{num});
        for (digits) |*c| c.* -= '0';
        defer allocator.free(digits);
        try testing.expect(damm(digits));
    }
    for (num_bad) |num| {
        const digits = try std.fmt.allocPrint(allocator, "{d}", .{num});
        for (digits) |*c| c.* -= '0';
        defer allocator.free(digits);
        try testing.expect(!damm(digits));
    }
}
