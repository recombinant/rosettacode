// https://rosettacode.org/wiki/Josephus_problem
const std = @import("std");
const mem = std.mem;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();

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
}

/// Caller owns returned slice memory.
fn j(allocator: mem.Allocator, n: usize, k: usize) ![]usize {
    var p = try std.ArrayList(usize).initCapacity(allocator, n);
    for (0..n) |i| try p.append(i);
    defer p.deinit();

    var i: usize = 0;
    var seq = try std.ArrayList(usize).initCapacity(allocator, n);
    while (p.items.len != 0) {
        i = (i + k - 1) % p.items.len;
        try seq.append(p.orderedRemove(i));
    }
    return try seq.toOwnedSlice();
}
