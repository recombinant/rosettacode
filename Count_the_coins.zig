// https://rosettacode.org/wiki/Count_the_coins
// {{works with|Zig|0.15.1}}
// {{trans|Python}}
// Translation of Python (Fast version)
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const us_coins = &[_]u8{ 100, 50, 25, 10, 5, 1 };
    const eu_coins = &[_]u8{ 200, 100, 50, 20, 10, 5, 2, 1 };

    for ([_][]const u8{ us_coins, eu_coins }) |coins| {
        try stdout.print("{}\n", .{try count(allocator, 1_00, coins[2..])});
        try stdout.print("{}\n", .{try count(allocator, 1_000_00, coins)});
        try stdout.print("{}\n", .{try count(allocator, 10_000_00, coins)});
        try stdout.print("{}\n\n", .{try count(allocator, 100_000_00, coins)});
    }

    try stdout.flush();
}

fn count(allocator: std.mem.Allocator, amount: u32, coins: []const u8) !u128 {
    const ways = try allocator.alloc(u128, amount + 1);
    defer allocator.free(ways);
    @memset(ways, 0);
    ways[0] = 1;

    for (coins) |coin|
        if (coin < amount + 1) {
            for (coin..amount + 1) |j|
                ways[j] += ways[j - coin];
        };
    return ways[amount];
}

/// Very slow recursive method included in the C example.
fn countRecursive(sum: u32, coins: []const u8) u32 {
    if (coins.len == 0 or @as(i32, @bitCast(sum)) < 0) return 0;
    if (sum == 0) return 1;
    return countRecursive(sum -% coins[0], coins) + countRecursive(sum, coins[1..]);
}

/// This is apparently the faster method in Python.
fn countFast(allocator: std.mem.Allocator, amount: u32, coins_: []const u8) !u128 {
    const coins = blk: {
        var array: std.ArrayList(u8) = .empty;
        for (coins_) |coin|
            if (coin <= amount) {
                try array.append(allocator, coin);
            };
        break :blk try array.toOwnedSlice(allocator);
    };
    defer allocator.free(coins);
    const n = coins.len;

    var cycle: usize = 0;
    for (coins) |c|
        if (c <= amount and c >= cycle) {
            cycle = c + 1;
        };
    cycle *= n;

    const table = try allocator.alloc(u128, cycle);
    defer allocator.free(table);
    @memset(table[0..n], 1);
    @memset(table[n..], 0);

    var pos = n;
    var s: u32 = 1;
    while (s < amount + 1) : (s += 1) {
        var i: usize = 0;
        while (i < n) : (i += 1) {
            if (i == 0 and pos >= cycle)
                pos = 0;

            if (coins[i] <= s) {
                const q = pos -% coins[i] * n;
                table[pos] = if (@as(isize, @bitCast(q)) >= 0)
                    table[q]
                else
                    table[q +% cycle];
            }
            if (i != 0)
                table[pos] += table[pos - 1];

            pos += 1;
        }
    }
    return table[pos - 1];
}

const testing = std.testing;

test count {
    const coins = &[_]u8{ 100, 50, 25, 10, 5, 1 };
    try testing.expectEqual(1, try count(testing.allocator, 1, coins));
    try testing.expectEqual(1, try count(testing.allocator, 2, coins));
    try testing.expectEqual(1, try count(testing.allocator, 3, coins));
    try testing.expectEqual(1, try count(testing.allocator, 4, coins));
    try testing.expectEqual(2, try count(testing.allocator, 6, coins));
    try testing.expectEqual(2, try count(testing.allocator, 7, coins));
    try testing.expectEqual(2, try count(testing.allocator, 8, coins));
    try testing.expectEqual(2, try count(testing.allocator, 9, coins));
    try testing.expectEqual(4, try count(testing.allocator, 10, coins));
    try testing.expectEqual(6, try count(testing.allocator, 15, coins));
}

test countFast {
    const coins = &[_]u8{ 100, 50, 25, 10, 5, 1 };
    try testing.expectEqual(1, try countFast(testing.allocator, 1, coins));
    try testing.expectEqual(1, try countFast(testing.allocator, 2, coins));
    try testing.expectEqual(1, try countFast(testing.allocator, 3, coins));
    try testing.expectEqual(1, try countFast(testing.allocator, 4, coins));
    try testing.expectEqual(2, try countFast(testing.allocator, 6, coins));
    try testing.expectEqual(2, try countFast(testing.allocator, 7, coins));
    try testing.expectEqual(2, try countFast(testing.allocator, 8, coins));
    try testing.expectEqual(2, try countFast(testing.allocator, 9, coins));
    try testing.expectEqual(4, try countFast(testing.allocator, 10, coins));
    try testing.expectEqual(6, try countFast(testing.allocator, 15, coins));
}

test countRecursive {
    const coins = &[_]u8{ 100, 50, 25, 10, 5, 1 };
    try testing.expectEqual(1, countRecursive(1, coins));
    try testing.expectEqual(1, countRecursive(2, coins));
    try testing.expectEqual(1, countRecursive(3, coins));
    try testing.expectEqual(1, countRecursive(4, coins));
    try testing.expectEqual(2, countRecursive(6, coins));
    try testing.expectEqual(2, countRecursive(7, coins));
    try testing.expectEqual(2, countRecursive(8, coins));
    try testing.expectEqual(2, countRecursive(9, coins));
    try testing.expectEqual(4, countRecursive(10, coins));
    try testing.expectEqual(6, countRecursive(15, coins));
}
