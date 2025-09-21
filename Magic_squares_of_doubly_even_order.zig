// https://www.rosettacode.org/wiki/Magic_squares_of_doubly_even_order
// {{works with|Zig|0.15.1}}
// {{trans|Java}}
// {{trans|Kotlin}}
const std = @import("std");

pub fn main() !void {
    // ------------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ---------------------------------------------------- allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------
    const n: u16 = 8;
    const magic: MagicSquareDoublyEven = try .init(allocator, n);
    defer magic.deinit();

    for (magic.m) |row| {
        for (row) |i| try stdout.print("{d:4}", .{i});
        try stdout.writeByte('\n');
    }
    try stdout.print("\nMagic constant: {}\n", .{(n * n + 1) * n / 2});
    // ------------------------------------------------------- stdout
    try stdout.flush();
}

const MagicSquareError = error{
    BaseNotMultipleOfFour,
};

const MagicSquareDoublyEven = struct {
    cells: []u16,
    m: [][]u16,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, n: u16) !MagicSquareDoublyEven {
        if (n < 4 or n % 4 != 0)
            return MagicSquareError.BaseNotMultipleOfFour;

        // pattern of count-up vs count-down zones
        const bits = 0b1001_0110_0110_1001;
        const grid_size = n * n;
        const mult = n / 4; // how many multiples of 4

        var cells = try allocator.alloc(u16, n * n);
        errdefer allocator.free(cells);

        var m = try allocator.alloc([]u16, n);
        // each row is a separate slice of 'cells'
        for (m, 0..) |*row, i|
            row.* = cells[n * i .. n * (i + 1)];

        var i: u16 = 0;
        for (0..n) |row| {
            for (0..n) |col| {
                const bit_pos = (col / mult) + (row / mult) * 4;
                m[row][col] = if (bits & std.math.shl(usize, 1, bit_pos) != 0) i + 1 else grid_size - i;
                i += 1;
            }
        }
        return MagicSquareDoublyEven{
            .cells = cells,
            .m = m,
            .allocator = allocator,
        };
    }

    fn deinit(self: *const MagicSquareDoublyEven) void {
        self.allocator.free(self.m);
        self.allocator.free(self.cells);
    }
};
