// https://rosettacode.org/wiki/Find_first_missing_positive
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    const numbers = [_][]const i64{
        &[_]i64{ 1, 2, 0 },
        &[_]i64{ 3, 4, -1, 1 },
        &[_]i64{ 7, 8, 9, 11, 12 },
    };
    for (numbers) |slice|
        try stdout.print("{} ", .{try findFirstMissingPositive(gpa, slice)});

    try stdout.flush();
}

fn findFirstMissingPositive(allocator: Allocator, slice: []const i64) !i64 {
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
