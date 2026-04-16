// https://rosettacode.org/wiki/Last_list_item
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    const numbers = [_]u16{ 6, 81, 243, 14, 25, 49, 123, 69, 11 };

    if (numbers.len == 0) {
        std.log.err("List empty, nothing to do", .{});
        return;
    }

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    var list: std.ArrayList(u16) = try .initCapacity(gpa, numbers.len);
    defer list.deinit(gpa);
    try list.appendSlice(gpa, &numbers);

    // process the items without any sorting
    while (list.items.len != 1) {
        var buffer: [2]u16 = undefined;
        var pair: std.ArrayList(u16) = .initBuffer(&buffer);
        for (0..2) |_|
            try pair.appendBounded(list.orderedRemove(findSmallest(u16, list.items).?));
        try list.append(gpa, pair.items[0] + pair.items[1]);
        try stdout.print("Intermediate result: {any}\n", .{list.items});
    }
    try stdout.print("{any} ==> {}\n", .{ numbers, list.items[0] });

    try stdout.flush();
}

/// Return the index of the smallest item in slice or null if slice empty.
fn findSmallest(T: type, slice: []const T) ?usize {
    if (slice.len == 0)
        return null;

    var idx: usize = 0;
    var smallest: T = slice[0];
    for (slice[1..], 1..) |n, i|
        if (n <= smallest) {
            smallest = n;
            idx = i;
        };
    return idx;
}
