// https://rosettacode.org/wiki/Iccanobif_primes
const std = @import("std");
const testing = std.testing;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.writeAll("The first 10 Iccanobif primes are:\n");

    var fibonnaci = Fibonnaci{};
    var count: u8 = 0;
    var looped = true;
    while (count != 10) {
        const n = reverse(fibonnaci.next());
        if (isPrime(n)) {
            if (looped) try stdout.writeByte(' ') else looped = false;
            try stdout.print("{d}", .{n});
            count += 1;
        }
    }
    try stdout.writeByte('\n');
}

/// Return the "reversed" value of `n`
fn reverse(n_: u64) u64 {
    var result: u64 = 0;
    var n = n_;
    while (n != 0) {
        result = 10 * result + n % 10;
        n /= 10;
    }
    return result;
}

const Fibonnaci = struct {
    fib1: u64 = 0,
    fib2: u64 = 1,

    fn next(self: *Fibonnaci) u64 {
        const fib = self.fib1;
        self.fib1 = self.fib2;
        self.fib2 += fib;
        return fib;
    }
};

// Return "true" is "n" is prime.
fn isPrime(n: u64) bool {
    if (n < 2) return false;
    if (n & 1 == 0) return n == 2;
    if (n % 3 == 0) return n == 3;
    var d: u64 = 5;
    var step: u64 = 2;
    while (d * d <= n) {
        if (n % d == 0)
            return false;
        d += step;
        step = 6 - step;
    }
    return true;
}

test reverse {
    try testing.expectEqual(@as(u64, 123456), reverse(654321));
    try testing.expectEqual(@as(u64, 0), reverse(0));
}

test Fibonnaci {
    var f = Fibonnaci{};

    var sequence = [_]u64{
        0,      1,      1,      2,     3,     5,     8,     13,    21,
        34,     55,     89,     144,   233,   377,   610,   987,   1597,
        2584,   4181,   6765,   10946, 17711, 28657, 46368, 75025, 121393,
        196418, 317811, 514229,
    };
    for (&sequence) |n| {
        try testing.expectEqual(n, f.next());
    }
}

test isPrime {
    const primes = [_]u64{ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29 };
    const non_primes = [_]u64{ 0, 1, 4, 6, 8, 9, 10, 12, 14, 15, 16, 18 };

    for (&primes) |n|
        try testing.expect(isPrime(n));
    for (&non_primes) |n|
        try testing.expect(!isPrime(n));
}
