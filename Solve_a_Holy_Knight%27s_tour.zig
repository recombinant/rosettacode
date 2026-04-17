// https://rosettacode.org/wiki/Solve_a_Holy_Knight%27s_tour
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;
const assert = std.debug.assert;

const board1 =
    " xxx    " ++
    " x xx   " ++
    " xxxxxxx" ++
    "xxx  x x" ++
    "x x  xxx" ++
    "sxxxxxx " ++
    "  xx x  " ++
    "   xxx  ";

const board2 =
    ".....s.x....." ++
    ".....x.x....." ++
    "....xxxxx...." ++
    ".....xxx....." ++
    "..x..x.x..x.." ++
    "xxxxx...xxxxx" ++
    "..xx.....xx.." ++
    "xxxxx...xxxxx" ++
    "..x..x.x..x.." ++
    ".....xxx....." ++
    "....xxxxx...." ++
    ".....x.x....." ++
    ".....x.x.....";

pub fn main(init: std.process.Init) anyerror!void {
    const io: Io = init.io;

    // unbuffered
    var stderr_writer = Io.File.stderr().writer(io, &.{});
    const stderr = &stderr_writer.interface;
    // buffered
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    findSolution(8, board1, stdout) catch |err| {
        switch (err) {
            SolutionError.CannotSolve => try stderr.print("Cannot solve this puzzle!", .{}),
            else => return err,
        }
    };
    try stdout.flush();

    try stdout.writeByte('\n');
    findSolution(13, board2, stdout) catch |err| {
        switch (err) {
            SolutionError.CannotSolve => try stderr.print("Cannot solve this puzzle!", .{}),
            else => return err,
        }
    };
    try stdout.flush();
}

// This could have been a member of BoardState - it is here to demonstrate uses
// of Zig comptime
fn solve(comptime sz: usize, pz: *BoardState(sz), sx: usize, sy: usize, idx: u9, cnt: usize) bool {
    if (idx > cnt) return true;

    const moves = comptime [8]struct { x: i3, y: i3 }{
        .{ .x = -1, .y = -2 }, .{ .x = 1, .y = -2 },
        .{ .x = -1, .y = 2 },  .{ .x = 1, .y = 2 },
        .{ .x = -2, .y = -1 }, .{ .x = 2, .y = -1 },
        .{ .x = -2, .y = 1 },  .{ .x = 2, .y = 1 },
    };

    for (moves) |mv| {
        const ix = @as(isize, @bitCast(sx)) + mv.x;
        const iy = @as(isize, @bitCast(sy)) + mv.y;
        if (ix >= 0 and ix < sz and iy >= 0 and iy < sz) {
            const x: usize = @bitCast(ix);
            const y: usize = @bitCast(iy);
            switch (pz.at(x, y).*) {
                .available => {
                    pz.at(x, y).* = SquareType{ .index = idx };
                    if (solve(sz, pz, x, y, idx + 1, cnt)) return true;
                    pz.at(x, y).* = SquareType.available;
                },
                .index, .blocked => {},
            }
        }
    }
    return false;
}

// Zig enum
const SquareTypeTag = enum {
    blocked,
    available,
    index,
};
// Zig tagged union
const SquareType = union(SquareTypeTag) {
    blocked: void,
    available: void,
    index: u9,
};

/// State of each square on the board.
/// Each square is a SquareType.
fn BoardState(comptime sz: usize) type {
    return struct {
        const Self = @This();
        pz: [sz * sz]SquareType = undefined,

        /// Setter/Getter.
        fn at(self: *Self, x: usize, y: usize) *SquareType {
            return &self.pz[y * sz + x];
        }

        const PopulateError = error{
            StartNotFound,
            StartDuplicated,
        };
        /// Populate the board state from the board.
        /// Return the starting point and the unblocked square count.
        fn populate(self: *Self, board: []const u8) PopulateError!struct { x: usize, y: usize, cnt: usize } {
            assert(board.len == sz * sz);
            var start_located = false;
            var x: usize = undefined;
            var y: usize = undefined;
            var idx: u9 = 0;
            var cnt: usize = sz * sz; // will be the count of squares that are NOT blocked.
            for (0..sz) |j| {
                for (0..sz) |i| {
                    self.at(i, j).* = switch (board[idx]) {
                        'x' => SquareType.available,
                        's' => blk: {
                            if (start_located)
                                return PopulateError.StartDuplicated;
                            start_located = true;
                            x = i;
                            y = j;
                            break :blk SquareType{ .index = 1 };
                        },
                        else => blk: {
                            cnt -= 1;
                            break :blk SquareType.blocked;
                        },
                    };
                    idx += 1;
                }
            }
            if (start_located)
                return .{ .x = x, .y = y, .cnt = cnt }
            else
                return PopulateError.StartNotFound;
        }
    };
}

const SolutionError = error{
    CannotSolve,
};
fn findSolution(comptime sz: usize, board: []const u8, w: *Io.Writer) anyerror!void {
    var pz: BoardState(sz) = .{};

    const start = try pz.populate(board);

    if (solve(sz, &pz, start.x, start.y, 2, start.cnt)) {
        for (0..sz) |j| {
            for (0..sz) |i|
                switch (pz.at(i, j).*) {
                    .index => |n| try w.print("{d:0>2}  ", .{n}),
                    .blocked => try w.print("--  ", .{}),
                    .available => unreachable,
                };
            try w.writeByte('\n');
        }
        return;
    } else {
        return SolutionError.CannotSolve;
    }
}
