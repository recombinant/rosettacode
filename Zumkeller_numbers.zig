// https://rosettacode.org/wiki/Zumkeller_numbers
const std = @import("std");
const math = std.math;
const mem = std.mem;
const testing = std.testing;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout = std.io.getStdOut().writer();

    {
        try stdout.print("The first 220 Zumkeller numbers are:\n", .{});
        var i: u32 = 2;
        var count: u32 = 0;
        while (count < 220) : (i += 1) {
            if (try isZumkeller(allocator, i)) {
                try stdout.print("{d:3} ", .{i});
                count += 1;
                if (count % 20 == 0)
                    try stdout.print("\n", .{});
            }
        }
    }
    {
        try stdout.print("\nThe first 40 odd Zumkeller numbers are:\n", .{});
        var i: u32 = 3;
        var count: u32 = 0;
        while (count < 40) : (i += 2) {
            if (try isZumkeller(allocator, i)) {
                try stdout.print("{d:5} ", .{i});
                count += 1;
                if (count % 10 == 0)
                    try stdout.print("\n", .{});
            }
        }
    }
    {
        try stdout.print("\nThe first 40 odd Zumkeller numbers which don't end in 5 are:\n", .{});
        var i: u32 = 3;
        var count: u32 = 0;
        while (count < 40) : (i += 2) {
            if (i % 10 != 5 and try isZumkeller(allocator, i)) {
                try stdout.print("{d:7} ", .{i});
                count += 1;
                if (count % 8 == 0)
                    try stdout.print("\n", .{});
            }
        }
    }
}

fn isZumkeller(allocator: mem.Allocator, n: u32) !bool {
    const divs = try getDivisors(allocator, n);
    defer allocator.free(divs);
    const sum = sumSlice(divs);
    // if sum is odd can't be split into two partitions with equal sums
    if (sum % 2 == 1)
        return false;

    // if n is odd use 'abundant odd number' optimization
    if (n % 2 == 1) {
        // Zig: use signed integer while abundance potentially < 0
        // abundance = sum - 2 * n;
        const abundance: i32 = @as(i32, @bitCast(sum)) - @as(i32, 2) * @as(i32, @bitCast(n));
        // abundance > 0 and abundance % 2 == 0
        return abundance > 0 and @as(u32, @bitCast(abundance)) % 2 == 0;
    }
    // if n and sum are both even check if there's a partition which totals sum / 2
    return try isPartSum(allocator, divs, sum / 2);
}

/// Caller owns returned memory.
fn getDivisors(allocator: mem.Allocator, n: u32) ![]u32 {
    var divs = std.ArrayList(u32).init(allocator);
    try divs.append(1);
    try divs.append(n);
    for (2..math.sqrt(n) + 1) |i|
        if (n % i == 0) {
            try divs.append(@truncate(i));
            const j = n / i;
            if (i != j)
                try divs.append(@truncate(j));
        };
    return try divs.toOwnedSlice();
}

fn isPartSum(allocator: mem.Allocator, d: []u32, sum: u32) !bool {
    if (sum == 0)
        return true;
    if (d.len == 0)
        return false;
    const last = d[d.len - 1];
    // Copy all but the last.
    const divs = try allocator.dupe(u32, d[0 .. d.len - 1]);
    defer allocator.free(divs);
    return if (last > sum)
        try isPartSum(allocator, divs, sum)
    else
        try isPartSum(allocator, divs, sum) or try isPartSum(allocator, divs, sum - last);
}

fn sumSlice(numbers: []u32) u32 {
    var total: u32 = 0;
    for (numbers) |n| total += n;
    return total;
}

test "Zumkeller number test" {
    const allocator = testing.allocator;

    try testing.expect(try isZumkeller(allocator, 6));
    try testing.expect(!try isZumkeller(allocator, 10));
    try testing.expect(try isZumkeller(allocator, 12));
}
