// https://rosettacode.org/wiki/Emirp_primes
// {{works with|Zig|0.15.1}}
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    {
        print("Task 1 (first 20 emirps):\n", .{});
        var count: usize = 0;
        var n: u64 = 0;

        while (true) : (n += 1) {
            if (isEmirp(n)) {
                print("{} ", .{n});
                count += 1;
                if (count == 20) break;
            }
        }
        print("\n\n", .{});
    }
    {
        print("Task 2 (emirps between 7,700 and 8,000):\n", .{});
        var n: u64 = 7_701;
        while (n != 8_001) : (n += 2) {
            if (isEmirp(n))
                print("{} ", .{n});
        }
        print("\n\n", .{});
    }
    {
        print("Task 3 (10,000th emirp):\n", .{});
        var count: usize = 0;
        var n: u64 = 13; // first emirp

        while (true) : (n += 2) {
            if (isEmirp(n)) {
                count += 1;
                if (count == 10_000) {
                    print("{}", .{n});
                    break;
                }
            }
        }
        print("\n\n", .{});
    }
}

fn isEmirp(n: u64) bool {
    const r = reverse(n);
    return r != n and isPrime(n) and isPrime(r);
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

fn isPrime(n: u64) bool {
    if (n <= 3)
        return n > 1;
    if (n % 2 == 0 or n % 3 == 0)
        return false;

    var d: u32 = 5;
    while (d * d <= n) : (d += 6)
        if (n % d == 0 or n % (d + 2) == 0)
            return false;

    return true;
}
