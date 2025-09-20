// https://rosettacode.org/wiki/Solve_triangle_solitaire_puzzle
// {{works with|Zig|0.15.1}}
// {{trans|Kotlin}}
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var board: Board = .init();

    var solutions: std.ArrayList(Solution) = .empty;
    defer solutions.deinit(allocator);

    // run once to get solutions
    const empty_start = 1;
    board.start(empty_start); // starting with peg 1 removed
    try board.solve(allocator, &solutions);
    std.debug.assert(board.isSolved());

    // restart & replay solutions printing the board
    board.start(empty_start);
    try board.drawBoard(stdout);
    try stdout.print("Starting with peg {X} removed\n", .{empty_start});
    for (solutions.items) |solution| {
        board.replayMove(solution);
        try stdout.writeByte('\n');
        try board.drawBoard(stdout);
        try stdout.print(
            "Peg {X} jumped over {X} to land on {X}\n",
            .{ solution.peg, solution.over, solution.land },
        );
    }

    try stdout.flush();
}

const Solution = struct {
    peg: u5,
    over: u5,
    land: u5,
    fn init(peg: u5, over: u5, land: u5) Solution {
        return Solution{ .peg = peg, .over = over, .land = land };
    }
};
const Board = struct {
    board: [16]bool,

    const jump_moves: []const []const [2]u5 = &[_][]const [2]u5{
        &[_][2]u5{},
        &[_][2]u5{ .{ 2, 4 }, .{ 3, 6 } },
        &[_][2]u5{ .{ 4, 7 }, .{ 5, 9 } },
        &[_][2]u5{ .{ 5, 8 }, .{ 6, 10 } },
        &[_][2]u5{ .{ 2, 1 }, .{ 5, 6 }, .{ 7, 11 }, .{ 8, 13 } },
        &[_][2]u5{ .{ 8, 12 }, .{ 9, 14 } },
        &[_][2]u5{ .{ 3, 1 }, .{ 5, 4 }, .{ 9, 13 }, .{ 10, 15 } },
        &[_][2]u5{ .{ 4, 2 }, .{ 8, 9 } },
        &[_][2]u5{ .{ 5, 3 }, .{ 9, 10 } },
        &[_][2]u5{ .{ 5, 2 }, .{ 8, 7 } },
        &[_][2]u5{.{ 9, 8 }},
        &[_][2]u5{.{ 12, 13 }},
        &[_][2]u5{ .{ 8, 5 }, .{ 13, 14 } },
        &[_][2]u5{ .{ 8, 4 }, .{ 9, 6 }, .{ 12, 11 }, .{ 14, 15 } },
        &[_][2]u5{ .{ 9, 5 }, .{ 13, 12 } },
        &[_][2]u5{ .{ 10, 6 }, .{ 14, 13 } },
    };

    fn init() Board {
        var b: Board = .{ .board = undefined };
        b.clear();
        return b;
    }
    fn clear(self: *Board) void {
        @memset(&self.board, true);
        self.board[0] = false; // board[0] is not used
    }
    fn start(self: *Board, empty_start: u5) void {
        self.clear();
        self.board[empty_start] = false;
    }
    fn replayMove(self: *Board, solution: Solution) void {
        self.board[solution.peg] = false;
        self.board[solution.over] = false;
        self.board[solution.land] = true;
    }
    /// Recursive function to solve the puzzle
    fn solve(self: *Board, allocator: std.mem.Allocator, solutions: *std.ArrayList(Solution)) !void {
        if (isSolved(self))
            return;
        for (1..self.board.len) |peg| {
            if (self.board[peg]) {
                for (jump_moves[peg]) |ol| {
                    const over, const land = ol;
                    if (self.board[over] and !self.board[land]) {
                        const save_board = self.board;
                        self.board[peg] = false;
                        self.board[over] = false;
                        self.board[land] = true;
                        try solutions.append(allocator, Solution.init(@truncate(peg), over, land));
                        try solve(self, allocator, solutions);
                        if (self.isSolved())
                            return;
                        // otherwise back-track
                        self.board = save_board;
                        _ = solutions.pop();
                    }
                }
            }
        }
    }
    fn isSolved(self: *const Board) bool {
        var count: usize = 0;
        for (self.board) |peg|
            count += @intFromBool(peg);
        return count == 1; // just one peg left
    }
    fn drawBoard(self: *const Board, w: *std.Io.Writer) !void {
        var pegs: [16]u8 = undefined;
        @memset(&pegs, '-');
        for (self.board, &pegs, 0..) |peg, *s, i|
            if (peg) {
                s.* = if (i < 10) '0' else 'A' - 10;
                s.* += @truncate(i);
            };
        try w.print("       {c}\n", .{pegs[1]});
        try w.print("      {c} {c}\n", .{ pegs[2], pegs[3] });
        try w.print("     {c} {c} {c}\n", .{ pegs[4], pegs[5], pegs[6] });
        try w.print("    {c} {c} {c} {c}\n", .{ pegs[7], pegs[8], pegs[9], pegs[10] });
        try w.print("   {c} {c} {c} {c} {c}\n", .{ pegs[11], pegs[12], pegs[13], pegs[14], pegs[15] });
    }
};
