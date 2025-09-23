// https://rosettacode.org/wiki/Ludic_numbers
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ludic_numbers = try getLudicNumbers(allocator, 30_000);

    defer allocator.free(ludic_numbers);

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll("First 25 Ludic numbers:\n");
    for (ludic_numbers[0..25]) |ludic|
        try stdout.print(" {}", .{ludic});
    _ = try stdout.splatByte('\n', 2);

    var count: usize = 0;
    while (ludic_numbers[count] <= 1000) : (count += 1) {}
    try stdout.print("Ludic numbers below 1000:\n {}\n\n", .{count});

    // Zig arrays are 0 based.
    // First Ludic number is at ludic_numbers[0] etc.
    try stdout.writeAll("Ludic numbers 2000..2005:\n");
    for (ludic_numbers[1999..2005]) |ludic|
        try stdout.print(" {}", .{ludic});
    _ = try stdout.splatByte('\n', 2);

    try stdout.writeAll("Triplets of Ludic numbers < 250:\n");
    var i: usize = 0;
    while (ludic_numbers[i] < 250) : (i += 1) {
        const ludic = ludic_numbers[i];
        if (std.mem.indexOfScalar(usize, ludic_numbers[i + 1 .. i + 3], ludic + 2) == null)
            continue;
        if (std.mem.indexOfScalar(usize, ludic_numbers[i + 1 .. i + 7], ludic + 6) == null)
            continue;
        try stdout.print(" ({} {} {})", .{ ludic_numbers[i], ludic_numbers[i] + 2, ludic_numbers[i] + 6 });
    }
    try stdout.writeByte('\n');

    try stdout.flush();
}

/// Return all the Ludic numbers up to `limit` using brute force sieve.
/// Allocates memory for the result, which must be freed by the caller.
fn getLudicNumbers(allocator: std.mem.Allocator, limit: usize) ![]usize {
    var ludic_list: std.ArrayList(usize) = .empty;
    defer ludic_list.deinit(allocator);
    try ludic_list.append(allocator, 1); // first ludic number

    // Not the most efficient, but a singly linked list in
    // conjunction with a memory pool does the job.
    const DataNode = struct {
        data: usize,
        node: std.SinglyLinkedList.Node = .{},
    };
    const DataNodePool = std.heap.MemoryPoolExtra(DataNode, .{});

    var data_node_pool: DataNodePool = .init(std.heap.page_allocator);
    defer data_node_pool.deinit();

    var list = blk: {
        var data = try data_node_pool.create();
        data.* = .{ .data = 2 }; // the next ludic number

        break :blk std.SinglyLinkedList{ .first = &data.node };
    };
    var tail = list.first.?;

    // all numbers from 3 up to limit
    for (3..limit) |i| {
        const new_data = try data_node_pool.create();
        new_data.* = .{ .data = i };
        const new_node = &new_data.node;
        tail.insertAfter(new_node);
        tail = new_node;
    }

    // harvest the ludic numbers, removing non-ludic
    while (list.first) |first| {
        const n = @as(*DataNode, @fieldParentPtr("node", first)).data;
        try ludic_list.append(allocator, n); // harvest
        _ = list.popFirst();
        var node = list.first;
        var i: usize = 2;
        while (node) |possible| : (i += 1)
            node = if (i % n == 0) possible.removeNext() else possible.next;
    }
    return ludic_list.toOwnedSlice(allocator);
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
