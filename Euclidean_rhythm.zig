// https://rosettacode.org/wiki/Euclidean_rhythm
// {{works with|Zig|0.16.0}}
// {{trans|Python}}

// Copied from rosettacode
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const allocator: Allocator = init.arena.allocator();
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    const result = try generateSequence(allocator, 5, 13);
    for (result) |item|
        try stdout.print("{}", .{item});

    try stdout.writeByte('\n');
    try stdout.flush();
}

fn generateSequence(allocator: Allocator, _k: i32, _n: i32) ![]i32 {
    var k = _k;
    var n = _n;

    var s: std.ArrayList(std.ArrayList(i32)) = .empty;

    for (0..@as(usize, @intCast(n))) |i| {
        var innerList: std.ArrayList(i32) = .empty;
        try innerList.append(allocator, if (i < k) 1 else 0);
        try s.append(allocator, innerList);
    }

    var d: i32 = n - k;
    n = @max(k, d);
    k = @min(k, d);
    var z = d;

    while (z > 0 or k > 1) {
        for (0..@as(usize, @intCast(k))) |i| {
            const lastList = s.items[s.items.len - 1 - i];
            for (lastList.items) |item|
                try s.items[i].append(allocator, item);
        }
        s.shrinkRetainingCapacity(s.items.len - @as(usize, @intCast(k)));
        z -= k;
        d = n - k;
        n = @max(k, d);
        k = @min(k, d);
    }

    var result: std.ArrayList(i32) = .empty;

    for (s.items) |sublist|
        for (sublist.items) |item|
            try result.append(allocator, item);

    return result.toOwnedSlice(allocator);
}
