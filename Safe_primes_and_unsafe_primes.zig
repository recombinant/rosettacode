// https://rosettacode.org/wiki/Safe_primes_and_unsafe_primes
// Translation of C
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    // ------------------------------ safe primes
    var beg: usize = 0;
    var end: usize = 1_000_000;
    var count: usize = 0;
    print("First 35 safe primes:\n", .{});
    for (beg..end) |i| {
        if (isPrime(i) and isPrime((i - 1) / 2)) {
            if (count < 35)
                print("{d} ", .{i});
            count += 1;
        }
    }
    print("\nThere are  {d} safe primes below  {d}\n", .{ count, end });

    beg = end;
    end = end * 10;
    for (beg..end) |i| {
        if (isPrime(i) and isPrime((i - 1) / 2))
            count += 1;
    }
    print("There are {d} safe primes below {d}\n", .{ count, end });

    // ---------------------------- unsafe primes
    beg = 2;
    end = 1_000_000;
    count = 0;
    print("\nFirst 40 unsafe primes:\n", .{});
    for (beg..end) |i| {
        if (isPrime(i) and !isPrime((i - 1) / 2)) {
            if (count < 40)
                print("{d} ", .{i});
            count += 1;
        }
    }
    print("\nThere are  {d} unsafe primes below  {d}\n", .{ count, end });

    beg = end;
    end = end * 10;
    for (beg..end) |i| {
        if (isPrime(i) and !isPrime((i - 1) / 2))
            count += 1;
    }
    print("There are {d} unsafe primes below {d}\n", .{ count, end });
}

fn isPrime(n: usize) bool {
    const primes = [_]u32{
        2,   3,   5,   7,   11,  13,  17,  19,  23,  29,
        31,  37,  41,  43,  47,  53,  59,  61,  67,  71,
        73,  79,  83,  89,  97,  101, 103, 107, 109, 113,
        127, 131, 137, 139, 149, 151, 157, 163, 167, 173,
        179, 181, 191, 193, 197, 199, 211, 223, 227, 229,
        233, 239, 241, 251, 257, 263, 269, 271, 277, 281,
        283, 293, 307, 311, 313, 317, 331,
    };

    if (n < 2)
        return false;

    for (0..primes.len) |i| {
        if (n == primes[i]) return true;
        if (n % primes[i] == 0) return false;
        if (n < primes[i] * primes[i]) return true;
    }

    // const start = comptime primes[primes.len - 1] + 2
    // var i = start;
    // while (i * i <= n) : (i += 2) {
    //     if (n % i == 0)
    //         return false;
    // }
    const start = comptime primes[primes.len - 1] - ((primes[primes.len - 1] - 5) % 6);
    var i = start;
    while (i * i <= n) {
        if (n % i == 0) return false;
        i += 2;
        if (n % i == 0) return false;
        i += 4;
    }
    return true;
}
