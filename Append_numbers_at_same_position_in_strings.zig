// https://rosettacode.org/wiki/Append_numbers_at_same_position_in_strings
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;
    const gpa: Allocator = init.gpa;
    // --------------------------------------------------------------
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    // --------------------------------------------------------------

    const list1 = [_]u32{ 1, 2, 3, 4, 5, 6, 7, 8, 9 };
    const list2 = [_]u32{ 10, 11, 12, 13, 14, 15, 16, 17, 18 };
    const list3 = [_]u32{ 19, 20, 21, 22, 23, 24, 25, 26, 27 };

    const lists = [_][]const u32{ &list1, &list2, &list3 };

    const result = try concatenateLists(gpa, lists[0..]);
    defer {
        for (result) |list| gpa.free(list);
        gpa.free(result);
    }

    const s = try std.mem.join(gpa, ", ", result);
    try stdout.print("list = [ {s} ]\n", .{s});
    gpa.free(s);

    try stdout.flush();
}

/// Return result as slice of strings. Caller owns returned memory.
fn concatenateLists(allocator: Allocator, lists: []const []const u32) ![][]const u8 {
    for (lists[1..]) |list| std.debug.assert(list.len == lists[0].len);

    var result: std.ArrayList([]const u8) = .empty;

    var w: std.Io.Writer.Allocating = .init(allocator);
    defer w.deinit();

    for (0..lists[0].len) |i| {
        for (lists) |list|
            try w.writer.printInt(list[i], 10, .lower, .{});
        try result.append(allocator, try w.toOwnedSlice());
    }
    return try result.toOwnedSlice(allocator);
}
