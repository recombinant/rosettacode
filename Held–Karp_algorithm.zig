// https://rosettacode.org/wiki/Held–Karp_algorithm
// {{works with|Zig|0.17.1}}
// {{trans|Python}}
// copied from rosettacode and tweaked

const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const allocator = init.gpa;

    var stdout_buffer: [256]u8 = undefined;
    var stdout_file = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout_writer = &stdout_file.interface;

    // Task's example test case: 4 cities, symmetric distances
    const example_distances1: []const []const i64 = &.{
        // zig fmt: off
        &.{  0,  2,  9, 10 },
        &.{  1,  0,  6,  4 },
        &.{ 15,  7,  0,  8 },
        &.{  6,  3, 12,  0 },
        // zig fmt: on
    };

    // Additional test case: 15 cities, from the Crow solution
    const example_distances2: []const []const i64 = &.{
        // zig fmt: off
        &.{0, 29, 82, 46, 68, 52, 72, 42, 51, 55, 29, 74, 23, 72, 46},
        &.{29, 0, 55, 46, 42, 43, 43, 23, 23, 31, 41, 51, 11, 52, 21},
        &.{82, 55, 0, 68, 46, 55, 23, 43, 41, 29, 79, 21, 64, 31, 51},
        &.{46, 46, 68, 0, 82, 15, 72, 31, 62, 42, 21, 51, 51, 43, 64},
        &.{68, 42, 46, 82, 0, 74, 23, 52, 21, 46, 82, 58, 46, 65, 23},
        &.{52, 43, 55, 15, 74, 0, 61, 23, 55, 31, 33, 37, 51, 29, 59},
        &.{72, 43, 23, 72, 23, 61, 0, 42, 23, 31, 77, 37, 51, 46, 33},
        &.{42, 23, 43, 31, 52, 23, 42, 0, 33, 15, 37, 33, 33, 31, 37},
        &.{51, 23, 41, 62, 21, 55, 23, 33, 0, 29, 62, 46, 29, 51, 11},
        &.{55, 31, 29, 42, 46, 31, 31, 15, 29, 0, 51, 21, 41, 23, 37},
        &.{29, 41, 79, 21, 82, 33, 77, 37, 62, 51, 0, 65, 42, 59, 61},
        &.{74, 51, 21, 51, 58, 37, 37, 33, 46, 21, 65, 0, 61, 11, 55},
        &.{23, 11, 64, 51, 46, 51, 51, 33, 29, 41, 42, 61, 0, 62, 23},
        &.{72, 52, 31, 43, 65, 29, 46, 31, 51, 23, 59, 11, 62, 0, 59},
        &.{46, 21, 51, 64, 23, 59, 33, 37, 11, 37, 61, 55, 23, 59, 0},
        // zig fmt: on
    };

    for ([_][]const []const i64{ example_distances1, example_distances2 }) |distances| {
        const hk = HeldKarpAlgorithm.solve(allocator, distances);
        defer hk.deinit(allocator);

        try stdout_writer.print("{} cities, minimum tour cost: {}\n", .{ distances.len, hk.cost });
        try stdout_writer.writeAll("  tour:");
        for (hk.tour) |v|
            try stdout_writer.print(" {}", .{v});
        try stdout_writer.writeAll("\n\n");
    }

    try stdout_writer.flush();
}

const HeldKarpAlgorithm = struct {
    cost: i64,
    tour: []usize,

    /// Solve the Traveling Salesman Problem using the Held-Karp algorithm (O(n^2·2^n)).
    /// distances: 2D square matrix of pairwise distances, dist[i][j] is the cost from i to j.
    /// Evaluates to {min_cost, tour}, where tour is a sequence of node indices
    /// starting and ending at 0.
    fn solve(allocator: Allocator, distances: []const []const i64) HeldKarpAlgorithm {
        const n = distances.len;
        const N = @as(usize, 1) << @intCast(n); // Number of subsets: 2^n
        // ------------------------------------------------------
        const matrix1: Matrix2D(i64) = .init(allocator, N, n, std.math.maxInt(i64));
        defer matrix1.deinit(allocator);
        const matrix2: Matrix2D(?usize) = .init(allocator, N, n, null);
        defer matrix2.deinit(allocator);
        // ------------------------------------------------------
        // dp[mask][j] = min cost to start at 0, visit exactly the cities in mask, and end at j
        var dp: [][]i64 = matrix1.matrix;

        // parent[mask][j] = best predecessor of j in the optimal path for (mask, j)
        var parent: [][]?usize = matrix2.matrix;

        // Base case: mask=1<<0, at city 0, cost=0
        dp[1][0] = 0;

        // Build up DP table
        // Iterate over all subsets that include node 0
        for (1..N) |mask| {
            if ((mask & 1) == 0)
                continue; // we always include city 0 in the tour
            for (1..n) |j| {
                if ((mask & (@as(usize, 1) << @intCast(j))) == 0)
                    continue; // j not in subset
                const prev_mask = mask ^ (@as(usize, 1) << @intCast(j));
                // Try all possibilities of coming to j from some k in prev_mask
                for (0..n) |k|
                    if (prev_mask & (@as(usize, 1) << @intCast(k)) != 0) {
                        const cost, const overflow = @addWithOverflow(dp[prev_mask][k], distances[k][j]);
                        if (overflow == 0 and cost < dp[mask][j]) {
                            dp[mask][j] = cost;
                            parent[mask][j] = k;
                        }
                    };
            }
        }

        // Close the tour by returning to city 0
        const full_mask = N - 1;
        var min_cost: i64 = std.math.maxInt(i64);
        var last_city: ?usize = null;
        for (1..n) |j| {
            const cost = dp[full_mask][j] + distances[j][0];
            if (cost < min_cost) {
                min_cost = cost;
                last_city = j;
            }
        }

        // Reconstruct the optimal tour
        var tour: std.ArrayList(usize) = .empty;
        // defer tour.deinit(allocator); // not necessary because of toOwnedSlice()

        var cur_mask = full_mask;
        var cur_city = last_city;
        while (cur_city) |cur| {
            tour.append(allocator, cur) catch @panic("OOM");
            const p = parent[cur_mask][cur];
            cur_mask ^= (@as(usize, 1) << @intCast(cur));
            cur_city = p;
        }
        // Reverse the tour
        std.mem.reverse(usize, tour.items);
        // return to start
        tour.append(allocator, 0) catch @panic("OOM");

        return .{
            .cost = min_cost,
            .tour = tour.toOwnedSlice(allocator) catch @panic("OOM"),
        };
    }
    fn deinit(self: HeldKarpAlgorithm, allocator: Allocator) void {
        allocator.free(self.tour);
    }
};
// One line of Python becomes this...
fn Matrix2D(T: type) type {
    return struct {
        matrix: [][]T,
        backing_slice: []T,
        const Self = @This();

        fn init(allocator: Allocator, m: usize, n: usize, fill: T) Self {
            var backing_slice = allocator.alloc(T, m * n) catch @panic("OOM");
            @memset(backing_slice, fill);

            var start: usize = 0;
            const matrix = allocator.alloc([]T, m) catch @panic("OOM");
            for (matrix) |*row| {
                row.* = backing_slice[start .. start + n];
                start += n;
            }
            return .{
                .matrix = matrix,
                .backing_slice = backing_slice,
            };
        }
        fn deinit(self: Self, allocator: Allocator) void {
            allocator.free(self.matrix);
            allocator.free(self.backing_slice);
        }
    };
}
