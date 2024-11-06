// https://rosettacode.org/wiki/Twin_primes_whose_sum_is_square_number
// Translation of C++
const std = @import("std");

pub fn main() void {
    var n: u32 = 3;
    while (n < 10_000) : (n += 2)
        if (isPrime(n) and isPrime(n + 2)) {
            const sum: u32 = 2 * n + 2;
            const sqrt: u32 = std.math.sqrt(sum);
            if (sum == sqrt * sqrt)
                std.debug.print("{}² = {} + {}\n", .{ sqrt, n, n + 2 });
        };
}

fn isPrime(n: anytype) bool {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("isPrime() expected unsigned integer argument, found " ++ @typeName(T));

    if (n < 2) return false;
    if (n % 2 == 0) return n == 2;
    if (n % 3 == 0) return n == 3;
    if (n % 5 == 0) return n == 5;

    const wheel = [_]T{ 4, 2, 4, 2, 4, 6, 2, 6 };

    var p: T = 7;
    while (true)
        for (wheel) |w| {
            if (p * p > n) return true;
            if (n % p == 0) return false;
            p += w;
        };
}
