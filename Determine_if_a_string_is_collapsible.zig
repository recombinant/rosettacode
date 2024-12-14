// https://rosettacode.org/wiki/Determine_if_a_string_is_collapsible
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const writer = std.io.getStdOut().writer();

    const data = [_][]const u8{
        "",
        "\"If I were two-faced, would I be wearing this one?\" --- Abraham Lincoln ",
        "..1111111111111111111111111111111111111111111111111111111111111117777888",
        "I never give 'em hell, I just tell the truth, and they think it's hell. ",
        "                                                    --- Harry S Truman  ",
    };
    var collapser = Collapser.init();
    defer collapser.deinit();
    for (data) |line| {
        try writer.print("original  : «««{s}»»»\n", .{line});
        const collapsed = try collapser.collapse(allocator, line);
        try writer.print("collapsed : «««{s}»»»\n\n", .{collapsed});
        allocator.free(collapsed);
    }
}

const Collapser = struct {
    const List = std.SinglyLinkedList(u8);
    const Node = List.Node;
    const NodePool = std.heap.MemoryPoolExtra(Node, .{});

    node_pool: NodePool,

    fn init() Collapser {
        return Collapser{
            .node_pool = NodePool.init(std.heap.page_allocator),
        };
    }
    fn deinit(self: *Collapser) void {
        self.node_pool.deinit();
        self.node_pool = undefined;
    }

    ///   There are simpler ways to collapse. This method shows
    /// the use of a singly linked list and a memory pool.
    ///   Allocates memory for the result, which must be freed
    /// by the caller.
    fn collapse(self: *Collapser, allocator: std.mem.Allocator, text: []const u8) ![]const u8 {
        if (text.len < 2)
            return allocator.dupe(u8, text);

        var list = try self.createListFromText(text);
        std.debug.assert(text.len == list.len());

        // collapse while copying to ArrayList
        var result = std.ArrayList(u8).init(allocator);
        var node = list.first.?;
        var c1 = node.data;
        try result.append(c1);
        while (node.next) |next_node| : (node = next_node) {
            const c2 = next_node.data;
            // case insensitive comparison
            if (std.ascii.toLower(c1) != std.ascii.toLower(c2)) {
                try result.append(c2);
                c1 = c2;
            }
        }
        self.destroyList(&list);
        std.debug.assert(0 == list.len());

        return result.toOwnedSlice();
    }
    fn createListFromText(self: *Collapser, text: []const u8) !List {
        var list = List{};
        var node: *Node = undefined;
        for (text) |c| {
            const new_node = try self.node_pool.create();
            new_node.* = .{ .data = c };
            if (list.first == null)
                list.prepend(new_node)
            else
                node.insertAfter(new_node);
            node = new_node;
        }
        return list;
    }
    fn destroyList(self: *Collapser, list: *List) void {
        // Nothing else is using the pool, so...
        const ok = self.node_pool.reset(.retain_capacity);
        std.debug.assert(ok);
        list.first = null;
        // // Quicker than
        // while (list.popFirst()) |node|
        //     self.node_pool.destroy(node);
    }
};

const testing = std.testing;
test Collapser {
    const string1 = "The better the 4-wheel drive, the further you'll be from help when ya get stuck!";
    const expected1 = "The beter the 4-whel drive, the further you'l be from help when ya get stuck!";
    const string2 = "headmistressship";
    const expected2 = "headmistreship";

    var collapser = Collapser.init();
    defer collapser.deinit();

    const actual1a = try collapser.collapse(testing.allocator, string1);
    try testing.expectEqualSlices(u8, expected1, actual1a);
    testing.allocator.free(actual1a);

    const actual2a = try collapser.collapse(testing.allocator, string2);
    try testing.expectEqualSlices(u8, expected2, actual2a);
    testing.allocator.free(actual2a);

    const actual2b = try collapser.collapse(testing.allocator, string2);
    try testing.expectEqualSlices(u8, expected2, actual2b);
    testing.allocator.free(actual2b);

    const actual1b = try collapser.collapse(testing.allocator, string1);
    try testing.expectEqualSlices(u8, expected1, actual1b);
    testing.allocator.free(actual1b);
}
