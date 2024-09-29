// https://rosettacode.org/wiki/Sphenic_numbers
// Translated from C++
const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const limit = 1_000_000;
    const imax = limit / 6;

    const sieve = calcPrimeSieve(imax + 1);
    var sphenic = std.StaticBitSet(limit + 1).initEmpty();

    for (0..imax + 1) |i| {
        if (!sieve.isSet(i))
            continue;

        const jmax = @min(imax, limit / (i * i));
        if (jmax <= i)
            break;
        for (i + 1..jmax + 1) |j| {
            if (!sieve.isSet(j))
                continue;
            const p = i * j;
            const kmax = @min(imax, limit / p);
            if (kmax <= j)
                break;
            for (j + 1..kmax + 1) |k| {
                if (!sieve.isSet(k))
                    continue;
                assert(p * k <= limit);
                sphenic.set(p * k);
            }
        }
    }

    const stdout = std.io.getStdOut().writer();

    var n: usize = 0;
    try stdout.writeAll("Sphenic numbers < 1,000:\n");
    for (0..1000) |i| {
        if (!sphenic.isSet(i))
            continue;
        n += 1;
        try stdout.print("{d:3}", .{i});
        try stdout.writeByte(if (n % 15 == 0) '\n' else ' ');
    }

    n = 0;
    try stdout.writeAll("\nSphenic triplets < 10,000:\n");
    for (0..10000) |i| {
        if (i > 1 and sphenic.isSet(i) and sphenic.isSet(i - 1) and sphenic.isSet(i - 2)) {
            n += 1;
            try stdout.print("({}, {}, {})", .{ i - 2, i - 1, i });
            try stdout.writeByte(if (n % 3 == 0) '\n' else ' ');
        }
    }

    var count: usize = 0;
    var triplets: usize = 0;
    var s200_000: u32 = 0;
    var t5_000: u32 = 0;
    for (0..limit) |i| {
        if (!sphenic.isSet(i))
            continue;
        count += 1;
        if (count == 200_000)
            s200_000 = @intCast(i);
        if (i > 1 and sphenic.isSet(i - 1) and sphenic.isSet(i - 2)) {
            triplets += 1;
            if (triplets == 5_000)
                t5_000 = @intCast(i);
        }
    }

    try stdout.print("\nNumber of sphenic numbers < 1,000,000: {}\n", .{count});
    try stdout.print("Number of sphenic triplets < 1,000,000: {}\n", .{triplets});

    const factors = try findPrimeFactors(allocator, s200_000);
    defer allocator.free(factors);
    assert(factors.len == 3);
    try stdout.print(
        "The 200,000th sphenic number: {} = {} * {} * {}\n",
        .{ s200_000, factors[0], factors[1], factors[2] },
    );

    try stdout.print(
        "The 5,000th sphenic triplet: ({}, {}, {})\n",
        .{ t5_000 - 2, t5_000 - 1, t5_000 },
    );
}

// Sieve of Eratosthenese. Not quite brute force.
// Sieve of Pritchard would be quicker.
// Primesieve (https://github.com/kimwalisch/primesieve) would be even quicker.
fn calcPrimeSieve(comptime limit: usize) std.StaticBitSet(limit) {
    var bits = std.StaticBitSet(limit).initFull();

    if (limit > 0) bits.unset(0);
    if (limit > 1) bits.unset(1);

    var i: usize = 4;
    while (i < limit) : (i += 2)
        bits.unset(i);

    var p: usize = 3;
    var sq: usize = 9;
    while (sq < limit) : (p += 2) {
        if (bits.isSet(p)) {
            var q = sq;
            while (q < limit) : (q += p << 1)
                bits.unset(q);
        }
        sq += (p + 1) << 2;
    }
    return bits;
}

fn findPrimeFactors(allocator: mem.Allocator, n_: u32) ![]u32 {
    var n = n_;
    var factors = std.ArrayList(u32).init(allocator);
    if (n > 1 and (n & 1) == 0) {
        try factors.append(2);
        while ((n & 1) == 0)
            n >>= 1;
    }
    var p: u32 = 3;
    while (p * p <= n) : (p += 2) {
        if (n % p == 0) {
            try factors.append(p);
            while (n % p == 0)
                n /= p;
        }
    }
    if (n > 1)
        try factors.append(n);

    return try factors.toOwnedSlice();
}
