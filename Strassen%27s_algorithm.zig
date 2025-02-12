// https://rosettacode.org/wiki/Strassen%27s_algorithm
// Translation of Go
const std = @import("std");
const fmt = std.fmt;
const heap = std.heap;
const mem = std.mem;
const print = std.debug.print;

pub fn main() !void {
    var fba = heap.GeneralPurposeAllocator(.{}){};
    defer _ = fba.deinit();
    const allocator = fba.allocator();

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const ephemeral_allocator = arena.allocator();

    const a = try Matrix(f64).initSet(allocator, 2, 2, &[_]f64{
        1, 2,
        3, 4,
    });
    defer a.deinit();
    const b = try Matrix(f64).initSet(allocator, 2, 2, &[_]f64{
        5, 6,
        7, 8,
    });
    defer b.deinit();
    const c = try Matrix(f64).initSet(allocator, 4, 4, &[_]f64{
        1, 1,  1,  1,
        2, 4,  8,  16,
        3, 9,  27, 81,
        4, 16, 64, 256,
    });
    defer c.deinit();
    const d = try Matrix(f64).initSet(allocator, 4, 4, &[_]f64{
        4,           -3,         4.0 / 3.0,  -1.0 / 4.0,
        -13.0 / 3.0, 19.0 / 4.0, -7.0 / 3.0, 11.0 / 24.0,
        3.0 / 2.0,   -2,         7.0 / 6.0,  -1.0 / 4.0,
        -1.0 / 6.0,  1.0 / 4.0,  -1.0 / 6.0, 1.0 / 24.0,
    });
    defer d.deinit();
    const e = try Matrix(f64).initSet(allocator, 4, 4, &[_]f64{
        1,  2,  3,  4,
        5,  6,  7,  8,
        9,  10, 11, 12,
        13, 14, 15, 16,
    });
    defer e.deinit();
    const f = try Matrix(f64).initSet(allocator, 4, 4, &[_]f64{
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    });
    defer f.deinit();

    print("Using 'normal' matrix multiplication:\n", .{});
    const m1 = try a.mul(b);
    defer m1.deinit();
    const m2 = try c.mul(d);
    defer m2.deinit();
    const m3 = try e.mul(f);
    defer m3.deinit();
    print("  a * b = {d}\n", .{m1});
    print("  c * d = {d:.0}\n", .{m2});
    print("  e * e = {d}\n", .{m3});

    print("\nUsing 'Strassen' matrix multiplication:\n", .{});

    // `ephemeral_allocator` is used for temporary allocations
    // where the allocations for temporary variables are out of
    // scope after strassen() returns.
    const s1 = try Matrix(f64).strassen(ephemeral_allocator, a, b);
    defer s1.deinit();
    _ = arena.reset(.retain_capacity);
    print("  a * b = {d}\n", .{s1});

    const s2 = try Matrix(f64).strassen(ephemeral_allocator, c, d);
    defer s2.deinit();
    _ = arena.reset(.retain_capacity);
    print("  c * d = {d:.0}\n", .{s2});

    const s3 = try Matrix(f64).strassen(ephemeral_allocator, e, f);
    defer s3.deinit();
    _ = arena.reset(.retain_capacity);
    print("  e * f = {d}\n", .{s3});
}

fn Matrix(comptime T: type) type {
    return struct {
        const Self = @This();
        allocator: mem.Allocator,
        rows: usize,
        cols: usize,
        data: []T,

        fn init(allocator: mem.Allocator, rows: usize, cols: usize) !Self {
            const data = try allocator.alloc(T, rows * cols);
            @memset(data, 0);
            return .{
                .allocator = allocator,
                .rows = rows,
                .cols = cols,
                .data = data,
            };
        }
        fn initSet(allocator: mem.Allocator, rows: usize, cols: usize, data: []const T) !Self {
            if (rows * cols != data.len)
                return error.MatrixDataLenIncorrect;
            return .{
                .allocator = allocator,
                .rows = rows,
                .cols = cols,
                .data = try allocator.dupe(T, data),
            };
        }
        fn deinit(self: Self) void {
            self.allocator.free(self.data);
        }
        pub fn format(value: Self, comptime fmt_: []const u8, options: fmt.FormatOptions, writer: anytype) !void {
            try writer.writeAll("[ ");
            for (0..value.rows, 0..) |row, i| {
                if (i != 0)
                    try writer.writeAll(", ");
                try writer.writeAll("[ ");
                const slice = value.data[row * value.cols .. (row + 1) * value.cols];
                for (slice, 0..) |cell, j| {
                    if (j != 0)
                        try writer.writeAll(", ");
                    try fmt.formatType(cell, fmt_, options, writer, 0);
                }
                try writer.writeAll(" ]");
            }
            try writer.writeAll(" ]");
        }

        fn at(self: Self, row: usize, col: usize) T {
            return self.data[row * self.cols + col];
        }
        fn setAt(self: *Self, row: usize, col: usize, value: T) void {
            self.data[row * self.cols + col] = value;
        }

        fn add(m: Self, m2: Self) Self {
            if (m.rows != m2.rows or m.cols != m2.cols) unreachable;
            var c = Self.init(m.allocator, m.rows, m.cols) catch unreachable;
            for (0..m.rows) |i|
                for (0..m.cols) |j|
                    c.setAt(i, j, m.at(i, j) + m2.at(i, j));
            return c;
        }
        fn sub(m: Self, m2: Self) Self {
            if (m.rows != m2.rows or m.cols != m2.cols) unreachable;
            var c = Self.init(m.allocator, m.rows, m.cols) catch unreachable;
            for (0..m.rows) |i|
                for (0..m.cols) |j|
                    c.setAt(i, j, m.at(i, j) - m2.at(i, j));
            return c;
        }
        fn mul(self: Self, other: Self) !Self {
            if (self.cols != other.rows)
                return error.CannotMultiplyMatrices;

            var m = try Self.init(self.allocator, self.rows, other.cols);
            for (0..self.rows) |row0| {
                const slice = m.data[row0 * other.cols .. (row0 + 1) * other.cols];
                for (slice, 0..) |*cell, col1|
                    for (0..other.rows) |row1| {
                        cell.* += self.at(row0, row1) * other.at(row1, col1);
                    };
            }
            return m;
        }

        fn strassen(ephemeral_allocator: mem.Allocator, a: Self, b: Self) !Self {
            if (a.rows != a.cols or b.rows != b.cols or a.rows != b.rows) return error.MatrixSizeMismatch;
            if (a.rows == 0 or (a.rows & (a.rows - 1)) != 0) return error.MatrixSizeNotPow2;
            if (a.rows == 1) return a.mul(b);
            const qa = try Self.toQuarters(ephemeral_allocator, a);
            const qb = try Self.toQuarters(ephemeral_allocator, b);
            const p1 = try Self.strassen(ephemeral_allocator, qa[1].sub(qa[3]), qb[2].add(qb[3]));
            const p2 = try Self.strassen(ephemeral_allocator, qa[0].add(qa[3]), qb[0].add(qb[3]));
            const p3 = try Self.strassen(ephemeral_allocator, qa[0].sub(qa[2]), qb[0].add(qb[1]));
            const p4 = try Self.strassen(ephemeral_allocator, qa[0].add(qa[1]), qb[3]);
            const p5 = try Self.strassen(ephemeral_allocator, qa[0], qb[1].sub(qb[3]));
            const p6 = try Self.strassen(ephemeral_allocator, qa[3], qb[2].sub(qb[0]));
            const p7 = try Self.strassen(ephemeral_allocator, qa[2].add(qa[3]), qb[0]);
            var q: [4]Matrix(T) = undefined;
            q[0] = p1.add(p2).sub(p4).add(p6);
            q[1] = p4.add(p5);
            q[2] = p6.add(p7);
            q[3] = p2.sub(p3).add(p5).sub(p7);
            return Self.fromQuarters(a.allocator, q);
        }

        fn toQuarters(ephemeral_allocator: mem.Allocator, m: Self) ![4]Self {
            const r = m.rows / 2;
            const c = m.cols / 2;
            const p = params(r, c);
            var quarters: [4]Matrix(T) = undefined;
            for (&quarters, 0..) |*q, k| {
                q.* = try Matrix(T).init(ephemeral_allocator, r, c);
                for (p[k][0]..p[k][1]) |i| {
                    for (p[k][2]..p[k][3]) |j|
                        q.setAt(i - p[k][4], j - p[k][5], m.at(i, j));
                }
            }
            return quarters;
        }

        fn fromQuarters(allocator: mem.Allocator, q: [4]Self) Self {
            var r = q[0].rows;
            var c = q[0].cols;
            const p = params(r, c);
            r *= 2;
            c *= 2;
            var m = Matrix(T).init(allocator, r, c) catch unreachable;
            for (0..4) |k|
                for (p[k][0]..p[k][1]) |i|
                    for (p[k][2]..p[k][3]) |j|
                        m.setAt(i, j, q[k].at(i - p[k][4], j - p[k][5]));
            return m;
        }

        fn params(r: usize, c: usize) [4][6]usize {
            return [4][6]usize{
                [6]usize{ 0, r, 0, c, 0, 0 },
                [6]usize{ 0, r, c, 2 * c, 0, c },
                [6]usize{ r, 2 * r, 0, c, r, 0 },
                [6]usize{ r, 2 * r, c, 2 * c, r, c },
            };
        }
    };
}
