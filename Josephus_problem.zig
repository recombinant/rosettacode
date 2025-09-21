// https://rosettacode.org/wiki/Josephus_problem
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const data = [_]struct { n: usize, step: usize }{
        .{ .n = 5, .step = 2 },
        .{ .n = 41, .step = 3 },
    };

    for (data) |pair| {
        const result = try j(allocator, pair.n, pair.step);
        defer allocator.free(result);
        try stdout.print(
            "Prisoner killing order: {any}\nSurvivor: {d}\n",
            .{ result[0 .. result.len - 1], result[result.len - 1] },
        );
    }

    try stdout.flush();
}

/// Caller owns returned slice memory.
fn j(allocator: std.mem.Allocator, n: usize, k: usize) ![]usize {
    var p: std.ArrayList(usize) = try .initCapacity(allocator, n);
    defer p.deinit(allocator);
    for (0..n) |i| try p.append(allocator, i);

    var i: usize = 0;
    var seq: std.ArrayList(usize) = try .initCapacity(allocator, n);
    while (p.items.len != 0) {
        i = (i + k - 1) % p.items.len;
        try seq.append(allocator, p.orderedRemove(i));
    }
    return try seq.toOwnedSlice(allocator);
}
