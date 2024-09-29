// https://rosettacode.org/wiki/Concatenate_two_primes_is_also_prime
// Translation of C
const std = @import("std");
const math = std.math;
const sort = std.sort;
const print = std.debug.print;

pub fn main() !void {
    const limit = 100;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var primes = std.ArrayList(u32).init(allocator);
    defer primes.deinit();
    var results = std.ArrayList(u32).init(allocator);
    defer results.deinit();

    for (0..limit) |i| {
        const p: u32 = @intCast(i);
        if (isPrime(p))
            try primes.append(p);
    }

    var factor: u32 = 1;
    var minimum: u32 = 0;
    for (primes.items) |p| {
        for (primes.items) |q| {
            if (q < factor or q > minimum) {
                minimum = math.pow(u32, 10, math.log10_int(@as(u32, q)));
                factor = minimum * 10;
            }
            const pq = (p * factor) + q;
            if (isPrime(pq))
                try results.append(pq);
        }
    }
    sort.insertion(u32, results.items, {}, sort.asc(u32));

    var count: usize = 0;
    print("Two primes under {d} concatenated together to form another prime:\n", .{limit});
    for (results.items, 0..) |result, i| {
        if (i > 0 and result == results.items[i - 1])
            continue;
        print("{d:6} ", .{result});
        count += 1;
        if (count % 10 == 0)
            print("\n", .{});
    }
    print("\n\nFound {d} such concatenated primes.\n", .{count});
}

fn isPrime(n: u32) bool {
    if (n < 2) return false;
    if (n % 2 == 0) return n == 2;
    if (n % 3 == 0) return n == 3;
    var d: u32 = 5;
    while (d * d <= n) {
        if (n % d == 0) return false;
        d += 2;
        if (n % d == 0) return false;
        d += 4;
    }
    return true;
}
