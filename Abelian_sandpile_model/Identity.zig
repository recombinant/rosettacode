// https://rosettacode.org/wiki/Abelian_sandpile_model/Identity
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var snapshots: std.ArrayList(SandPile) = .empty;
    // defer snapshots.deinit(); // not necessary, see toOwnedSlice()

    // Avalanche ------------------------------------------
    var s: SandPile = .{ .pile = .{ .{ 4, 3, 3 }, .{ 3, 1, 2 }, .{ 0, 2, 3 } } };
    try snapshots.append(allocator, s);

    // Stabilize the sand pile taking snapshots at each iteration.
    while (!s.isStable()) {
        s.topple();
        try snapshots.append(allocator, s);
    }
    const slice = try snapshots.toOwnedSlice(allocator);
    defer allocator.free(slice);

    try stdout.print("The piles demonstration avalanche:\n", .{});
    try printSlice(slice, stdout);
    // ----------------------------------------------------
    var s1: SandPile = .{ .pile = .{ .{ 1, 2, 0 }, .{ 2, 1, 1 }, .{ 0, 1, 3 } } };
    var s2: SandPile = .{ .pile = .{ .{ 2, 1, 3 }, .{ 1, 0, 1 }, .{ 0, 1, 0 } } };
    var s3: SandPile = .{ .pile = .{ .{ 3, 3, 3 }, .{ 3, 3, 3 }, .{ 3, 3, 3 } } };
    var s3_id: SandPile = .{ .pile = .{ .{ 2, 1, 2 }, .{ 1, 0, 1 }, .{ 2, 1, 2 } } };
    // s1 + s2 == s2 + s1 ---------------------------------
    try stdout.print("\nConfirm that \"s1 + s2 == s2 + s1\":\n", .{});
    try printSum(s1, s2, s1.add(s2), stdout);
    try stdout.writeByte('\n');
    try printSum(s2, s1, s2.add(s1), stdout);
    // s3 + s3_id == s3 -----------------------------------
    try stdout.print("\nThe piles in \"s3 + s3_id == s3\" are:\n", .{});
    try printSum(s3, s3_id, s3.add(s3_id), stdout);
    // s3_id + s3_id == s3_id -----------------------------
    try stdout.print("\nThe piles in \"s3_id + s3_id = s3_id\" are:\n", .{});
    try printSum(s3_id, s3_id, s3_id.add(s3_id), stdout);

    try stdout.flush();
}

const SandPile = struct {
    pile: [3][3]u16,

    /// Return true if the sandpile is stable, else false.
    fn isStable(self: *const SandPile) bool {
        for (self.pile) |row|
            for (row) |value|
                if (value > 3)
                    return false;
        return true;
    }

    /// Eliminate one value > 3, propagating a grain to each neighbor.
    fn topple(self: *SandPile) void {
        for (self.pile, 0..) |row, i|
            for (row, 0..) |value, j|
                if (value > 3) {
                    self.pile[i][j] -= 4;
                    var it = neighbors(i, j);
                    while (it.next()) |next|
                        self.pile[next.i][next.j] += 1;
                    return;
                };
    }

    /// Stabilize a sandpile.
    fn stabilize(sandPile: *SandPile) void {
        while (!sandPile.isStable())
            sandPile.topple();
    }

    /// Add two sandpiles, stabilizing the result.
    fn add(self: *const SandPile, other: SandPile) SandPile {
        var result: SandPile = undefined;
        for (0..3) |row|
            for (0..3) |col| {
                result.pile[row][col] = self.pile[row][col] + other.pile[row][col];
            };
        result.stabilize();
        return result;
    }

    fn printRow(self: *const SandPile, w: *std.Io.Writer, index: usize) !void {
        const row = &self.pile[index];
        try w.print("{d} {d} {d}", .{ row[0], row[1], row[2] });
    }

    const NeighborIterator = struct {
        const State = enum { one, two, three, four, complete };
        state: State = State.one,
        i: usize,
        j: usize,

        fn next(self: *NeighborIterator) ?struct { i: usize, j: usize } {
            while (true)
                switch (self.state) {
                    .one => {
                        self.state = .two;
                        if (self.i > 0)
                            return .{ .i = self.i - 1, .j = self.j };
                    },
                    .two => {
                        self.state = .three;
                        if (self.i < 2)
                            return .{ .i = self.i + 1, .j = self.j };
                    },
                    .three => {
                        self.state = .four;
                        if (self.j > 0)
                            return .{ .i = self.i, .j = self.j - 1 };
                    },
                    .four => {
                        self.state = .complete;
                        if (self.j < 2)
                            return .{ .i = self.i, .j = self.j + 1 };
                    },
                    .complete => return null,
                };
        }
    };

    fn neighbors(i: usize, j: usize) NeighborIterator {
        return NeighborIterator{ .i = i, .j = j };
    }
};

/// Print a slice of sand piles.
fn printSlice(slice: []SandPile, w: *std.Io.Writer) !void {
    for (0..3) |i| {
        for (slice, 0..) |sp, n| {
            if (n != 0)
                try w.print("{s}", .{if (i == 1) " ⇨ " else "   "});
            try sp.printRow(w, i);
        }
        try w.writeByte('\n');
    }
}

/// Print "s1 + s2 = s3".
fn printSum(s1: SandPile, s2: SandPile, s3: SandPile, w: *std.Io.Writer) !void {
    for (0..3) |i| {
        try s1.printRow(w, i);
        try w.writeAll(if (i == 1) " + " else "   ");
        try s2.printRow(w, i);
        try w.writeAll(if (i == 1) " = " else "   ");
        try s3.printRow(w, i);
        try w.writeByte('\n');
    }
}
