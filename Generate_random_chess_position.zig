// https://rosettacode.org/wiki/Generate_random_chess_position
const std = @import("std");
const mem = std.mem;
const print = std.debug.print;

pub fn main() !void {
    // ------------------------------------------------ random number
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const rand = prng.random();
    // ---------------------------------------------------- allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------
    var board = Board.init(rand);
    _ = board.placeKings()
        .placePieces("PPPPPPPP", true)
        .placePieces("pppppppp", true)
        .placePieces("RNBQBNR", false)
        .placePieces("rnbqbnr", false);

    board.printBoard();
    // board.prettyPrintBoard();
    try board.printFen(allocator);
}

const Board = struct {
    grid: [8][8]u8,
    rand: std.Random,

    fn init(rand: std.Random) Board {
        return Board{
            .grid = [1][8]u8{[1]u8{'.'} ** 8} ** 8,
            .rand = rand,
        };
    }

    fn printBoard(self: Board) void {
        for (self.grid) |row| {
            for (row) |square|
                print("{c} ", .{square});
            print("\n", .{});
        }
    }

    fn prettyPrintBoard(self: Board) void {
        for (self.grid) |row| {
            for (row) |piece| {
                const pretty = switch (piece) {
                    '.' => ".",
                    'B' => "♗",
                    'K' => "♔",
                    'N' => "♘",
                    'P' => "♙",
                    'Q' => "♕",
                    'R' => "♖",
                    'b' => "♝",
                    'k' => "♚",
                    'n' => "♞",
                    'p' => "♟",
                    'q' => "♛",
                    'r' => "♜",
                    else => unreachable,
                };
                print("{s} ", .{pretty});
            }
            print("\n", .{});
        }
    }

    fn placeKings(self: *Board) *Board {
        while (true) {
            const r1 = self.rand.intRangeLessThan(usize, 0, 8);
            const c1 = self.rand.intRangeLessThan(usize, 0, 8);
            const r2 = self.rand.intRangeLessThan(usize, 0, 8);
            const c2 = self.rand.intRangeLessThan(usize, 0, 8);
            if ((@max(r1, r2) - @min(r1, r2)) > 1 and (@max(c1, c2) - @min(c1, c2)) > 1) {
                self.grid[r1][c1] = 'K';
                self.grid[r2][c2] = 'k';
                return self;
            }
        }
    }

    fn placePieces(self: *Board, pieces: []const u8, is_pawn: bool) *Board {
        const place_count = self.rand.intRangeLessThan(usize, 0, pieces.len);
        const lo: usize = if (is_pawn) 1 else 0;
        const hi: usize = if (is_pawn) 7 else 8;
        for (pieces[0..place_count]) |piece| {
            while (true) {
                const r = self.rand.intRangeLessThan(usize, lo, hi);
                const c = self.rand.intRangeLessThan(usize, 0, 8);
                if (self.grid[r][c] == '.') {
                    self.grid[r][c] = piece;
                    break;
                }
            }
        }
        return self;
    }

    fn printFen(self: Board, allocator: mem.Allocator) !void {
        var fen = std.ArrayList(u8).init(allocator);
        defer fen.deinit();
        var writer = fen.writer();

        var empty_count: u6 = 0;
        for (self.grid) |row| {
            for (row) |square| {
                if (square == '.')
                    empty_count += 1
                else {
                    if (empty_count > 0) {
                        try writer.print("{d}", .{empty_count});
                        empty_count = 0;
                    }
                    try writer.writeByte(square);
                }
            }
            if (empty_count > 0) {
                try writer.print("{d}", .{empty_count});
                empty_count = 0;
            }
            try writer.writeByte('/');
        }
        try writer.writeAll(" w - - 0 1");

        print("{s}\n", .{fen.items});
    }
};
