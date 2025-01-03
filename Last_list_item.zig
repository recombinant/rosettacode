// https://rosettacode.org/wiki/Last_list_item
const std = @import("std");

pub fn main() !void {
    const numbers = [_]u16{ 6, 81, 243, 14, 25, 49, 123, 69, 11 };

    if (numbers.len == 0) {
        std.log.err("List empty, nothing to do", .{});
        return;
    }

    const writer = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list = try std.ArrayList(u16).initCapacity(allocator, numbers.len);
    defer list.deinit();
    try list.appendSlice(&numbers);

    // process the items without any sorting
    while (list.items.len != 1) {
        var pair = try std.BoundedArray(u16, 2).init(0);
        for (0..2) |_|
            try pair.append(list.orderedRemove(findSmallest(u16, list.items).?));
        try list.append(pair.get(0) + pair.get(1));
        try writer.print("Intermediate result: {any}\n", .{list.items});
    }
    try writer.print("{any} ==> {}\n", .{ numbers, list.items[0] });
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
