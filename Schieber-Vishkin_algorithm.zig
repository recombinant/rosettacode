// https://rosettacode.org/wiki/Schieber-Vishkin_algorithm
// {{works with|Zig|0.17.1}}
// copied from rosettacode and tweaked
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Io = std.Io;

const Node = struct {
    child: usize = 0,
    sib: usize = 0,
    parent: usize = 0,
};

const ProcessResult = struct {
    pi: []const usize,
    beta: []const usize,
    alfa: []const usize,
    tau: []const usize,
    lam: []const i32,

    fn deinit(self: ProcessResult, allocator: Allocator) void {
        allocator.free(self.pi);
        allocator.free(self.beta);
        allocator.free(self.alfa);
        allocator.free(self.tau);
        allocator.free(self.lam);
    }
    // Caller must call ProcessResult.deinit() to ProcessResult owned
    // slices.
    fn init(allocator: Allocator, n: usize, a: []i32) !ProcessResult {
        const pi = try allocator.alloc(usize, n + 1);
        const beta = try allocator.alloc(usize, n + 1);
        const alfa = try allocator.alloc(usize, n + 1);
        const tau = try allocator.alloc(usize, n + 1);
        const lam = try allocator.alloc(i32, n + 1);

        @memset(pi, 0);
        @memset(beta, 0);
        @memset(alfa, 0);
        @memset(tau, 0);
        @memset(lam, 0);

        lam[0] = -1;

        var nodes = try allocator.alloc(Node, n + 1);
        defer allocator.free(nodes);
        for (nodes) |*node|
            node.* = .{};

        // Make triply linked tree
        var t: usize = 0;
        var v: usize = n;
        while (v >= 1) : (v -= 1) {
            var u: usize = 0;
            while (a[v] > a[t] or (a[v] == a[t] and v > t)) {
                u = t;
                t = nodes[t].parent;
            }

            if (u != 0) {
                nodes[v].sib = nodes[u].sib;
                nodes[u].sib = 0;
                nodes[u].parent = v;
                nodes[v].child = u;
            } else {
                nodes[v].sib = nodes[t].child;
            }

            nodes[t].child = v;
            nodes[v].parent = t;
            t = v;
        }

        // Begin first traversal
        var p = nodes[0].child;
        var n_count: usize = 0;

        // First traversal loop
        while (true) {
            // s3: Compute beta in the easy case
            n_count += 1;
            pi[p] = n_count;
            tau[n_count] = 0;
            lam[n_count] = 1 + lam[n_count >> 1];

            if (nodes[p].child != 0) {
                p = nodes[p].child;
                continue;
            }

            beta[p] = n_count;

            // s4: Compute tau, bottom-up
            while (true) {
                tau[beta[p]] = nodes[p].parent;

                if (nodes[p].sib != 0) {
                    p = nodes[p].sib;
                    break; // Go back to s3
                }

                p = nodes[p].parent;

                // Compute beta in the hard case
                if (p != 0) {
                    const h = lam[(n_count & (~pi[p] + 1))];
                    beta[p] = ((n_count >> @intCast(h)) | 1) << @intCast(h);
                } else {
                    // Exit traversal
                    break;
                }
            }

            if (p == 0)
                break;
        }

        // Begin second traversal
        p = nodes[0].child;
        lam[0] = lam[n_count];
        pi[0] = 0;
        beta[0] = 0;
        alfa[0] = 0;

        // Perform second traversal
        if (p != 0)
            computeAlfa(p, nodes, alfa, beta);

        return .{
            .pi = pi,
            .beta = beta,
            .alfa = alfa,
            .tau = tau,
            .lam = lam,
        };
    }
    fn computeAlfa(p: usize, nodes: []const Node, alfa: []usize, beta: []const usize) void {
        // s7: Compute alfa, top-down
        alfa[p] = alfa[nodes[p].parent] | (beta[p] & (~beta[p] + 1));

        if (nodes[p].child != 0)
            computeAlfa(nodes[p].child, nodes, alfa, beta);

        // s8: Continue traversal
        if (nodes[p].sib != 0)
            computeAlfa(nodes[p].sib, nodes, alfa, beta);
    }
};

fn nca(
    x_param: usize,
    y_param: usize,
    pr: *const ProcessResult,
) usize {
    var x = x_param;
    var y = y_param;

    // Find common height
    var h = if (pr.beta[x] <= pr.beta[y])
        pr.lam[(pr.beta[y] & (~pr.beta[x] + 1))]
    else
        pr.lam[(pr.beta[x] & (~pr.beta[y] + 1))];

    // Find true height
    const k = pr.alfa[x] & pr.alfa[y] & (~(@as(usize, 1) << @intCast(h)) + 1);
    h = pr.lam[(k & (~k + 1))];

    // Find beta[z]
    const j = ((pr.beta[x] >> @intCast(h)) | 1) << @intCast(h);

    // Find x' and y'
    if (j != pr.beta[x]) {
        const l = pr.lam[(pr.alfa[x] & ((@as(usize, 1) << @intCast(h)) - 1))];
        x = pr.tau[((pr.beta[x] >> @intCast(l)) | 1) << @intCast(l)];
    }

    if (j != pr.beta[y]) {
        const l = pr.lam[(pr.alfa[y] & ((@as(usize, 1) << @intCast(h)) - 1))];
        y = pr.tau[((pr.beta[y] >> @intCast(l)) | 1) << @intCast(l)];
    }

    // Find z
    return if (pr.pi[x] <= pr.pi[y])
        x
    else
        y;
}

fn solveTestCase(
    io: Io,
    allocator: Allocator,
    n: usize,
    values: []const i32,
    queries: []const [2]usize,
) ![]const i32 {
    var a: ArrayList(i32) = .empty;
    defer a.deinit(allocator);
    try a.append(allocator, std.math.maxInt(i32)); // A[0]

    var r = try allocator.alloc(usize, n + 2);
    defer allocator.free(r);
    var b = try allocator.alloc(usize, n + 2);
    defer allocator.free(b);

    @memset(r, 0);
    @memset(b, 0);

    var big_n: usize = 1;
    var count: i32 = 0;
    var oldx: ?i32 = null;

    for (1..n + 1) |i| {
        const x = values[i - 1];

        if (i > 1 and (oldx == null or x != oldx.?)) {
            try a.append(allocator, count);
            r[big_n] = i;
            big_n += 1;
            count = 0;
        }

        b[i] = big_n;
        count += 1;
        oldx = x;
    }

    try a.append(allocator, count);
    r[big_n] = n + 1;

    const process_result: ProcessResult = try .init(allocator, big_n, a.items);
    defer process_result.deinit(allocator); // not necessary

    const results = try allocator.alloc(i32, queries.len);

    //
    var group: Io.Group = .init;
    for (queries, 0..) |query, idx|
        group.async(io, worker, .{ query, idx, a.items, b, r, &process_result, results });
    try group.await(io);

    return results;
}

fn worker(
    query: [2]usize,
    idx: usize,
    a: []const i32,
    b: []const usize,
    r: []const usize,
    pr: *const ProcessResult,
    results: []i32,
) void {
    const i = query[0];
    const j = query[1];
    const x = b[i];
    const y = b[j];

    const z = if (x == y)
        @as(i32, @intCast(j - i + 1))
    else blk: {
        var z_val: i32 = if (x + 1 != y)
            a[nca(x + 1, y - 1, pr)]
        else
            0;

        z_val = @max(z_val, @max(@as(i32, @intCast(r[x] - i)), a[y] - @as(i32, @intCast(r[y] - j - 1))));

        break :blk z_val;
    };
    results[idx] = z;
}

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout_writer = &stdout_file.interface;

    try stdout_writer.print("This application is {s}-threaded\n\n", .{if (@import("builtin").single_threaded) "single" else "multi"});

    // Hard-coded test data
    const TestCase = struct {
        n: usize,
        values: []const i32,
        queries: []const [2]usize,
        expected: []const i32,
    };

    const test_cases: []const TestCase = &.{
        .{
            .n = 10,
            .values = &.{ -1, -1, 1, 1, 1, 1, 3, 10, 10, 10 },
            .queries = &.{ .{ 2, 3 }, .{ 1, 10 }, .{ 5, 10 } },
            .expected = &.{ 1, 4, 3 },
        },
    };

    for (test_cases, 1..) |test_case, idx| {
        try stdout_writer.print("Test Case {}:\n", .{idx});
        try stdout_writer.print("Size: {}, Queries: {}\n", .{ test_case.n, test_case.queries.len });
        try stdout_writer.writeAll("Values: ");
        for (test_case.values) |v|
            try stdout_writer.print("{} ", .{v});
        try stdout_writer.writeByte('\n');

        const results = try solveTestCase(io, gpa, test_case.n, test_case.values, test_case.queries);
        defer gpa.free(results);

        try stdout_writer.writeAll("Queries and Results:\n");
        for (test_case.queries, 0..) |query, q_idx| {
            const i = query[0];
            const j = query[1];
            const result = results[q_idx];
            const exp = test_case.expected[q_idx];

            try stdout_writer.print("Query: {} {}\n", .{ i, j });
            try stdout_writer.print("Result: {} (Expected: {})\n", .{ result, exp });
            if (result != exp)
                std.log.warn("Result doesn't match expected output", .{});
        }
        try stdout_writer.writeByte('\n');
    }

    try stdout_writer.flush();
}
