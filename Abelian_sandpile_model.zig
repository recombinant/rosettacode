// https://rosettacode.org/wiki/Abelian_sandpile_model
pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize the sand pile.
    const init_val = try askInitVal();

    var sand_pile: SandPile = try .init(allocator, init_val);
    defer sand_pile.deinit();

    // Run the simulation.
    while (sand_pile.doOneStep()) {}

    if (sand_pile.side_len <= 20) try sand_pile.display(stdout, init_val);

    const name = try std.fmt.allocPrint(allocator, "abelian_sandpile_{d}.ppm", .{init_val});
    defer allocator.free(name);
    try sand_pile.writePpmFile(name);
    try stdout.print("PPM image written in \"{s}\".\n", .{name});
}

/// Abelian sandpile.
const SandPile = struct {
    allocator: mem.Allocator,
    tiles: []u32,
    side_len: usize, // sand pile is square
    boundary: struct { x0: usize, y0: usize, xn: usize, yn: usize },

    fn init(allocator: mem.Allocator, init_val: u32) !SandPile {
        const side_len = sideLength(init_val);

        const tiles = try allocator.alloc(u32, side_len * side_len);
        @memset(tiles, 0);

        const origin = @divTrunc(side_len, 2);
        var sand_pile = SandPile{
            .allocator = allocator,
            .tiles = tiles,
            .side_len = side_len,
            // The boundary is initially just the central tile which has all
            // the sand particles on it, however, as the algorithm progresses,
            // the boundary will expand as the sand particles flow.
            .boundary = .{ .x0 = origin, .y0 = origin, .xn = origin + 1, .yn = origin + 1 },
        };
        // We put the initial sand in the exact middle of the field. This isn't
        // necessary per se, but it ensures that the sand can fully topple.
        sand_pile.atPtr(origin, origin).* = init_val;
        return sand_pile;
    }
    fn deinit(self: *SandPile) void {
        self.allocator.free(self.tiles);
    }

    fn at(self: *const SandPile, x: usize, y: usize) u32 {
        return self.tiles[(self.side_len * y) + x];
    }
    fn atPtr(self: *const SandPile, x: usize, y: usize) *u32 {
        return &self.tiles[(self.side_len * y) + x];
    }

    /// Return the tile grid side length needed for "init_val" sand
    /// particles.
    fn sideLength(init_val: u32) u32 {
        const result: u32 = @intFromFloat(math.sqrt(@as(f64, @floatFromInt(init_val)) / 1.75) + 3);
        // Ensure that the returned value is odd.
        return result + (result & 1) ^ 1;
    }

    fn doOneStep(self: *SandPile) bool {
        var done = false;
        // The boundary restricts computation to occupied tiles.
        for (self.boundary.y0..self.boundary.yn) |y| {
            for (self.boundary.x0..self.boundary.xn) |x| {
                if (self.at(x, y) >= 4) {
                    const rem = @divFloor(self.at(x, y), 4);
                    self.atPtr(x, y).* = @mod(self.at(x, y), 4);

                    if (y - 1 >= 0) {
                        self.atPtr(x, y - 1).* += rem;
                        if (y == self.boundary.y0) self.boundary.y0 -= 1;
                    }
                    if (x - 1 >= 0) {
                        self.atPtr(x - 1, y).* += rem;
                        if (x == self.boundary.x0) self.boundary.x0 -= 1;
                    }
                    if (y + 1 < self.side_len) {
                        self.atPtr(x, y + 1).* += rem;
                        if (y == self.boundary.yn - 1) self.boundary.yn += 1;
                    }
                    if (x + 1 < self.side_len) {
                        self.atPtr(x + 1, y).* += rem;
                        if (x == self.boundary.xn - 1) self.boundary.xn += 1;
                    }
                    done = true;
                }
            }
        }
        return done;
    }

    /// Display the tile grid as a 2D array of tile values.
    fn display(self: *SandPile, writer: anytype, init_val: u32) !void {
        try writer.print("Starting with {d} particles.\n\n", .{init_val});

        for (0..self.side_len) |y| {
            for (0..self.side_len) |x| try writer.print("{d:2}", .{self.at(x, y)});
            try writer.print("\n", .{});
        }
        try writer.print("\n", .{});
    }

    /// Colors to use for PPM files.
    const Colors: [4]struct { r: u8, g: u8, b: u8 } = .{
        .{ .r = 100, .g = 40, .b = 15 },
        .{ .r = 117, .g = 87, .b = 30 },
        .{ .r = 181, .g = 134, .b = 47 },
        .{ .r = 245, .g = 182, .b = 66 },
    };

    /// Write the tile grid representation in a PPM file.
    fn writePpmFile(self: SandPile, name: []const u8) !void {
        var file = try std.fs.cwd().createFile(name, .{});
        defer file.close();

        var bw = std.io.bufferedWriter(file.writer());
        var out = bw.writer();

        // P6 (binary) NetPDM file
        try out.print("P6 {d} {d}\n", .{ self.side_len, self.side_len });
        try out.print("255\n", .{});
        for (self.tiles) |value| {
            try out.writeByte(Colors[value].r);
            try out.writeByte(Colors[value].g);
            try out.writeByte(Colors[value].b);
        }

        // // P3 (ASCII) NetPBM file
        // try out.print("P3 {d} {d}\n", .{ self.side_len, self.side_len });
        // try out.print("# {s}\n", .{name});
        // try out.print("255\n", .{});
        // for (self.tiles, 0..) |value, i| {
        //     if (i % self.side_len == 0) try out.writeByte('\n');
        //     for (Colors[value]) |c| try out.print("{d} ", .{c});
        // }

        try bw.flush();
    }
};

/// Ask user for the number of sand particles.
fn askInitVal() !u32 {
    const stderr = std.io.getStdErr().writer();
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    const len = comptime math.log10_int(@as(u32, math.maxInt(u32))) + 2;
    var buf: [len]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    while (true) {
        fbs.reset();
        try stdout.print("Number of particles? ", .{});
        stdin.streamUntilDelimiter(fbs.writer(), '\n', fbs.buffer.len) catch |e| {
            switch (e) {
                error.StreamTooLong => {
                    while (try stdin.readByte() != '\n') {}
                    try stderr.print("Invalid input\n", .{});
                    continue; // await further input
                },
                else => return e,
            }
        };
        const output = mem.trim(u8, fbs.getWritten(), "\r\n\t ");
        if (std.fmt.parseInt(u32, output, 10)) |number| {
            if (number < 4) {
                try stderr.print("Value expected in range: 4..{d}\n", .{math.maxInt(u32)});
                continue; // await further input
            }
            return number;
        } else |_| try stderr.print("Invalid input\n", .{});
        // await further input
    }
}

const std = @import("std");
const math = std.math;
const mem = std.mem;
