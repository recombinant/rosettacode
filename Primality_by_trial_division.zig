// https://rosettacode.org/wiki/Primality_by_trial_division
const std = @import("std");

fn isPrime(n_: anytype) bool {
    const T = @TypeOf(n_);
    if (@typeInfo(T) != .int)
        @compileError("isPrime() expected integer argument, found " ++ @typeName(T));

    if (n_ <= 1) return false;

    const U: type = comptime std.meta.Int(.unsigned, @typeInfo(T).int.bits);

    const n: U = @bitCast(n_);
    if (n % 2 == 0) return n == 2;

    const limit = std.math.sqrt(n);
    var i: U = 3;
    while (i <= limit) : (i += 1)
        if (n % i == 0) return false;
    return true;
}

/// An alternative implementation for comparison during test.
fn isPrimeAlt(n: anytype) bool {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("isPrime() expected unsigned integer argument, found " ++ @typeName(T));
    if (n < 2) return false;
    inline for ([3]u3{ 2, 3, 5 }) |p| if (n % p == 0) return n == p;
    const wheel = comptime [_]u3{ 4, 2, 4, 2, 4, 6, 2, 6 };
    var p: T = 7;
    while (true)
        for (wheel) |w| {
            if (p * p > n) return true;
            if (n % p == 0) return false;
            p += w;
        };
}

const testing = std.testing;
test isPrime {
    // some known small numbers
    try testing.expect(!isPrime(@as(u8, 0)));
    try testing.expect(!isPrime(@as(u8, 1)));
    try testing.expect(isPrime(@as(u8, 2)));
    try testing.expect(isPrime(@as(u8, 3)));
    try testing.expect(!isPrime(@as(u8, 4)));
    try testing.expect(!isPrime(@as(u8, 9)));
    try testing.expect(!isPrime(@as(u8, 10)));
    // known small primes
    for ([_]u16{
        2,  3,  5,  7,  11, 13, 17, 19, 23, 29, 31, 37, 41,
        43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97,
    }) |n| {
        try testing.expect(isPrime(n));
    }
    // negative numbers are not prime
    var i: i32 = -1_000_000;
    while (i != 2) : (i += 1)
        try testing.expect(!isPrime(i));
    // unsigned and signed values should give the same results
    var j: i32 = 2;
    var k: i32 = 2;
    while (j != 1_000_000) : ({
        j += 1;
        k += 1;
    }) {
        try testing.expectEqual(isPrime(j), isPrime(k));
    }
    // some known small unsigned numbers
    try testing.expect(isPrime(@as(i8, 2)));
    try testing.expect(isPrime(@as(i8, 3)));
    try testing.expect(!isPrime(@as(i8, 4)));
    try testing.expect(!isPrime(@as(i8, 9)));
    try testing.expect(!isPrime(@as(i8, 10)));

    for (0..1_000_000) |n|
        try testing.expectEqual(isPrime(n), isPrimeAlt(n));
}
