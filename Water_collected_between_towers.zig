// https://rosettacode.org/wiki/Water_collected_between_towers
const std = @import("std");
const math = std.math;
const mem = std.mem;
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

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
        var table = try Table.init(allocator, block);
        defer table.deinit();

        const water = table.fill();
        // table.printTable();

        print("{} water units.\n", .{water});
    }
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
    allocator: mem.Allocator,
    array: []Status,
    width: usize,
    height: usize,

    fn init(allocator: mem.Allocator, block: []const u7) !Table {
        const width = block.len;
        const height = blk: {
            var max_height: u7 = math.minInt(u7);
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
            if (mem.indexOfScalar(Status, slice, .wall)) |left| {
                // first wall from the right
                const right = mem.lastIndexOfScalar(Status, slice, .wall).?;
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
    fn printTable(self: Table) void {
        var row = self.height;
        while (row != 0) {
            print("{d:2} ", .{row});
            row -= 1;
            const slice = self.getRowSlice(row);
            for (slice) |status| {
                const s: []const u8 = switch (status) {
                    .empty => "  ",
                    .wall => "██",
                    .water => "≈≈",
                };
                print("{s}", .{s});
            }
            print("\n", .{});
        }
    }
};
