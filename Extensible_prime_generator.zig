// https://rosettacode.org/wiki/Extensible_prime_generator
// Copied from rosettacode
const std = @import("std");
const heap = std.heap;
const math = std.math;
const mem = std.mem;
const meta = std.meta;

fn assertInt(comptime T: type) void {
    if (@typeInfo(T) != .int)
        @compileError("data type must be an integer.");
    const info = @typeInfo(T).int;
    if (info.signedness == .signed or info.bits % 2 == 1 or info.bits < 4)
        @compileError("type must be an unsigned integer with even bit size (of at least 4 bits).");
}

fn SqrtType(comptime T: type) type {
    assertInt(T);
    return meta.Int(.unsigned, @typeInfo(T).int.bits / 2);
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
}

const wheel2357 = [48]u8{
    10, 2, 4, 2, 4, 6, 2,  6,
    4,  2, 4, 6, 6, 2, 6,  4,
    2,  6, 4, 6, 8, 4, 2,  4,
    2,  4, 8, 6, 4, 6, 2,  4,
    6,  2, 6, 6, 4, 2, 4,  6,
    2,  6, 4, 2, 4, 2, 10, 2,
};

fn Wheel2357Multiple(comptime T: type) type {
    assertInt(T);
    return struct {
        multiple: T,
        base_prime: T,
        offset: u6,

        fn order(_: void, self: Wheel2357Multiple(T), other: Wheel2357Multiple(T)) math.Order {
            return math.order(self.multiple, other.multiple);
        }
    };
}

pub fn PrimeGen(comptime Int: type) type {
    assertInt(Int);
    const MultiplesPriorityQueue = std.PriorityQueue(Wheel2357Multiple(Int), void, Wheel2357Multiple(Int).order);

    return struct {
        const Self = @This();

        initial_primes: u16,
        offset: u6,
        candidate: Int,
        multiples: MultiplesPriorityQueue,
        allocator: mem.Allocator,
        count: u32,

        pub fn init(alloc: mem.Allocator) Self {
            return Self{
                .initial_primes = 0xAC, // primes 2, 3, 5, 7 in a bitmask
                .offset = 0,
                .candidate = 1,
                .count = 0,
                .allocator = alloc,
                .multiples = MultiplesPriorityQueue.init(alloc, {}),
            };
        }

        pub fn deinit(self: *PrimeGen(Int)) void {
            self.multiples.deinit();
        }

        pub fn next(self: *PrimeGen(Int)) !?Int {
            if (self.initial_primes != 0) { // use the bitmask up first
                const p = @as(Int, @ctz(self.initial_primes));
                self.initial_primes &= self.initial_primes - 1;
                self.count += 1;
                return p;
            } else {
                while (true) {
                    // advance to the next prime candidate.
                    self.candidate, const overflow = @addWithOverflow(self.candidate, wheel2357[self.offset]);
                    if (overflow != 0)
                        return null;
                    self.offset = (self.offset + 1) % @as(u6, wheel2357.len);

                    // See if the composite number on top of the heap matches
                    // the candidate.
                    //
                    var top = self.multiples.peek();
                    if (top == null or self.candidate < top.?.multiple) {
                        // prime found, add the square and it's position on the wheel
                        // to the heap.
                        //
                        if (self.candidate <= math.maxInt(SqrtType(Int)))
                            try self.multiples.add(Wheel2357Multiple(Int){
                                .multiple = self.candidate * self.candidate,
                                .base_prime = self.candidate,
                                .offset = self.offset,
                            });
                        self.count += 1;
                        return self.candidate;
                    } else {
                        while (true) {
                            // advance the top of heap to the next prime multiple
                            // that is not a multiple of 2, 3, 5, 7.
                            //
                            var mult = self.multiples.remove();
                            // If the multiple becomes too big (greater than the the maximum
                            // sieve size), then there's no reason to add it back to the queue.
                            //
                            const tmp, const ov1 = @mulWithOverflow(mult.base_prime, wheel2357[mult.offset]);
                            if (ov1 == 0) {
                                mult.multiple, const ov2 = @addWithOverflow(tmp, mult.multiple);
                                if (ov2 == 0) {
                                    mult.offset = (mult.offset + 1) % @as(u6, wheel2357.len);
                                    try self.multiples.add(mult);
                                }
                            }
                            top = self.multiples.peek();
                            if (top == null or self.candidate != top.?.multiple)
                                break;
                        }
                    }
                }
            }
        }
    };
}
