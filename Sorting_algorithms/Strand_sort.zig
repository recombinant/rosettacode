// https://rosettacode.org/wiki/Sorting_algorithms/Strand_sort
const std = @import("std");

const List = std.DoublyLinkedList(u16);
const NodePool = std.heap.MemoryPoolExtra(List.Node, .{});

pub fn main() !void {
    var node_pool = NodePool.init(std.heap.page_allocator);
    defer node_pool.deinit();

    const writer = std.io.getStdOut().writer();

    // Create a new linked list of integers
    var list = List{};

    // Add the following integers to the linked list
    const integers = [_]u16{ 5, 1, 4, 2, 0, 9, 6, 3, 8, 7 };
    for (integers) |int| {
        const node = try node_pool.create();
        node.* = List.Node{
            .data = int,
        };
        list.append(node);
    }

    StrandSort.sort(&list);

    // Print out the solution list
    var it = list.first;
    while (it) |node| : (it = node.next)
        try writer.print("{d}\n", .{node.data});
}

const StrandSort = struct {
    fn sort(list: *List) void {
        var leftover = List{};
        var sorted1 = List{};

        var result: List = List{};
        while (list.len != 0) {
            sorted1.append(list.popFirst().?);
            while (list.popFirst()) |node| {
                if (sorted1.last.?.data <= node.data)
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
        var result = List{};
        while (left.len != 0 and right.len != 0) {
            if (left.first.?.data <= right.first.?.data)
                result.append(left.popFirst().?)
            else
                result.append(right.popFirst().?);
        }
        result.concatByMoving(left);
        result.concatByMoving(right);

        return result;
    }
};
