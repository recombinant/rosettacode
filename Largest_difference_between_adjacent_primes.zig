// https://rosettacode.org/wiki/Largest_difference_between_adjacent_primes
const std = @import("std");

const LIMIT = 1_000_000;

pub fn main() !void {
    var t0 = try std.time.Timer.start();

    // The `comptime` reduces the runtime sieve creation time by more than 3 orders of magnitude.
    // Without the `comptime` the compile time is considerably quicker.
    const prime_sieve = comptime sieve(LIMIT);

    std.log.info("sieve created in {}", .{std.fmt.fmtDuration(t0.read())});

    var curr: u32 = 2;
    var prev: u32 = 2;
    var prime2 = curr;
    var prime1 = prev;

    var i: u32 = 3;
    while (i <= LIMIT) : (i += 2)
        if (prime_sieve[i]) {
            prev = curr;
            curr = i;
            if (curr - prev > prime2 - prime1) {
                prime2 = curr;
                prime1 = prev;
            }
        };

    const writer = std.io.getStdOut().writer();
    try writer.print("{} is the largest difference between adjacent primes under {}\n", .{ prime2 - prime1, LIMIT });
    try writer.print("between {} and {}\n", .{ prime2, prime1 });
}

/// Simple sieve of Eratothenes.
/// true denotes prime, false denotes composite.
fn sieve(comptime limit: usize) [limit]bool {
    @setEvalBranchQuota(limit * 2);
    var array: [limit]bool = undefined;
    @memset(&array, true);
    array[0] = false; // zero is not prime
    array[1] = false; // one is not prime
    var i: usize = 4;
    while (i < limit) : (i += 2)
        array[i] = false; // even numbers are composite
    var p: usize = 3;
    while (true) {
        const p2 = p * p;
        if (p2 >= limit) break;
        i = p2;
        while (i < limit) : (i += 2 * p)
            array[i] = false;
        while (true) {
            p += 2;
            if (array[p])
                break;
        }
    }
    return array;
}
