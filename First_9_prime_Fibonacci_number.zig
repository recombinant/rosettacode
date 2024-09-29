// https://rosettacode.org/wiki/First_9_prime_Fibonacci_number
const std = @import("std");
const testing = std.testing;

pub fn main() !void {
    const limit = 9;

    const stdout = std.io.getStdOut().writer();
    try stdout.print("The first {} prime Fibonacci numbers are:\n", .{limit});

    var fibonacci = FibonacciIterator{};
    var count: u8 = 0;
    while (count != limit) {
        const n = fibonacci.next();
        if (isPrime(n)) {
            try stdout.print("{d} ", .{n});
            count += 1;
        }
    }
    try stdout.writeByte('\n');
}

const FibonacciIterator = struct {
    // Uses some jiggery pokery so that only the previous and current fibonacci
    // values are stored. If the next value were to be stored then u64 would
    // overflow before reaching the task's 12th prime.
    started: bool = false,
    fib1: u64 = 1, // previous value (after started)
    fib2: u64 = 0, // current value

    fn next(self: *FibonacciIterator) u64 {
        if (self.started) {
            const fib = self.fib1;
            self.fib1 = self.fib2;
            self.fib2 += fib;
            return self.fib2;
        }
        self.started = true;
        return 0;
    }
};

fn isPrime(n: u64) bool {
    if (n < 2) return false;
    if (n % 2 == 0) return n == 2;
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

test FibonacciIterator {
    const sequence = [_]u64{
        0,      1,      1,      2,     3,     5,     8,     13,    21,
        34,     55,     89,     144,   233,   377,   610,   987,   1597,
        2584,   4181,   6765,   10946, 17711, 28657, 46368, 75025, 121393,
        196418, 317811, 514229,
    };

    var it = FibonacciIterator{};
    for (sequence) |n|
        try testing.expectEqual(n, it.next());
}

test isPrime {
    const primes = [_]u64{ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29 };
    const non_primes = [_]u64{ 0, 1, 4, 6, 8, 9, 10, 12, 14, 15, 16, 18 };

    for (primes) |n|
        try testing.expect(isPrime(n));
    for (non_primes) |n|
        try testing.expect(!isPrime(n));
}
