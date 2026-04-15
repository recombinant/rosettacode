// https://rosettacode.org/wiki/Determine_if_a_string_is_collapsible
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    const data = [_][]const u8{
        "",
        "\"If I were two-faced, would I be wearing this one?\" --- Abraham Lincoln ",
        "..1111111111111111111111111111111111111111111111111111111111111117777888",
        "I never give 'em hell, I just tell the truth, and they think it's hell. ",
        "                                                    --- Harry S Truman  ",
    };
    var collapser: CollapserContainer = .empty;
    defer collapser.deinit();
    for (data) |line| {
        try stdout.print("original  : «««{s}»»»\n", .{line});
        const collapsed = try collapser.collapse(gpa, line);
        try stdout.print("collapsed : «««{s}»»»\n\n", .{collapsed});
        gpa.free(collapsed);
    }

    try stdout.flush();
}

const CollapserNode = struct {
    node: std.SinglyLinkedList.Node = .{},
    data: u8,
};

const CollapserContainer = struct {
    const Self = @This();
    const NodePool = std.heap.MemoryPoolExtra(CollapserNode, .{});

    node_pool: NodePool = .empty,

    const empty: Self = .{};

    fn init() Self {
        return .{
            .node_pool = .empty,
        };
    }
    fn deinit(self: *Self) void {
        self.node_pool.deinit(std.heap.page_allocator);
        self.node_pool = undefined;
    }

    /// There are simpler ways to collapse. This method shows the use of
    /// a singly linked list and a memory pool.
    ///
    /// Allocates memory for the result, which must be freed by the caller.
    fn collapse(self: *Self, gpa: Allocator, text: []const u8) ![]const u8 {
        if (text.len < 2)
            return gpa.dupe(u8, text);

        var first = try self.createListFromText(text);
        std.debug.assert(text.len == first.?.node.countChildren() + 1);

        // collapse while copying to ArrayList
        var result: std.ArrayList(u8) = .empty;
        var node: *std.SinglyLinkedList.Node = &first.?.node;
        var c1 = first.?.data;
        try result.append(gpa, c1);
        while (node.next) |next_node| : (node = next_node) {
            const c2 = @as(*CollapserNode, @fieldParentPtr("node", next_node)).data;
            // case insensitive comparison
            if (std.ascii.toLower(c1) != std.ascii.toLower(c2)) {
                try result.append(gpa, c2);
                c1 = c2;
            }
        }

        // Nothing else is using the pool, so...
        const ok = self.node_pool.reset(std.heap.page_allocator, .retain_capacity);
        std.debug.assert(ok);

        return result.toOwnedSlice(gpa);
    }
    fn createListFromText(self: *Self, text: []const u8) !?*CollapserNode {
        var first: ?*CollapserNode = null;
        var last: *CollapserNode = undefined;
        for (text) |c| {
            const new_node = try self.node_pool.create(std.heap.page_allocator);
            new_node.* = .{ .data = c };
            if (first == null)
                first = new_node
            else
                last.node.next = &new_node.node;
            last = new_node;
        }
        return first;
    }
};

const testing = std.testing;
test CollapserContainer {
    const string1 = "The better the 4-wheel drive, the further you'll be from help when ya get stuck!";
    const expected1 = "The beter the 4-whel drive, the further you'l be from help when ya get stuck!";
    const string2 = "headmistressship";
    const expected2 = "headmistreship";

    var collapser: CollapserContainer = .init();
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
