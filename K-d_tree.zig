// https://rosettacode.org/wiki/K-d_tree
// Translation of C
// also https://en.wikipedia.org/wiki/Quickselect
const std = @import("std");
const heap = std.heap;
const mem = std.mem;
const meta = std.meta;
const posix = std.posix;

const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() !void {
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try posix.getrandom(mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const arr = [_]Point(2){ .{ 2, 3 }, .{ 5, 4 }, .{ 9, 6 }, .{ 4, 7 }, .{ 8, 1 }, .{ 7, 2 } };
    const this_point = Point(2){ 9, 2 };

    const nodes = try createKDNodesFromPoints(allocator, 2, &arr);
    defer allocator.free(nodes);
    print("nodes = {}\n", .{nodes.len});
    var root: *KDNode(2) = makeTree(rand, 2, nodes, 0).?;

    var n_visited: u32 = 0;
    root.nearest(this_point, 0, &n_visited);
}

fn Point(comptime dim: u16) type {
    comptime assert(dim > 0);
    return [dim]f64;
}

fn KDNode(comptime dim: u16) type {
    const S = BitsType(dim);

    return struct {
        const Self = @This();

        pt: Point(dim),
        left: ?*KDNode(dim) = null,
        right: ?*KDNode(dim) = null,

        fn nearest(root: ?*const Self, pt: Point(dim), split: S, n_visited: *u32) void {
            if (root == null) return;
            const node = root.?;

            const d = node.dist(pt);
            _ = d;
            const dx = node.pt[split] - pt[split];
            _ = dx;
            n_visited.* += 1;
        }

        fn dist(self: *const Self, pt: Point(dim)) f64 {
            var d: f64 = 0;
            for (0..dim) |i| {
                const t = self.pt[i] - pt[i];
                d += t * t;
            }
            return d;
        }
    };
}

fn NodesContext(comptime dim: u16) type {
    return struct {
        split: BitsType(dim),
        items: []KDNode(dim),
        rand: std.Random,

        fn lessThan(ctx: @This(), a: usize, b: usize) bool {
            return ctx.items[a].pt[ctx.split] < ctx.items[b].pt[ctx.split];
        }
        fn swap(ctx: @This(), a: usize, b: usize) void {
            return mem.swap(KDNode(dim), &ctx.items[a], &ctx.items[b]);
        }
    };
}

fn partitionContext(left: usize, right: usize, pivot: usize, context: anytype) usize {
    // Move pivot to end
    if (pivot != right) context.swap(pivot, right);
    var store_index = left;
    for (left..right) |i| {
        if (context.lessThan(i, right)) { // pivot value is in right
            if (store_index != i)
                context.swap(store_index, i);
            store_index += 1;
        }
    }
    context.swap(store_index, right); // Move pivot to its final place
    return store_index;
}

/// https://en.wikipedia.org/wiki/Quickselect
fn selectContext(left: usize, right: usize, k: usize, context: anytype) usize {
    // If the list contains only one element return that element
    if (left == right) return left;
    // Select a pivot element between left and right
    var pivot = context.rand.uintLessThan(usize, right + 1);
    pivot = partitionContext(left, right, pivot, context);
    // The pivot is in its final position
    if (k == pivot)
        return k
    else if (k < pivot)
        return selectContext(left, pivot - 1, k, context)
    else
        return selectContext(pivot + 1, right, k, context);
}

/// Create an array of KDNode from an array Point.
fn createKDNodesFromPoints(allocator: mem.Allocator, comptime dim: u16, pts: []const Point(dim)) ![]KDNode(dim) {
    const nodes = try allocator.alloc(KDNode(dim), pts.len);
    for (pts, nodes) |pt, *node| node.* = KDNode(dim){ .pt = pt };
    return nodes;
}

fn makeTree(rand: std.Random, comptime dim: u16, nodes: []KDNode(dim), split: BitsType(dim)) ?*KDNode(dim) {
    if (nodes.len == 0) return null;

    const context: NodesContext(dim) = .{ .items = nodes, .split = split, .rand = rand };
    const md: usize = @divTrunc(nodes.len, 2);
    const median = selectContext(0, nodes.len - 1, md, context);
    var node = &nodes[median];

    const S = BitsType(dim);
    const s2: S = (split +% 1) % @as(S, @intCast(dim));
    node.left = makeTree(rand, 2, nodes[0..median], s2);
    node.right = makeTree(rand, 2, nodes[median + 1 .. nodes.len], s2);
    return node;
}

/// Minimal number of bits to represent the dimension in KD.
fn BitsType(comptime dim: u16) type {
    comptime var s = dim;
    comptime var bits = 0;
    inline while (s != 0) : (s >>= 1) {
        bits += 1;
    }
    return meta.Int(.unsigned, bits); // enough bits to hold 'dim'
}
