// https://rosettacode.org/wiki/Find_first_missing_positive
const std = @import("std");

pub fn main() !void {
    const writer = std.io.getStdOut().writer();

    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const numbers = [_][]const i64{
        &[_]i64{ 1, 2, 0 },         &[_]i64{ 3, 4, -1, 1 },
        &[_]i64{ 7, 8, 9, 11, 12 },
    };
    for (numbers) |slice|
        try writer.print("{} ", .{try findFirstMissingPositive(allocator, slice)});
}

fn findFirstMissingPositive(allocator: std.mem.Allocator, slice: []const i64) !i64 {
    var set = std.AutoArrayHashMap(i64, void).init(allocator);
    defer set.deinit();
    try set.ensureTotalCapacity(slice.len);

    for (slice) |n|
        try set.put(n, {});

    var result: i64 = 0;
    while (true) {
        result += 1;
        if (!set.contains(result))
            break;
    }
    return result;
}
