// https://rosettacode.org/wiki/Knapsack_problem/0-1
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;
    const gpa: Allocator = init.gpa;

    const items = [_]Item{
        try .init(gpa, "map", 9, 150),
        try .init(gpa, "compass", 13, 35),
        try .init(gpa, "water", 153, 200),
        try .init(gpa, "sandwich", 50, 160),
        try .init(gpa, "glucose", 15, 60),
        try .init(gpa, "tin", 68, 45),
        try .init(gpa, "banana", 27, 60),
        try .init(gpa, "apple", 39, 40),
        try .init(gpa, "cheese", 23, 30),
        try .init(gpa, "beer", 52, 10),
        try .init(gpa, "suntan cream", 11, 70),
        try .init(gpa, "camera", 32, 30),
        try .init(gpa, "t-shirt", 24, 15),
        try .init(gpa, "trousers", 48, 10),
        try .init(gpa, "umbrella", 73, 40),
        try .init(gpa, "waterproof trousers", 42, 70),
        try .init(gpa, "waterproof overclothes", 43, 75),
        try .init(gpa, "note-case", 22, 80),
        try .init(gpa, "sunglasses", 7, 20),
        try .init(gpa, "towel", 18, 12),
        try .init(gpa, "socks", 4, 50),
        try .init(gpa, "book", 30, 10),
    };
    defer for (items) |item| item.deinit(gpa);

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    const bagged = try getSolution(gpa, 400, &items);
    std.mem.sortUnstable(Item, bagged, {}, Item.lessThan); // sort for printing

    try stdout.writeAll("Bagged items:\n");

    defer gpa.free(bagged);
    for (bagged) |item|
        try stdout.print("  {s}\n", .{item.name});

    var w: usize = 0;
    var v: usize = 0;
    for (bagged) |item| {
        v += item.value;
        w += item.weight;
    }
    try stdout.print("\nTotal value  = {d}\nTotal weight = {d}\n", .{ v, w });

    try stdout.flush();
}

const Item = struct {
    name: []const u8,
    weight: usize,
    value: usize,

    fn init(allocator: Allocator, name: []const u8, weight: usize, value: usize) !Item {
        return .{ .name = try allocator.dupe(u8, name), .weight = weight, .value = value };
    }
    fn deinit(self: Item, allocator: Allocator) void {
        allocator.free(self.name);
    }
    /// For sorting by name.
    fn lessThan(_: void, self: Item, other: Item) bool {
        return std.mem.order(u8, self.name, other.name) == .lt;
    }
};

/// From the wikipedia "0-1 knapsack problem"
/// Caller owns returned slice memory.
fn getSolution(allocator: std.mem.Allocator, maximum_weight: usize, items: []const Item) ![]Item {
    const row_len = items.len + 1;
    const col_len = maximum_weight + 1;

    const table = try allocator.alloc([]usize, row_len);
    defer allocator.free(table);

    const cols = try allocator.alloc(usize, row_len * col_len);
    defer allocator.free(cols);
    @memset(cols, 0); // simply zero entire matrix

    for (table, 0..) |*row, i|
        row.* = cols[i * col_len .. (i + 1) * col_len];

    for (items, 1..) |item, i|
        for (0..maximum_weight, 1..) |_, w| {
            table[i][w] = if (item.weight > w)
                table[i - 1][w]
            else
                @max(
                    table[i - 1][w],
                    table[i - 1][w - item.weight] + item.value,
                );
        };

    var result: std.ArrayList(Item) = .empty;

    var w = maximum_weight;
    var j = row_len;
    while (j != 1) {
        j -= 1;
        const added = (table[j][w] - table[j - 1][w]) != 0;
        if (added) {
            const wt = items[j - 1].weight;
            try result.append(allocator, items[j - 1]);
            w -= wt;
        }
    }
    return try result.toOwnedSlice(allocator);
}

const testing = std.testing;
// Tests are refactored from
// https://exercism.org/tracks/zig/exercises/knapsack/

/// getMaximumValue function is for use by tests
fn getMaximumValue(allocator: std.mem.Allocator, maximum_weight: usize, items: []const Item) !usize {
    const max_items = try getSolution(allocator, maximum_weight, items);
    defer allocator.free(max_items);

    var v: usize = 0;
    for (max_items) |item|
        v += item.value;

    return v;
}

test "no items" {
    const expected: usize = 0;
    const items: [0]Item = .{};
    const actual = try getMaximumValue(testing.allocator, 100, &items);
    try testing.expectEqual(expected, actual);
}
test "one item, too heavy" {
    const allocator = testing.allocator;
    const expected: usize = 0;
    const items: [1]Item = .{
        try Item.init(allocator, "one", 100, 1),
    };
    defer for (items) |item| item.deinit(allocator);
    const actual = try getMaximumValue(testing.allocator, 10, &items);
    try testing.expectEqual(expected, actual);
}
test "five items (cannot be greedy by weight)" {
    const allocator = testing.allocator;
    const expected: usize = 21;
    const items: [5]Item = .{
        try Item.init(allocator, "one", 2, 5),
        try Item.init(allocator, "two", 2, 5),
        try Item.init(allocator, "three", 2, 5),
        try Item.init(allocator, "four", 2, 5),
        try Item.init(allocator, "five", 10, 21),
    };
    defer for (items) |item| item.deinit(allocator);
    const actual = try getMaximumValue(testing.allocator, 10, &items);
    try testing.expectEqual(expected, actual);
}
test "five items (cannot be greedy by value)" {
    const allocator = testing.allocator;
    const expected: usize = 80;
    const items: [5]Item = .{
        try Item.init(allocator, "one", 2, 20),
        try Item.init(allocator, "two", 2, 20),
        try Item.init(allocator, "three", 2, 20),
        try Item.init(allocator, "four", 2, 20),
        try Item.init(allocator, "five", 10, 50),
    };
    const actual = try getMaximumValue(testing.allocator, 10, &items);
    try testing.expectEqual(expected, actual);

    for (items) |item| item.deinit(allocator);
}
test "example knapsack" {
    const allocator = testing.allocator;
    const expected: usize = 90;
    const items: [4]Item = .{
        try Item.init(allocator, "one", 5, 10),
        try Item.init(allocator, "two", 4, 40),
        try Item.init(allocator, "three", 6, 30),
        try Item.init(allocator, "four", 4, 50),
    };
    const actual = try getMaximumValue(testing.allocator, 10, &items);
    try testing.expectEqual(expected, actual);

    for (items) |item| item.deinit(allocator);
}
test "8 items" {
    const allocator = testing.allocator;
    const expected: usize = 900;
    const items: [8]Item = .{
        try Item.init(allocator, "one", 25, 350),
        try Item.init(allocator, "two", 35, 400),
        try Item.init(allocator, "three", 45, 450),
        try Item.init(allocator, "four", 5, 20),
        try Item.init(allocator, "five", 25, 70),
        try Item.init(allocator, "six", 3, 8),
        try Item.init(allocator, "sever", 2, 5),
        try Item.init(allocator, "eight", 2, 5),
    };
    const actual = try getMaximumValue(testing.allocator, 104, &items);
    try testing.expectEqual(expected, actual);

    for (items) |item| item.deinit(allocator);
}
test "15 items" {
    const allocator = testing.allocator;
    const expected: usize = 1458;
    const items: [15]Item = .{
        try Item.init(allocator, "one", 70, 135),
        try Item.init(allocator, "two", 73, 139),
        try Item.init(allocator, "three", 77, 149),
        try Item.init(allocator, "four", 80, 150),
        try Item.init(allocator, "five", 82, 156),
        try Item.init(allocator, "six", 87, 163),
        try Item.init(allocator, "sever", 90, 173),
        try Item.init(allocator, "eight", 94, 184),
        try Item.init(allocator, "nine", 98, 192),
        try Item.init(allocator, "ten", 106, 201),
        try Item.init(allocator, "eleven", 110, 210),
        try Item.init(allocator, "twelve", 113, 214),
        try Item.init(allocator, "thirteen", 115, 221),
        try Item.init(allocator, "fourteen", 118, 229),
        try Item.init(allocator, "fifteen", 120, 240),
    };
    const actual = try getMaximumValue(testing.allocator, 750, &items);
    try testing.expectEqual(expected, actual);

    for (items) |item| item.deinit(allocator);
}
