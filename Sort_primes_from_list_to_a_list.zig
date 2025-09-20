// https://rosettacode.org/wiki/Sort_primes_from_list_to_a_list
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    const primes = [_]u8{ 2, 43, 81, 122, 63, 13, 7, 95, 103 };

    var buffer: [primes.len]u8 = undefined;
    var array: std.ArrayList(u8) = .initBuffer(&buffer);

    for (primes) |prime|
        if (isPrime(prime))
            try array.appendBounded(prime);

    std.mem.sortUnstable(u8, array.items, {}, std.sort.asc(u8));

    std.debug.print("Primes are: {any}\n", .{array.items});
}

fn isPrime(n: anytype) bool {
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
