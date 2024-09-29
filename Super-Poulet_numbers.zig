// https://rosettacode.org/wiki/Super-Poulet_numbers
// Translated from C++
const std = @import("std");
const heap = std.heap;
const mem = std.mem;
const print = std.debug.print;

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var n: u64 = 2;
    var count: usize = 0;
    while (true) : (n += 1) {
        if (try isSuperPouletNumber(allocator, n)) {
            count += 1;
            if (count <= 20) {
                print("{d:5}", .{n});
                print("{c}", .{@as(u8, if (count % 5 == 0) '\n' else ' ')});
                if (count == 20)
                    print("\n", .{});
            } else if (n > 1_000_000) {
                print("First super-Poulet number greater than one million is {} at index {}.", .{ n, count });
                break;
            }
        }
    }
}

/// Return "a^n mod m".
fn modpow(base_: u64, exp_: u64, mod: u64) u64 {
    if (mod == 1)
        return 0;

    var base = base_ % mod;
    var exp = exp_;
    var result: u64 = 1;

    while (exp != 0) : (exp >>= 1) {
        if (exp & 1 != 0)
            result = (result * base) % mod;
        base = (base * base) % mod;
    }
    return result;
}

/// 2, 3, 5 prime test.
fn isPrime(n: u64) bool {
    if (n < 2)
        return false;

    inline for ([3]u3{ 2, 3, 5 }) |p| {
        if (n % p == 0)
            return n == p;
    }

    const wheel = comptime [_]u3{ 4, 2, 4, 2, 4, 6, 2, 6 };

    var p: u64 = 7;
    while (true) {
        for (wheel) |w| {
            if (p * p > n)
                return true;
            if (n % p == 0)
                return false;
            p += w;
        }
    }
}

/// Caller owns returned slice memory.
fn divisors(allocator: mem.Allocator, n_: u64) ![]u64 {
    var result = std.ArrayList(u64).init(allocator);
    errdefer result.deinit();

    try result.append(1);

    var n = n_;
    var power: u64 = 2;
    while (n & 1 == 0) {
        try result.append(power);
        power <<= 1;
        n >>= 1;
    }
    var p: u64 = 3;
    while (p * p <= n) : (p += 2) {
        const len = result.items.len;
        power = p;
        while (n % p == 0) {
            for (0..len) |i|
                try result.append(power * result.items[i]);
            power *= p;
            n /= p;
        }
    }
    if (n > 1) {
        const len = result.items.len;
        for (0..len) |i|
            try result.append(n * result.items[i]);
    }
    return try result.toOwnedSlice();
}

/// Caller owns returned slice memory.
fn divisors2(allocator: mem.Allocator, n: u64) ![]u64 {
    var result = std.ArrayList(u64).init(allocator);
    errdefer result.deinit();

    try result.append(n);
    var d: u64 = 2;
    while (d * d <= n) : (d += 1)
        if (n % d == 0) {
            const q = n / d;
            try result.append(d);
            if (q != d)
                try result.append(q);
        };
    return try result.toOwnedSlice();
}

fn isPouletNumber(n: u64) bool {
    return modpow(2, n - 1, n) == 1 and !isPrime(n);
}

fn isSuperPouletNumber(allocator: mem.Allocator, n: u64) !bool {
    if (!isPouletNumber(n))
        return false;

    const divs = try divisors(allocator, n);
    defer allocator.free(divs);

    for (divs[1..]) |d|
        if (modpow(2, d, d) != 2)
            return false;
    return true;
}

const testing = std.testing;
const math = std.math;
const sort = std.sort;

test modpow {
    const expected: u64 = math.pow(u64, 7, 5) % 3;
    try testing.expectEqual(expected, modpow(7, 5, 3));
}

test isPrime {
    try testing.expect(isPrime(2));
    try testing.expect(isPrime(3));
    try testing.expect(isPrime(5));
    try testing.expect(isPrime(7));
    try testing.expect(isPrime(11));
    try testing.expect(isPrime(13));
    try testing.expect(isPrime(17));

    try testing.expect(isPrime(19141));
    try testing.expect(isPrime(19391));
    try testing.expect(isPrime(19609));

    try testing.expect(!isPrime(1));
    try testing.expect(!isPrime(4));
    try testing.expect(!isPrime(6));
    try testing.expect(!isPrime(8));
    try testing.expect(!isPrime(9));
    try testing.expect(!isPrime(10));
    try testing.expect(!isPrime(12));
    try testing.expect(!isPrime(14));

    try testing.expect(!isPrime(19147));
    try testing.expect(!isPrime(19397));
    try testing.expect(!isPrime(19607));
}

test divisors {
    const divs2 = try divisors(testing.allocator, 2);
    try testing.expectEqualSlices(u64, &[_]u64{ 1, 2 }, divs2);
    testing.allocator.free(divs2);

    const divs6 = try divisors(testing.allocator, 6);
    mem.sort(u64, divs6, {}, sort.asc(u64));
    try testing.expectEqualSlices(u64, &[_]u64{ 1, 2, 3, 6 }, divs6);
    testing.allocator.free(divs6);

    const divs23 = try divisors(testing.allocator, 23);
    try testing.expectEqualSlices(u64, &[_]u64{ 1, 23 }, divs23);
    testing.allocator.free(divs23);

    const divs24 = try divisors(testing.allocator, 24);
    mem.sort(u64, divs24, {}, sort.asc(u64));
    try testing.expectEqualSlices(u64, &[_]u64{ 1, 2, 3, 4, 6, 8, 12, 24 }, divs24);
    testing.allocator.free(divs24);
}
