// https://rosettacode.org/wiki/Extensible_prime_generator
// Copied from rosettacode

// Alternative version based on "Two Compact Incremental Prime Sieves" by Jonathon P. Sorenson.
// Like the version based on the O'Neil sieve, this version also
// uses metaprogramming, this time to properly calculate the
// sizes of the buckets required by the algorithm (the sieve is
// implemented as an array of buckets, each bucket containing a
// list of the unique prime factors of that entry.) It's quite
// memory efficient for a u32 and below (16 bytes per bucket),
// though it is not memory efficient for larger sieves.
// For example, a u36 requires a bucket size of 36 bytes.)

// As with the O'Neil sieve, this version thus represents a
// spectrum of fixed or unbounded generators. PrimeGen(u32) (or
// PrimeGen(u64)) can be used as an unbounded sieve, whereas a
// PrimeGen(u10) represents a fixed sieve for all primes < 1024.

// Since this version uses an array (O(1)) rather than an
// O(log n) priority queue, it is significantly faster. On my
// laptop, sieving up to 100,000,000 primes takes 2:18 seconds
// for the O'Neil sieve and 52 seconds for the Sorenson.

// --------------------------------------------------------------

// Since in the common case (primes < 2^32 - 1), the stack only needs to be 8 16-bit words long
// (only twice the size of a pointer) the required stacks are stored in each cell, rather
// than using an indirection (e.g. linked list of integer cells)
//
const std = @import("std");
const math = std.math;
const meta = std.meta;
const mem = std.mem;
const assert = std.debug.assert;

fn assertInt(comptime T: type) void {
    if (@typeInfo(T) != .int)
        @compileError("data type must be an integer.");
    const info = @typeInfo(T).int;
    if (info.signedness == .signed or info.bits % 2 == 1 or info.bits < 4 or info.bits > 64)
        @compileError("type must be an unsigned integer with even bit size (of at least 4 bits).");
}

// given a type, return the maximum stack size required by the algorthm.
fn listSize(comptime T: type) usize {
    assertInt(T);
    const primes = [_]u6{
        2,  3,  5,  7,  11, 13, 17, 19,
        23, 29, 31, 37, 41, 43, 47, 53,
    };
    // Find the first primorial that will overflow type T.
    // the size of the list is the primorial index minus one,
    // since the sieve doesn't include 2.
    //
    var i: usize = 0;
    var pi: T = 1;
    while (true) {
        pi, const overflow = @mulWithOverflow(pi, primes[i]);
        if (overflow == 0)
            i += 1
        else
            break;
    }
    return i - 1;
}

fn SqrtType(comptime T: type) type {
    assertInt(T);
    return meta.Int(.unsigned, @typeInfo(T).int.bits / 2);
}

// stack type (actually just an array list)
fn ArrayList(comptime T: type) type {
    assertInt(T);
    return [listSize(T)]SqrtType(T);
}

// given an upper bound, max, return the most restrictive sieving data type.
pub fn AutoSieveType(comptime max: u64) type {
    if (max == 0)
        @compileError("The maximum sieving size must be non-zero.");
    var bit_len = 64 - @clz(max);
    if (max & (max - 1) == 0) // power of two
        bit_len -= 1;
    if (bit_len % 2 == 1)
        bit_len += 1;
    if (bit_len < 4)
        bit_len = 4;
    return meta.Int(.unsigned, bit_len);
}

const testing = std.testing;

test "type meta functions" {
    try testing.expect(SqrtType(u20) == u10);
    try testing.expect(AutoSieveType(8000) == u14);
    try testing.expect(AutoSieveType(9000) == u14);
    try testing.expect(AutoSieveType(16384) == u14);
    try testing.expect(AutoSieveType(16385) == u16);
    try testing.expect(AutoSieveType(32768) == u16);
    try testing.expect(AutoSieveType(1000) == u10);
    try testing.expect(AutoSieveType(10) == u4);
    try testing.expect(AutoSieveType(4) == u4);
    try testing.expect(AutoSieveType(math.maxInt(u32)) == u32);
    try testing.expect(listSize(u64) == 14);
    try testing.expect(listSize(u32) == 8);
    try testing.expect(@sizeOf(ArrayList(u32)) == 16);
    try testing.expect(@sizeOf(ArrayList(u36)) == 36);
    try testing.expect(@sizeOf(ArrayList(u64)) == 56);
}

pub fn PrimeGen(comptime T: type) type {
    assertInt(T);
    return struct {
        const Self = @This();
        const Sieve = std.ArrayList(ArrayList(T));

        sieve: Sieve,
        count: usize,
        candidate: T,
        rt: SqrtType(T),
        sq: T,
        pos: usize,

        // grow the sieve by a comptime fixed amount
        fn growBy(self: *Self, comptime n: usize) !void {
            var chunk: [n]ArrayList(T) = mem.zeroes([n]ArrayList(T));
            try self.sieve.appendSlice(&chunk);
        }

        // add a known prime number to the sieve at postion k
        fn add(self: *Self, p: SqrtType(T), k: usize) void {
            for (&self.sieve.items[k]) |*x|
                if (x.* == 0) {
                    x.* = p;
                    return;
                };
            // each bucket is precalculated for the max size.
            // If we get here, there's been a mistake somewhere.
            unreachable;
        }

        pub fn init(alloc: mem.Allocator) Self {
            return Self{
                .count = 0,
                .sieve = Sieve.init(alloc),
                .candidate = 3,
                .rt = 3,
                .sq = 9,
                .pos = 0,
            };
        }

        pub fn deinit(self: *Self) void {
            self.sieve.deinit();
        }

        pub fn next(self: *Self) !?T {
            self.count += 1;
            if (self.count == 1) {
                try self.growBy(1); // prepare sieve
                return 2;
            } else {
                var is_prime = false;
                while (!is_prime) {
                    is_prime = true;
                    // Step 1: check the list at self.pos; if there are divisors then
                    // the candidate is not prime.  Move each divisor to its next multiple
                    // in the sieve.
                    //
                    if (self.sieve.items[self.pos][0] != 0) {
                        is_prime = false;
                        for (&self.sieve.items[self.pos]) |*x| {
                            const p = x.*;
                            x.* = 0;
                            if (p == 0)
                                break;
                            self.add(p, (p + self.pos) % self.sieve.items.len);
                        }
                    }
                    // Step 2: If we've hit the next perfect square, and we thought the number
                    // was prime from step 1, note that it wasn't prime but rather was a non p-smooth
                    // number.  Add the square root to the sieve.  In any case, look ahead to the next
                    // square number.
                    //
                    if (self.candidate == self.sq) {
                        if (is_prime) {
                            is_prime = false;
                            self.add(self.rt, (self.pos + self.rt) % self.sieve.items.len);
                        }
                        // advance to the next root; if doing so would cause overflow then just ignore it,
                        // since we'll never see the next square.
                        //
                        const rt: SqrtType(T), const overflow = @addWithOverflow(self.rt, 2);
                        if (overflow == 0) {
                            self.rt = rt;
                            self.sq = @as(T, rt) * rt;
                        }
                    }
                    // advance the iterator; Note if we overflow, the candidate cannot be prime
                    // since the bit count must be even and all integers of the form 2^n - 1 with
                    // even n (except 2) are composite.
                    //
                    self.candidate, const overflow = @addWithOverflow(self.candidate, 2);
                    if (overflow != 0) {
                        assert(!is_prime);
                        return null;
                    }
                    self.pos += 1;
                    if (self.pos == self.sieve.items.len) {
                        // expand the array by 2 to maintain the invariant: sieve.items.len > √candidate
                        try self.growBy(2);
                        self.pos = 0;
                    }
                }
                return self.candidate - 2;
            }
        }
    };
}
