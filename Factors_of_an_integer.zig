// https://rosettacode.org/wiki/Factors_of_an_integer
const std = @import("std");
const math = std.math;
const mem = std.mem;
const sort = std.sort;
const testing = std.testing;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();

    var t0 = try std.time.Timer.start();

    const result = try factors(allocator, 15120);
    defer allocator.free(result);
    try stdout.print("{d} => {any}\n", .{ 15120, result });

    try stdout.print("Processed in {}\n", .{std.fmt.fmtDuration(t0.read())});
}

/// Caller owns returned slice.
fn factors(allocator: mem.Allocator, number: u64) ![]u64 {
    var number_list = std.ArrayList(u64).init(allocator);

    var n: u64 = 1;
    while (n < math.sqrt(number) + 1) : (n += 1) {
        if (number % n == 0) {
            try number_list.append(n);
            const n2 = number / n;
            if (n2 != n)
                try number_list.append(n2);
        }
    }
    const result = try number_list.toOwnedSlice();
    mem.sort(u64, result, {}, sort.asc(u64));
    return result;
}

test "factors 0" {
    const result = try factors(testing.allocator, 0);
    try testing.expectEqual(0, result.len);
    testing.allocator.free(result);
}
test "factors primes" {
    const numbers = [_]u64{ 2, 3, 5, 7, 11, 13, 17, 19, 23 };
    for (numbers) |n| {
        const result = try factors(testing.allocator, n);
        defer testing.allocator.free(result);
        try testing.expectEqual(2, result.len);
        try testing.expectEqual(1, result[0]);
        try testing.expectEqual(n, result[1]);
    }
}
test "factors 4 & 9" {
    const numbers = [_]u64{ 4, 9 };
    for (numbers) |n| {
        const result = try factors(testing.allocator, n);
        defer testing.allocator.free(result);
        try testing.expectEqual(3, result.len);
        try testing.expectEqual(1, result[0]);
        try testing.expectEqual(math.sqrt(n), result[1]);
        try testing.expectEqual(n, result[2]);
    }
}
test "factors 6" {
    const result = try factors(testing.allocator, 6);
    defer testing.allocator.free(result);

    const expected = [_]u64{ 1, 2, 3, 6 };
    try testing.expectEqualSlices(u64, &expected, result);
}
test "factors 12" {
    const result = try factors(testing.allocator, 12);
    defer testing.allocator.free(result);

    const expected = [_]u64{ 1, 2, 3, 4, 6, 12 };
    try testing.expectEqualSlices(u64, &expected, result);
}
test "factors 16" {
    const result = try factors(testing.allocator, 16);
    defer testing.allocator.free(result);

    const expected = [_]u64{ 1, 2, 4, 8, 16 };
    try testing.expectEqualSlices(u64, &expected, result);
}
test "factors 24" {
    const result = try factors(testing.allocator, 24);
    defer testing.allocator.free(result);

    const expected = [_]u64{ 1, 2, 3, 4, 6, 8, 12, 24 };
    try testing.expectEqualSlices(u64, &expected, result);
}
test "factors 36" {
    const result = try factors(testing.allocator, 36);
    defer testing.allocator.free(result);

    const expected = [_]u64{ 1, 2, 3, 4, 6, 9, 12, 18, 36 };
    try testing.expectEqualSlices(u64, &expected, result);
}
test "factors 48" {
    const result = try factors(testing.allocator, 48);
    defer testing.allocator.free(result);

    const expected = [_]u64{ 1, 2, 3, 4, 6, 8, 12, 16, 24, 48 };
    try testing.expectEqualSlices(u64, &expected, result);
}
test "factors 60" {
    const result = try factors(testing.allocator, 60);
    defer testing.allocator.free(result);

    const expected = [_]u64{ 1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60 };
    try testing.expectEqualSlices(u64, &expected, result);
}
test "factors 120" {
    const result = try factors(testing.allocator, 120);
    defer testing.allocator.free(result);

    const expected = [_]u64{ 1, 2, 3, 4, 5, 6, 8, 10, 12, 15, 20, 24, 30, 40, 60, 120 };
    try testing.expectEqualSlices(u64, &expected, result);
}
