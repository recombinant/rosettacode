// https://rosettacode.org/wiki/Ludic_numbers
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ludic_numbers = try getLudicNumbers(allocator, 30_000);

    defer allocator.free(ludic_numbers);

    const writer = std.io.getStdOut().writer();

    try writer.writeAll("First 25 Ludic numbers:\n");
    for (ludic_numbers[0..25]) |ludic|
        try writer.print(" {}", .{ludic});
    try writer.writeByteNTimes('\n', 2);

    var count: usize = 0;
    while (ludic_numbers[count] <= 1000) : (count += 1) {}
    try writer.print("Ludic numbers below 1000:\n {}\n\n", .{count});

    // Zig arrays are 0 based.
    // First Ludic number is at ludic_numbers[0] etc.
    try writer.writeAll("Ludic numbers 2000..2005:\n");
    for (ludic_numbers[1999..2005]) |ludic|
        try writer.print(" {}", .{ludic});
    try writer.writeByteNTimes('\n', 2);

    try writer.writeAll("Triplets of Ludic numbers < 250:\n");
    var i: usize = 0;
    while (ludic_numbers[i] < 250) : (i += 1) {
        const ludic = ludic_numbers[i];
        if (std.mem.indexOfScalar(usize, ludic_numbers[i + 1 .. i + 3], ludic + 2) == null)
            continue;
        if (std.mem.indexOfScalar(usize, ludic_numbers[i + 1 .. i + 7], ludic + 6) == null)
            continue;
        try writer.print(" ({} {} {})", .{ ludic_numbers[i], ludic_numbers[i] + 2, ludic_numbers[i] + 6 });
    }
    try writer.writeByte('\n');
}

/// Return all the Ludic numbers up to `limit` using brute force sieve.
/// Allocates memory for the result, which must be freed by the caller.
fn getLudicNumbers(allocator: std.mem.Allocator, limit: usize) ![]usize {
    var ludic_list = std.ArrayList(usize).init(allocator);
    defer ludic_list.deinit();
    try ludic_list.append(1); // first ludic number

    // Not the most efficient, but a singly linked list in
    // conjunction with a memory pool does the job.
    const List = std.SinglyLinkedList(usize);
    const Node = List.Node;
    const NodePool = std.heap.MemoryPoolExtra(Node, .{});

    var node_pool = NodePool.init(std.heap.page_allocator);
    defer node_pool.deinit();

    var list = List{};
    list.first = try node_pool.create();
    var last = list.first.?;
    last.* = .{ .data = 2 }; // the next ludic number

    // all numbers from 3 up to limit
    for (3..limit) |i| {
        const new_node = try node_pool.create();
        new_node.* = .{ .data = i };
        last.insertAfter(new_node);
        last = new_node;
    }
    // harvest the ludic numbers, removing non-ludic
    while (list.first != null) {
        const n = list.first.?.data;
        try ludic_list.append(n); // harvest
        list.first = list.first.?.next; // remove first
        var node_: ?*Node = list.first;
        var i: usize = 2;
        while (node_) |node| : (i += 1)
            node_ = if (i % n == 0) node.removeNext() else node.next;
    }
    return ludic_list.toOwnedSlice();
}

const testing = std.testing;
test getLudicNumbers {
    // from
    // https://oeis.org/A003309
    const ludic_numbers = [_]usize{
        1,   2,   3,   5,   7,   11,  13,  17,  23,  25,
        29,  37,  41,  43,  47,  53,  61,  67,  71,  77,
        83,  89,  91,  97,  107, 115, 119, 121, 127, 131,
        143, 149, 157, 161, 173, 175, 179, 181, 193, 209,
        211, 221, 223, 227, 233, 235, 239, 247, 257, 265,
        277, 283, 287, 301, 307, 313,
    };
    const actual = try getLudicNumbers(testing.allocator, 1000);

    try testing.expectEqualSlices(usize, &ludic_numbers, actual[0..ludic_numbers.len]);

    testing.allocator.free(actual);
}
