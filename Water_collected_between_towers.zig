// https://rosettacode.org/wiki/Water_collected_between_towers
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const blocks = [_][]const u7{
        &[_]u7{ 1, 5, 3, 7, 2 },
        &[_]u7{ 5, 3, 7, 2, 6, 4, 5, 9, 1, 2 },
        &[_]u7{ 2, 6, 3, 5, 2, 8, 1, 4, 2, 2, 5, 3, 5, 7, 4, 1 },
        &[_]u7{ 5, 5, 5, 5 },
        &[_]u7{ 5, 6, 7, 8 },
        &[_]u7{ 8, 7, 7, 6 },
        &[_]u7{ 6, 7, 10, 7, 6 },
    };
    for (blocks) |block| {
        var table: Table = try .init(allocator, block);
        defer table.deinit();

        const water = table.fill();
        try table.printTable(stdout);

        try stdout.print("{} water units.\n\n", .{water});
    }
    try stdout.flush();
}

const Status = enum { empty, wall, water };

// 9               ██
// 8               ██
// 7     ██≈≈≈≈≈≈≈≈██
// 6     ██≈≈██≈≈≈≈██
// 5 ██≈≈██≈≈██≈≈████
// 4 ██≈≈██≈≈████████
// 3 ██████≈≈████████
// 2 ████████████████≈≈██
// 1 ████████████████████

// ↑ rows
// → columns
const Table = struct {
    allocator: std.mem.Allocator,
    array: []Status,
    width: usize,
    height: usize,

    fn init(allocator: std.mem.Allocator, block: []const u7) !Table {
        const width = block.len;
        const height = blk: {
            var max_height: u7 = std.math.minInt(u7);
            for (block) |height|
                if (height > max_height) {
                    max_height = height;
                };
            break :blk max_height;
        };
        const table_array = try allocator.alloc(Status, width * height);
        // build the walls
        var index: usize = 0;
        for (0..height) |row|
            for (0..width) |col| {
                table_array[index] = if (block[col] > row) .wall else .empty;
                index += 1;
            };
        return Table{
            .allocator = allocator,
            .array = table_array,
            .height = height,
            .width = width,
        };
    }
    fn deinit(self: *Table) void {
        self.allocator.free(self.array);
    }
    fn fill(self: *Table) usize {
        var water: usize = 0;

        for (0..self.height) |row| {
            var slice = self.getRowSlice(row);
            // first wall from the left
            if (std.mem.indexOfScalar(Status, slice, .wall)) |left| {
                // first wall from the right
                const right = std.mem.lastIndexOfScalar(Status, slice, .wall).?;
                if (right - left < 2)
                    break;

                var col = left + 1;
                while (col != right) : (col += 1)
                    if (slice[col] == .empty) {
                        slice[col] = .water;
                        water += 1;
                    };
            } else {
                break; // row has no walls, complete
            }
        }
        return water;
    }
    fn getRowSlice(self: *const Table, row: usize) []Status {
        const offset = row * self.width;
        return self.array[offset .. offset + self.width];
    }
    fn printTable(self: Table, w: *std.Io.Writer) !void {
        var row = self.height;
        while (row != 0) {
            try w.print("{d:2} ", .{row});
            row -= 1;
            const slice = self.getRowSlice(row);
            for (slice) |status| {
                const s: []const u8 = switch (status) {
                    .empty => "  ",
                    .wall => "██",
                    .water => "≈≈",
                };
                try w.print("{s}", .{s});
            }
            try w.writeByte('\n');
        }
    }
};
