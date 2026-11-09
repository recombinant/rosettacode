// https://rosettacode.org/wiki/Wavelet_Matrix
// {{works with|Zig|0.17.1}}
// copied from rosettacode and tweaked
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout_writer = &stdout_file.interface;

    const a: []const i32 = &.{ 3374, 956, 2114, 3415, 3437 };

    const input = try gpa.dupe(i32, a);
    defer gpa.free(input);

    const backup = try gpa.dupe(i32, a);
    defer gpa.free(backup);

    // Sort and deduplicate the array
    const sorted_a = try gpa.dupe(i32, a);
    defer gpa.free(sorted_a);
    std.mem.sortUnstable(i32, sorted_a, {}, std.sort.asc(i32));

    // Deduplicate
    var unique_a: std.ArrayList(i32) = .empty;
    defer unique_a.deinit(gpa);

    for (sorted_a, 0..) |val, i|
        if (i == 0 or val != sorted_a[i - 1])
            try unique_a.append(gpa, val);

    // Map original values to their indices in the unique array
    for (input, backup) |*in, b|
        in.* = @intCast(std.sort.binarySearch(i32, unique_a.items, b, orderI32).?);

    const lrk_vector: []const [3]i32 = &.{
        .{ 2, 2, 1 },
        .{ 3, 4, 1 },
        .{ 4, 5, 1 },
        .{ 1, 2, 2 },
        .{ 4, 4, 1 },
    };

    var wm: WaveletMatrix = try .new(gpa, input, null);
    defer wm.deinit();

    for (lrk_vector) |lrk| {
        const l = lrk[0] - 1; // Convert to 0-indexed
        const r = lrk[1];
        const k = lrk[2];
        try stdout_writer.print("{d}\n", .{unique_a.items[@intCast(wm.quantile(k - 1, @intCast(l), @intCast(r)))]});
    }

    try stdout_writer.flush();
}

const BitRank = struct {
    block: std.ArrayList(u64) = .empty,
    count: std.ArrayList(i32) = .empty,

    const Self = @This();

    const empty: Self = .{};

    fn deinit(self: *Self, allocator: Allocator) void {
        self.block.deinit(allocator);
        self.count.deinit(allocator);
    }

    fn clone(self: Self, allocator: std.mem.Allocator) !Self {
        var result: Self = .empty;
        try result.block.appendSlice(allocator, self.block.items);
        try result.count.appendSlice(allocator, self.count.items);
        return result;
    }

    // Resize resizes the bit vector to the given length
    fn resize(self: *Self, allocator: Allocator, num: usize) !void {
        try self.block.resize(allocator, ((num + 63) / 64) + 1);
        try self.count.resize(allocator, self.block.items.len);

        @memset(self.block.items, 0);
        @memset(self.count.items, 0);
    }

    // Set sets bit at position i
    fn set(self: *Self, i: usize, val: i32) void {
        if (val == 1)
            self.block.items[i >> 6] |= @as(u64, 1) << @intCast(i & 63);
    }

    // Build builds the rank structure
    fn build(self: *Self) void {
        for (1..self.block.items.len) |i|
            self.count.items[i] = self.count.items[i - 1] + self.popcountll(self.block.items[i - 1]);
    }

    // popcountll counts number of 1's in a 64-bit integer
    fn popcountll(_: *const Self, n: u64) i32 {
        return @intCast(@popCount(n));
    }

    // Rank1 counts number of 1's in [0, i)
    fn rank1(self: *const Self, i: usize) i32 {
        if (i == 0)
            return 0;

        const block_idx = i >> 6;
        const bit_pos = i & 63;

        if (block_idx >= self.block.items.len)
            return self.count.items[self.count.items.len - 1];

        const mask = if (bit_pos == 0) 0 else (@as(u64, 1) << @intCast(bit_pos)) - 1;
        return self.count.items[block_idx] + self.popcountll(self.block.items[block_idx] & mask);
    }

    // Rank1FromTo counts number of 1's in [i, j)
    fn rank1FromTo(self: *const Self, i: usize, j: usize) i32 {
        return self.rank1(j) - self.rank1(i);
    }

    // Rank0 counts number of 0's in [0, i)
    fn rank0(self: *const Self, i: usize) i32 {
        return @as(i32, @intCast(i)) - self.rank1(i);
    }

    // Rank0FromTo counts number of 0's in [i, j)
    fn rank0FromTo(self: *const Self, i: usize, j: usize) i32 {
        return self.rank0(j) - self.rank0(i);
    }
};

// Helper function to get bit at position i from val
fn getBit(val: i32, i: i32) i32 {
    if (i < 0 or i >= 32)
        return 0; // Safe default for out of range bit positions

    const n: u32 = @intCast(i);
    return (val >> @intCast(n)) & 1;
}

// WaveletMatrix is a wavelet matrix data structure
const WaveletMatrix = struct {
    height: i32 = 0,
    b: std.ArrayList(BitRank) = .empty,
    pos: std.ArrayList(i32) = .empty,
    allocator: std.mem.Allocator,

    const Self = @This();

    fn init(allocator: std.mem.Allocator) Self {
        return .{ .allocator = allocator };
    }

    fn deinit(self: *Self) void {
        for (self.b.items) |*bit_rank|
            bit_rank.deinit(self.allocator);
        self.b.deinit(self.allocator);
        self.pos.deinit(self.allocator);
    }

    // Create a new wavelet matrix
    fn new(allocator: std.mem.Allocator, vec: []const i32, sigma: ?i32) !Self {
        var wm: Self = .init(allocator);

        const s = if (sigma) |s| s else blk: {
            // Find the maximum element and use that as sigma
            var max_val: i32 = 0;
            for (vec) |v| {
                if (v > max_val)
                    max_val = v;
            }
            break :blk max_val + 1;
        };

        try wm.initWithVector(allocator, vec, s);
        return wm;
    }

    fn initWithVector(self: *Self, allocator: Allocator, vec: []const i32, sigma: i32) !void {
        // Calculate height based on sigma value
        self.height = if (sigma <= 1)
            1
        else
            // Safely calculate the height to avoid overflow
            32 - @as(i32, @intCast(@clz(@as(u32, @intCast(sigma - 1)))));

        try self.b.resize(allocator, @intCast(self.height));
        @memset(self.b.items, .empty);

        try self.pos.resize(allocator, @intCast(self.height));

        const temp_vec = try self.allocator.alloc(i32, vec.len);
        defer self.allocator.free(temp_vec);
        @memcpy(temp_vec, vec);

        for (0..@intCast(self.height)) |i| {
            try self.b.items[i].resize(allocator, vec.len);

            for (0..vec.len) |j| {
                const bit_val = getBit(temp_vec[j], self.height - @as(i32, @intCast(i)) - 1);
                self.b.items[i].set(j, bit_val);
            }

            self.b.items[i].build();

            // Stable partition - separate 0's and 1's while preserving order
            const height_i = self.height - @as(i32, @intCast(i)) - 1;
            self.pos.items[i] = @intCast(self.stablePartition(temp_vec, height_i));
        }
    }

    // stablePartition is equivalent to C++ stable_partition
    fn stablePartition(self: *Self, arr: []i32, height_i: i32) usize {
        var result: std.ArrayList(i32) = .empty;
        defer result.deinit(self.allocator);

        var false_values: std.ArrayList(i32) = .empty;
        defer false_values.deinit(self.allocator);

        for (arr) |item| {
            if (getBit(item, height_i) == 0)
                result.append(self.allocator, item) catch unreachable
            else
                false_values.append(self.allocator, item) catch unreachable;
        }

        const partition_point = result.items.len;

        result.appendSlice(self.allocator, false_values.items) catch unreachable;

        // Update the original array
        @memcpy(arr, result.items);

        return partition_point;
    }

    // Rank counts occurrences of val in range [l, r)
    fn rank(self: *const Self, val: i32, l: usize, r: usize) i32 {
        return self.rankSingle(val, r) - self.rankSingle(val, l);
    }

    // RankSingle counts occurrences of val in range [0, i)
    fn rankSingle(self: *const Self, val: i32, i: usize) i32 {
        var p: i32 = 0;
        var i_val: i32 = @intCast(i);

        for (0..@intCast(self.height)) |j| {
            if (getBit(val, self.height - @as(i32, @intCast(j)) - 1) == 1) {
                p = self.pos.items[j] + self.b.items[j].rank1(@intCast(p));
                i_val = self.pos.items[j] + self.b.items[j].rank1(@intCast(i_val));
            } else {
                p = self.b.items[j].rank0(@intCast(p));
                i_val = self.b.items[j].rank0(@intCast(i_val));
            }
        }
        return i_val - p;
    }

    // Quantile returns kth smallest element in [l, r)
    fn quantile(self: *const Self, k: i32, l: usize, r: usize) i32 {
        var res: i32 = 0;
        var k_val = k;
        var l_val = l;
        var r_val = r;

        for (0..@intCast(self.height)) |i| {
            const j = self.b.items[i].rank0FromTo(l_val, r_val);
            if (j > k_val) {
                l_val = @intCast(self.b.items[i].rank0(l_val));
                r_val = @intCast(self.b.items[i].rank0(r_val));
            } else {
                l_val = @intCast(self.pos.items[i] + self.b.items[i].rank1(l_val));
                r_val = @intCast(self.pos.items[i] + self.b.items[i].rank1(r_val));
                k_val -= j;
                res |= @as(i32, 1) << @intCast(self.height - @as(i32, @intCast(i)) - 1);
            }
        }
        return res;
    }

    // RangeFreq counts elements in [l, r) that are in value range [a, b)
    fn rangeFreq(self: *const Self, l: usize, r: usize, a: i32, b: i32) i32 {
        // Use a safer calculation for the maximum value
        const max_val = if (self.height >= 31) std.math.maxInt(i32) else (@as(i32, 1) << @intCast(self.height));
        return self.rangeFreqRecursive(l, r, a, b, 0, max_val, 0);
    }

    fn rangeFreqRecursive(self: *const Self, i: usize, j: usize, a: i32, b: i32, l: i32, r: i32, x: usize) i32 {
        if (i == j or r <= a or b <= l)
            return 0;

        const mid = (l + r) >> 1;
        if (a <= l and r <= b)
            return @intCast(j - i)
        else {
            const left = self.rangeFreqRecursive(@intCast(self.b.items[x].rank0(i)), @intCast(self.b.items[x].rank0(j)), a, b, l, mid, x + 1);
            const right = self.rangeFreqRecursive(@intCast(self.pos.items[x] + self.b.items[x].rank1(i)), @intCast(self.pos.items[x] + self.b.items[x].rank1(j)), a, b, mid, r, x + 1);
            return left + right;
        }
    }

    // RangeMin finds minimum value in [l, r) within value range [a, b), -1 if not found
    fn rangeMin(self: *const Self, l: usize, r: usize, a: i32, b: i32) i32 {
        // Use a safer calculation for the maximum value
        const max_val = if (self.height >= 31) std.math.maxInt(i32) else (@as(i32, 1) << @intCast(self.height));
        return self.rangeMinRecursive(l, r, a, b, 0, max_val, 0, 0);
    }

    fn rangeMinRecursive(self: *const Self, i: usize, j: usize, a: i32, b: i32, l: i32, r: i32, x: usize, val: i32) i32 {
        if (i == j or r <= a or b <= l)
            return -1;

        if (r - l == 1)
            return val;

        const mid = (l + r) >> 1;
        const res = self.rangeMinRecursive(@intCast(self.b.items[x].rank0(i)), @intCast(self.b.items[x].rank0(j)), a, b, l, mid, x + 1, val);

        if (res < 0)
            return self.rangeMinRecursive(@intCast(self.pos.items[x] + self.b.items[x].rank1(i)), @intCast(self.pos.items[x] + self.b.items[x].rank1(j)), a, b, mid, r, x + 1, val + (@as(i32, 1) << @intCast(self.height - @as(i32, @intCast(x)) - 1)))
        else
            return res;
    }
};

// helper function for std.sort.binarySearch
fn orderI32(context: i32, item: i32) std.math.Order {
    return std.math.order(context, item);
}
