// https://rosettacode.org/wiki/Sorting_algorithms/Strand_sort
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;

const List = std.DoublyLinkedList;

const Element = struct {
    node: List.Node = .{},
    data: u16,
};

const NodePool = std.heap.MemoryPool(Element);

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var node_pool: NodePool = .empty;
    defer node_pool.deinit(std.heap.page_allocator);

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    // Create a new linked list of integers
    var list: List = .{};

    // Add the following integers to the linked list
    const integers = [_]u16{ 5, 1, 4, 2, 0, 9, 6, 3, 8, 7 };
    for (integers) |int| {
        const element = try node_pool.create(std.heap.page_allocator);
        element.* = .{ .data = int };
        list.append(&element.node);
    }

    StrandSort.sort(&list);

    // Print out the solution list
    var it = list.first;
    while (it) |node| : (it = node.next) {
        const element: *Element = @fieldParentPtr("node", node);
        try stdout.print("{d} ", .{element.data});
    }
    try stdout.writeByte('\n');

    try stdout.flush();
}

const StrandSort = struct {
    fn sort(list: *List) void {
        var leftover: List = .{};
        var sorted1: List = .{};

        var result: List = .{};
        while (list.first != null) {
            sorted1.append(list.popFirst().?);
            while (list.popFirst()) |node| {
                const element: *Element = @fieldParentPtr("node", node);
                const element1: *Element = @fieldParentPtr("node", sorted1.last.?);
                if (element1.data <= element.data)
                    sorted1.append(node)
                else
                    leftover.append(node);
            }
            list.concatByMoving(&leftover);

            result = merge(&sorted1, &result);
        }
        list.* = result;
    }

    fn merge(left: *List, right: *List) List {
        var result: List = .{};
        while (left.first != null and right.first != null) {
            const element_left: *Element = @fieldParentPtr("node", left.first.?);
            const element_right: *Element = @fieldParentPtr("node", right.first.?);
            if (element_left.data <= element_right.data)
                result.append(left.popFirst().?)
            else
                result.append(right.popFirst().?);
        }
        result.concatByMoving(left);
        result.concatByMoving(right);

        return result;
    }
};
