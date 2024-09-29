// https://rosettacode.org/wiki/Find_prime_numbers_of_the_form_n*n*n%2B2
// Translation of C
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    const limit = 200;
    var n: u64 = 1;
    while (n < limit) : (n += 1) {
        const p = n * n * n + 2;
        if (isPrime(p))
            print("n = {d:3} => n³ + 2 = {d}\n", .{ n, p });
    }
}

fn isPrime(n: u64) bool {
    if (n < 2) return false;
    if (n % 2 == 0) return n == 2;
    if (n % 3 == 0) return n == 3;
    var d: u64 = 5;
    while (d * d <= n) {
        if (n % d == 0) return false;
        d += 2;
        if (n % d == 0) return false;
        d += 4;
    }
    return true;
}

const testing = std.testing;

test isPrime {
    try testing.expect(!isPrime(0));
    try testing.expect(!isPrime(1));
    try testing.expect(isPrime(2));
    try testing.expect(isPrime(3));
    try testing.expect(!isPrime(4));
    try testing.expect(isPrime(5));
    try testing.expect(!isPrime(6));
    try testing.expect(isPrime(7));
    try testing.expect(!isPrime(8));
    try testing.expect(!isPrime(9));
    try testing.expect(!isPrime(10));
    try testing.expect(isPrime(11));
    try testing.expect(!isPrime(12));
    try testing.expect(isPrime(13));
    try testing.expect(!isPrime(14));
    try testing.expect(!isPrime(15));
}
