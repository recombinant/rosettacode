// https://rosettacode.org/wiki/Find_first_missing_positive
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const numbers = [_][]const i64{
        &[_]i64{ 1, 2, 0 },
        &[_]i64{ 3, 4, -1, 1 },
        &[_]i64{ 7, 8, 9, 11, 12 },
    };
    for (numbers) |slice|
        try stdout.print("{} ", .{try findFirstMissingPositive(allocator, slice)});

    try stdout.flush();
}

fn findFirstMissingPositive(allocator: std.mem.Allocator, slice: []const i64) !i64 {
    var set: std.AutoArrayHashMapUnmanaged(i64, void) = .empty;
    defer set.deinit(allocator);
    try set.ensureTotalCapacity(allocator, slice.len);

    for (slice) |n|
        try set.put(allocator, n, {});

    var result: i64 = 0;
    while (true) {
        result += 1;
        if (!set.contains(result))
            break;
    }
    return result;
}
