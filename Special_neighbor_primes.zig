// https://rosettacode.org/wiki/Special_neighbor_primes
// {{works with|Zig|0.15.1}}
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    var p1: u16 = 3;
    while (p1 < 100) : (p1 += 2) {
        if (isPrime(p1)) {
            const p2 = nextPrime(p1);
            if (p2 < 100 and isPrime(p2 + p1 - 1))
                print("{d} + {d} - 1 = {d}\n", .{ p1, p2, p1 + p2 - 1 });
        }
    }
}

fn nextPrime(p: u16) u16 {
    if (p == 0) return 2;
    if (p < 3) return p + 1;
    var i: u16 = 1;
    while (!isPrime(i + p)) : (i += 1) {}
    return i + p;
}

fn isPrime(n: u16) bool {
    if (n < 2) return false;
    if (n % 2 == 0) return n == 2;
    if (n % 3 == 0) return n == 3;
    var d: u16 = 5;
    while (d * d <= n) {
        if (n % d == 0) return false;
        d += 2;
        if (n % d == 0) return false;
        d += 4;
    }
    return true;
}
