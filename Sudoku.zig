// https://rosettacode.org/wiki/Sudoku
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    const problem = [_]u8{
        8, 5, 0, 0, 0, 2, 4, 0, 0,
        7, 2, 0, 0, 0, 0, 0, 0, 9,
        0, 0, 4, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 1, 0, 7, 0, 0, 2,
        3, 0, 5, 0, 0, 0, 9, 0, 0,
        0, 4, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 8, 0, 0, 7, 0,
        0, 1, 7, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 3, 6, 0, 4, 0,
    };
    var sudoku: Sudoku = .init(problem);

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    if (sudoku.solve())
        try stdout.print("{f}", .{sudoku})
    else
        std.log.err("unsolvable puzzle", .{});

    try stdout.flush();
}

const Sudoku = struct {
    grid: [9 * 9]u8,

    fn init(grid: [9 * 9]u8) Sudoku {
        return .{ .grid = grid };
    }
    fn isValid(self: *Sudoku, i: usize, v: u8) bool {
        {
            // validate columns
            var j = i % 9;
            while (j < 81) : (j += 9)
                if (self.grid[j] == v)
                    return false;
        }
        {
            // validate rows
            const row_start = i - (i % 9);
            for (row_start..row_start + 9) |j|
                if (self.grid[j] == v)
                    return false;
        }
        {
            // validate 3x3 blocks
            var j = i - (i % 3) - 9 * ((i / 9) % 3);
            var k: usize = 0;
            while (k < 9) : ({
                k += 1;
                j += if (k % 3 != 0) 1 else 7;
            }) {
                if (self.grid[j] == v)
                    return false;
            }
        }
        return true;
    }
    fn backtrack(self: *Sudoku, i: usize) bool {
        var v: u8 = 9;
        while (v > 0) : (v -= 1) {
            if (!self.isValid(i, v))
                continue;
            self.grid[i] = v;

            if (self.backtrack(i + (std.mem.indexOfScalar(u8, self.grid[i..], 0) orelse return true)))
                return true;
        }
        self.grid[i] = 0;
        return false;
    }
    pub fn format(self: *const Sudoku, w: *std.Io.Writer) std.Io.Writer.Error!void {
        for (0..9) |y| {
            for (0..9) |x| {
                if (x != 0) try w.writeByte(' ');
                try w.writeByte(self.grid[9 * y + x] + '0');
            }
            try w.writeByte('\n');
        }
    }
    fn solve(self: *Sudoku) bool {
        return self.backtrack(std.mem.indexOfScalar(u8, &self.grid, 0) orelse return true);
    }
};
