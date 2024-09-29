// https://www.rosettacode.org/wiki/Magic_squares_of_singly_even_order
// Translated from C
// Usage : executable <integer specifying rows in magic square>
const std = @import("std");
const mem = std.mem;

const MagicError = error{
    CountArgumentNotInteger,
    MissingCountArgument,
    BaseLessThanSix,
    BaseNotMultipleOfFourPlusTwo,
    OddBaseLessThanThree,
    OddBaseIsEven,
};

pub fn main() !void {
    // ------------------------------------------------------- stdout
    const stdout = std.io.getStdOut().writer();
    // ---------------------------------------------------- allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ---------------------------------------------------
    const n: u16 = try getN(allocator);

    const magic = try SinglyEvenMagicSquare.init(allocator, n);
    defer magic.deinit();

    for (magic.m) |row| {
        for (row) |i| try stdout.print("{d:4}", .{i});
        try stdout.writeByte('\n');
    }
    try stdout.print("\nMagic constant: {}\n", .{(n * n + 1) * n / 2});
}

const SinglyEvenMagicSquare = struct {
    cells: []u16,
    m: [][]u16,
    allocator: mem.Allocator,

    fn init(allocator: mem.Allocator, n: u16) !SinglyEvenMagicSquare {
        if (n < 6)
            return MagicError.BaseLessThanSix;
        if ((n - 2) % 4 != 0)
            return MagicError.BaseNotMultipleOfFourPlusTwo;

        const size = n * n;
        const half_n = n / 2;
        const sub_grid_size = size / 4;

        const sub_grid = try OddMagicSquare.init(allocator, half_n);
        defer sub_grid.deinit();

        const grid_factors = [_]u16{ 0, 2, 3, 1 };

        var cells = try allocator.alloc(u16, n * n);
        errdefer allocator.free(cells);

        var m = try allocator.alloc([]u16, n);
        for (m, 0..) |*row, i|
            row.* = cells[n * i .. n * (i + 1)];

        for (0..n) |r|
            for (0..n) |c| {
                const grid = (r / half_n) * 2 + (c / half_n);
                m[r][c] = sub_grid.m[r % half_n][c % half_n];
                m[r][c] += grid_factors[grid] * sub_grid_size;
            };

        const nColsLeft = half_n / 2;
        const nColsRight = nColsLeft - 1;

        for (0..half_n) |r|
            for (0..n) |c| {
                if (c < nColsLeft or c >= n - nColsRight or (c == nColsLeft and r == nColsLeft)) {
                    if (c == 0 and r == nColsLeft)
                        continue;
                    mem.swap(u16, &m[r][c], &m[r + half_n][c]);
                }
            };

        return SinglyEvenMagicSquare{
            .cells = cells,
            .m = m,
            .allocator = allocator,
        };
    }

    fn deinit(self: *const SinglyEvenMagicSquare) void {
        self.allocator.free(self.m);
        self.allocator.free(self.cells);
    }
};

const OddMagicSquare = struct {
    cells: []u16,
    m: [][]u16,
    allocator: mem.Allocator,

    fn init(allocator: mem.Allocator, n: u16) !OddMagicSquare {
        if (n < 3)
            return MagicError.OddBaseLessThanThree;
        if (n % 2 == 0)
            return MagicError.OddBaseIsEven;

        const squareSize = n * n;

        var cells = try allocator.alloc(u16, n * n);
        errdefer allocator.free(cells);
        @memset(cells, 0);

        var m = try allocator.alloc([]u16, n);
        for (m, 0..) |*row, i|
            row.* = cells[n * i .. n * (i + 1)];

        var r: usize = 0;
        var c = n / 2;
        var value: u16 = 1;
        while (value <= squareSize) {
            m[r][c] = value;
            value += 1;

            if (r == 0) {
                if (c == n - 1) {
                    r += 1;
                } else {
                    r = n - 1;
                    c += 1;
                }
            } else if (c == n - 1) {
                r -= 1;
                c = 0;
            } else if (m[r - 1][c + 1] == 0) {
                r -= 1;
                c += 1;
            } else {
                r += 1;
            }
        }
        return OddMagicSquare{
            .cells = cells,
            .m = m,
            .allocator = allocator,
        };
    }
    fn deinit(self: *const OddMagicSquare) void {
        self.allocator.free(self.m);
        self.allocator.free(self.cells);
    }
};

/// Get the square dimension from the command line.
fn getN(allocator: mem.Allocator) !u16 {
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.skip(); // current program
    //
    if (args.next()) |count_string| {
        const n = std.fmt.parseInt(u16, count_string, 10) catch
            return MagicError.CountArgumentNotInteger;
        return n; // ------------------- column / row count
    } else {
        return MagicError.MissingCountArgument;
    }
}
