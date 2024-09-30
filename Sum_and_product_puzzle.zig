// https://rosettacode.org/wiki/Sum_and_product_puzzle
// Translation of C
const std = @import("std");
const heap = std.heap;
const mem = std.mem;

const Pair = struct { x: u64, y: u64 };
const L = std.SinglyLinkedList(Pair);
const Pool = heap.MemoryPoolExtra(L.Node, .{});

pub fn main() !void {
    // ----------------------------------------------------
    var pool = Pool.init(heap.page_allocator);
    defer pool.deinit();
    // ----------------------------------------------------
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ----------------------------------------------------
    const stdout = std.io.getStdOut().writer();
    // ----------------------------------------------------
    var candidates = try init(&pool);
    defer deinit(&pool, &candidates);
    try printCount(stdout, candidates);

    try statement1(allocator, &pool, &candidates);
    try printCount(stdout, candidates);

    try statement2(allocator, &pool, &candidates);
    try printCount(stdout, candidates);

    try statement3(allocator, &pool, &candidates);
    try printCount(stdout, candidates);

    try printList(stdout, candidates);
}

fn printList(writer: anytype, list: L) !void {
    var node_ = list.first;
    while (node_) |node| : (node_ = node.next) {
        const pair = node.data;
        const sum = pair.x + pair.y;
        const product = pair.x * pair.y;
        try writer.print("[{}, {}] S={} P={}\n", .{ pair.x, pair.y, sum, product });
    }
}

fn printCount(writer: anytype, list: L) !void {
    const len = list.len();
    try switch (len) {
        0 => writer.writeAll("no candidates\n"),
        1 => writer.writeAll("one candidate\n"),
        else => writer.print("{} candidates\n", .{len}),
    };
}

fn init(pool: *Pool) !L {
    var list = L{};

    const max_sum = 100;

    // numbers must be greater than 1
    for (2..max_sum / 2 - 1) |x| {
        // numbers must be unique, and sum no more than 100
        for (x + 1..max_sum - 2) |y| {
            if (x + y <= max_sum) {
                const node = try pool.create();
                node.* = L.Node{ .data = .{ .x = x, .y = y } };
                list.prepend(node);
            }
        }
    }
    return list;
}

fn deinit(pool: *Pool, list: *L) void {
    while (list.popFirst()) |node|
        pool.destroy(node);
}

/// May invalidate any exising pointers into list.
fn removeBySum(pool: *Pool, list: *L, sum: u64) void {
    var node_ = list.first;
    while (node_) |node| {
        node_ = node.next; // move to next before possibly removing node
        const pair = node.data;
        if (pair.x + pair.y == sum) {
            list.remove(node);
            pool.destroy(node);
        }
    }
}

/// May invalidate any exising pointers into list.
fn removeByProduct(pool: *Pool, list: *L, product: u64) void {
    var node_ = list.first;
    while (node_) |node| {
        node_ = node.next; // move to next before possibly removing node
        const pair = node.data;
        if (pair.x * pair.y == product) {
            list.remove(node);
            pool.destroy(node);
        }
    }
}

/// product vs product frequency
fn statement1(allocator: mem.Allocator, pool: *Pool, list: *L) !void {
    var pair_counts = std.AutoArrayHashMap(u64, u32).init(allocator);
    defer pair_counts.deinit();

    {
        var node_ = list.first;
        while (node_) |node| {
            node_ = node.next;
            const pair = node.data;
            const product = pair.x * pair.y;
            const gop = try pair_counts.getOrPutValue(product, 1);
            if (gop.found_existing)
                gop.value_ptr.* += 1;
        }
    }
    {
        var node_ = list.first;
        while (node_) |node| {
            node_ = node.next;
            const pair = node.data;
            const product = pair.x * pair.y;
            if (pair_counts.get(product).? == 1) {
                removeBySum(pool, list, pair.x + pair.y);
                node_ = list.first; // because `node_` may be invalidated
            }
        }
    }
}

/// product vs product frequency
fn statement2(allocator: mem.Allocator, pool: *Pool, list: *L) !void {
    var pair_counts = std.AutoArrayHashMap(u64, u32).init(allocator);
    defer pair_counts.deinit();

    {
        var node_ = list.first;
        while (node_) |node| {
            node_ = node.next;
            const pair = node.data;
            const product = pair.x * pair.y;
            const gop = try pair_counts.getOrPutValue(product, 1);
            if (gop.found_existing)
                gop.value_ptr.* += 1;
        }
    }
    {
        var node_ = list.first;
        while (node_) |node| {
            node_ = node.next;
            const pair = node.data;
            const product = pair.x * pair.y;
            if (pair_counts.get(product).? > 1) {
                list.remove(node);
                pool.destroy(node);
                removeByProduct(pool, list, product);
                node_ = list.first; // because `node_` may be invalidated
            }
        }
    }
}

/// sum vs sum frequency
fn statement3(allocator: mem.Allocator, pool: *Pool, list: *L) !void {
    var pair_counts = std.AutoArrayHashMap(u64, u32).init(allocator);
    defer pair_counts.deinit();

    {
        var node_ = list.first;
        while (node_) |node| {
            node_ = node.next;
            const pair = node.data;
            const sum = pair.x + pair.y;
            const gop = try pair_counts.getOrPutValue(sum, 1);
            if (gop.found_existing)
                gop.value_ptr.* += 1;
        }
    }
    {
        var node_ = list.first;
        while (node_) |node| {
            node_ = node.next;
            const pair = node.data;
            const sum = pair.x + pair.y;
            if (pair_counts.get(sum).? > 1) {
                list.remove(node);
                pool.destroy(node);
                removeBySum(pool, list, sum);
                node_ = list.first; // because `node_` may be invalidated
            }
        }
    }
}
