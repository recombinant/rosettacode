// https://rosettacode.org/wiki/Abelian_sandpile_model
// {{works with|Zig|0.15.1}}
const std = @import("std");

const PPM = enum { P3, P6 }; // NetPBM formats
const ppm = PPM.P3;

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

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

    try stdout.flush();
}

/// Abelian sandpile.
const SandPile = struct {
    allocator: std.mem.Allocator,
    tiles: []u32,
    side_len: usize, // sand pile is square
    boundary: struct { x0: usize, y0: usize, xn: usize, yn: usize },

    fn init(allocator: std.mem.Allocator, init_val: u32) !SandPile {
        const side_len = sideLength(init_val);

        const tiles = try allocator.alloc(u32, side_len * side_len);
        @memset(tiles, 0);

        const origin = @divTrunc(side_len, 2);
        var sand_pile: SandPile = .{
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

    /// Return the tile grid side length needed for "init_val" sand particles.
    fn sideLength(init_val: u32) u32 {
        const result: u32 = @intFromFloat(std.math.sqrt(@as(f64, @floatFromInt(init_val)) / 1.75) + 3);
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
    fn display(self: *SandPile, w: *std.Io.Writer, init_val: u32) !void {
        try w.print("Starting with {d} particles.\n\n", .{init_val});

        for (0..self.side_len) |y| {
            for (0..self.side_len) |x| try w.print("{d:2}", .{self.at(x, y)});
            try w.writeByte('\n');
        }
        try w.writeByte('\n');
    }

    /// Colors to use for PPM files.
    const colors: [4]struct { r: u8, g: u8, b: u8 } = .{
        .{ .r = 100, .g = 40, .b = 15 },
        .{ .r = 117, .g = 87, .b = 30 },
        .{ .r = 181, .g = 134, .b = 47 },
        .{ .r = 245, .g = 182, .b = 66 },
    };

    /// Write the tile grid representation in a PPM file.
    fn writePpmFile(self: SandPile, name: []const u8) !void {
        var file = try std.fs.cwd().createFile(name, .{});
        defer file.close();

        var buffer: [4096]u8 = undefined;
        var file_writer = file.writer(&buffer);
        const w = &file_writer.interface;

        switch (ppm) {
            .P3 => { // P3 (ASCII) NetPBM file
                try w.print("P3 {d} {d}\n", .{ self.side_len, self.side_len });
                try w.print("# {s}\n", .{name});
                try w.print("255\n", .{});
                for (self.tiles, 0..) |value, i| {
                    if (i % self.side_len == 0) try w.writeByte('\n');
                    const c = colors[value];
                    try w.print("{d} {d} {d}\n", .{ c.r, c.g, c.b });
                }
            },
            .P6 => { // P6 (binary) NetPDM file
                try w.print("P6 {d} {d}\n", .{ self.side_len, self.side_len });
                try w.print("255\n", .{});
                for (self.tiles) |value| {
                    try w.writeByte(colors[value].r);
                    try w.writeByte(colors[value].g);
                    try w.writeByte(colors[value].b);
                }
            },
        }
        try w.flush();
    }
};

/// Ask user for the number of sand particles.
fn askInitVal() !u32 {
    var stderr_buffer: [1024]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
    const stderr = &stderr_writer.interface;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var stdin_buffer: [512]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;

    const len = comptime std.math.log10_int(@as(u32, std.math.maxInt(u32))) + 2;
    var buf: [len]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);

    while (true) {
        _ = w.consumeAll();

        try stdout.print("Number of particles? ", .{});
        try stdout.flush();

        _ = try stdin.streamDelimiter(&w, '\n');
        _ = try stdin.takeByte(); // consume the '\n'

        const output = std.mem.trim(u8, w.buffered(), "\r\n\t ");
        if (output.len == 0) {
            try stderr.print("No input\n", .{});
            try stderr.flush();
            continue; // await further input
        }
        if (std.fmt.parseInt(u32, output, 10)) |number| {
            if (number < 4) {
                try stderr.print("Value expected in range: 4..{d}\n", .{std.math.maxInt(u32)});
                try stderr.flush();
                continue; // await further input
            }
            return number;
        } else |_| {
            try stderr.print("Invalid input\n", .{});
            try stderr.flush();
        }
        // await further input
    }
}
