// https://rosettacode.org/wiki/Maze_generation
const std = @import("std");
const mem = std.mem;
const print = std.debug.print;

pub fn main() void {
    var mg = MazeGenerator(8, 8).init();
    mg.generate(0, 0);
    mg.display();
}

fn MazeGenerator(comptime width: u16, comptime height: u16) type {
    return struct {
        grid: [width * height]?Cell = [1]?Cell{null} ** (width * height),
        rand: std.Random,

        // static struct to keep prng in scope
        const S = struct {
            var prng: std.Random.DefaultPrng = undefined;
            var rand: ?std.Random = null;
        };

        const Self = @This();
        fn init() Self {
            if (S.rand == null) {
                var seed: u64 = undefined;
                std.posix.getrandom(mem.asBytes(&seed)) catch unreachable;
                S.prng = std.Random.DefaultPrng.init(seed);
                S.rand = S.prng.random();
            }
            return Self{ .rand = S.rand.? };
        }
        fn generate(self: *Self, cx: u16, cy: u16) void {
            var compass = [4]Direction{ .n, .e, .s, .w };
            self.rand.shuffle(Direction, &compass);

            for (compass) |d| {
                if (isInside(cx, cy, d)) {
                    const nx = cx +% d.getDX();
                    const ny = cy +% d.getDY();
                    if (self.getCell(nx, ny) == null) {
                        self.setCellDirection(cx, cy, d);
                        self.setCellDirection(nx, ny, d.opposite());
                        self.generate(nx, ny);
                    }
                }
            }
        }
        fn display(self: Self) void {
            for (0..height) |j| {
                // draw the north edge
                for (0..width) |i| {
                    const cell = self.getCell(i, j);
                    const sep = if (cell != null and cell.?.n) "+---" else "+   ";
                    print("{s}", .{sep});
                }
                print("+\n", .{});
                // draw the west edge
                for (0..width) |i| {
                    const cell = self.getCell(i, j);
                    const sep = if (cell != null and cell.?.w) "|   " else "    ";
                    print("{s}", .{sep});
                }
                print("|\n", .{});
            }
            // draw the bottom line
            print("{s}+\n", .{"+---" ** width});
        }

        fn getCell(self: Self, x: usize, y: usize) ?Cell {
            return self.grid[x + y * width];
        }

        fn setCellDirection(self: *Self, x: usize, y: usize, d: Direction) void {
            const cell = &self.grid[x + y * width];
            if (cell.* == null)
                cell.* = Cell.init();
            cell.*.?.clearDirection(d);
        }

        fn isInside(x: usize, y: usize, d: Direction) bool {
            return switch (d) {
                .n => y > 0,
                .e => x < width - 1,
                .s => y < height - 1,
                .w => x > 0,
            };
        }
    };
}

const Direction = enum {
    n,
    e,
    s,
    w,

    fn opposite(d: Direction) Direction {
        return switch (d) {
            .n => .s,
            .e => .w,
            .s => .n,
            .w => .e,
        };
    }
    fn getDX(self: Direction) u16 {
        return switch (self) {
            .n, .s => 0,
            .e => 1,
            .w => @as(u16, 0) -% @as(u16, 1),
        };
    }
    fn getDY(self: Direction) u16 {
        return switch (self) {
            .n => @as(u16, 0) -% @as(u16, 1),
            .e, .w => 0,
            .s => 1,
        };
    }
};

const Cell = packed struct {
    n: bool,
    e: bool,
    s: bool,
    w: bool,

    fn init() Cell {
        return Cell{
            .n = true,
            .e = true,
            .s = true,
            .w = true,
        };
    }

    fn clearDirection(self: *Cell, d: Direction) void {
        switch (d) {
            .n => self.n = false,
            .e => self.e = false,
            .s => self.s = false,
            .w => self.w = false,
        }
    }
};
