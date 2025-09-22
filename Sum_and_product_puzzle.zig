// https://rosettacode.org/wiki/Sum_and_product_puzzle
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

const List = std.SinglyLinkedList;
const Item = struct {
    node: List.Node = .{},
    x: u64,
    y: u64,
};
const Pool = std.heap.MemoryPoolExtra(Item, .{});

pub fn main() !void {
    // ----------------------------------------------------
    var pool: Pool = .init(std.heap.page_allocator);
    defer pool.deinit();
    // ----------------------------------------------------
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ----------------------------------------------------
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ----------------------------------------------------
    var candidates = try setup(&pool);
    defer deinit(&pool, &candidates);
    try printCount(candidates, stdout);

    try statement1(allocator, &pool, &candidates);
    try printCount(candidates, stdout);

    try statement2(allocator, &pool, &candidates);
    try printCount(candidates, stdout);

    try statement3(allocator, &pool, &candidates);
    try printCount(candidates, stdout);

    try printList(candidates, stdout);

    try stdout.flush();
}

fn printList(list: List, w: *std.Io.Writer) !void {
    var node_ = list.first;
    while (node_) |node| : (node_ = node.next) {
        const item: *Item = @fieldParentPtr("node", node);
        const sum = item.x + item.y;
        const product = item.x * item.y;
        try w.print("[{}, {}] S={} P={}\n", .{ item.x, item.y, sum, product });
    }
}

fn printCount(list: List, w: *std.Io.Writer) !void {
    const len = list.len();
    try switch (len) {
        0 => w.writeAll("no candidates\n"),
        1 => w.writeAll("one candidate\n"),
        else => w.print("{} candidates\n", .{len}),
    };
}

fn setup(pool: *Pool) !List {
    var list = List{};

    // numbers must be greater than 1
    for (2..99) |x| {
        // numbers must be unique, and sum no more than 100
        for (x + 1..99) |y| {
            if (x + y <= 100) {
                const item = try pool.create();
                item.* = .{ .x = x, .y = y };
                list.prepend(&item.node);
            }
        }
    }
    return list;
}

fn deinit(pool: *Pool, list: *List) void {
    while (list.popFirst()) |node| {
        const item: *Item = @fieldParentPtr("node", node);
        pool.destroy(item);
    }
}

/// May invalidate any exising pointers into list.
fn removeBySum(pool: *Pool, list: *List, sum: u64) void {
    var it = list.first;
    while (it) |node| {
        const item: *Item = @fieldParentPtr("node", node);
        if (item.x + item.y == sum) {
            list.remove(node);
            pool.destroy(item);
            it = list.first;
        } else {
            it = node.next;
        }
    }
}

/// May invalidate any exising pointers into list.
fn removeByProduct(pool: *Pool, list: *List, product: u64) void {
    var it = list.first;
    while (it) |node| {
        const item: *Item = @fieldParentPtr("node", node);
        if (item.x * item.y == product) {
            list.remove(node);
            pool.destroy(item);
            it = list.first;
        } else {
            it = node.next;
        }
    }
}

fn statement1(allocator: std.mem.Allocator, pool: *Pool, list: *List) !void {
    var pair_counts: std.AutoArrayHashMapUnmanaged(u64, u8) = .empty;
    defer pair_counts.deinit(allocator);

    var it = list.first;
    while (it) |node| : (it = node.next) {
        const item: *Item = @fieldParentPtr("node", node);
        const product = item.x * item.y;
        const gop = try pair_counts.getOrPutValue(allocator, product, 1);
        if (gop.found_existing)
            gop.value_ptr.* += 1;
    }

    it = list.first;
    while (it) |node| {
        const item: *Item = @fieldParentPtr("node", node);
        const product = item.x * item.y;
        if (pair_counts.get(product).? == 1) {
            removeBySum(pool, list, item.x + item.y);
            it = list.first;
        } else {
            it = node.next;
        }
    }
}

fn statement2(allocator: std.mem.Allocator, pool: *Pool, list: *List) !void {
    var pair_counts: std.AutoArrayHashMapUnmanaged(u64, u8) = .empty;
    defer pair_counts.deinit(allocator);

    var it = list.first;
    while (it) |node| : (it = node.next) {
        const item: *Item = @fieldParentPtr("node", node);
        const product = item.x * item.y;
        const gop = try pair_counts.getOrPutValue(allocator, product, 1);
        if (gop.found_existing)
            gop.value_ptr.* += 1;
    }

    it = list.first;
    while (it) |node| {
        const item: *Item = @fieldParentPtr("node", node);
        const product = item.x * item.y;
        if (pair_counts.get(product).? > 1) {
            list.remove(node);
            pool.destroy(item);
            removeByProduct(pool, list, product);
            it = list.first;
        } else {
            it = node.next;
        }
    }
}

fn statement3(allocator: std.mem.Allocator, pool: *Pool, list: *List) !void {
    var unique = try allocator.alloc(u8, 100);
    defer allocator.free(unique);
    @memset(unique, 0);

    var it = list.first;
    while (it) |node| : (it = node.next) {
        const item: *Item = @fieldParentPtr("node", node);
        const sum = item.x + item.y;
        unique[sum] += 1;
    }

    it = list.first;
    while (it) |node| {
        const item: *Item = @fieldParentPtr("node", node);
        const sum = item.x + item.y;
        if (unique[sum] > 1) {
            removeBySum(pool, list, sum);
            it = list.first;
        } else {
            it = node.next;
        }
    }
}
