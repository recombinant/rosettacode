// https://rosettacode.org/wiki/Smarandache_prime-digital_sequence
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    const limit = 1_000_000_000;
    var n: u32 = 0;
    var max: u32 = 0;
    print("First 25 SPDS primes:\n", .{});
    var i: usize = 0;
    while (n < limit) {
        n = nextPrimeDigitNumber(n);
        if (!isPrime(n))
            continue;
        if (i < 25) {
            if (i > 0)
                print(" ", .{});
            print("{d}", .{n});
        } else if (i == 25)
            print("\n", .{});
        i += 1;
        if (i == 100)
            print("Hundredth SPDS prime: {d}\n", .{n})
        else if (i == 1_000)
            print("Thousandth SPDS prime: {d}\n", .{n})
        else if (i == 10_000)
            print("Ten thousandth SPDS prime: {d}\n", .{n});
        max = n;
    }
    print("Largest SPDS prime less than {d}: {d}\n", .{ limit, max });
}

fn nextPrimeDigitNumber(n: anytype) @TypeOf(n) {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("nextPrimeDigitNumber() expected unsigned integer argument, found " ++ @typeName(T));

    if (n == 0)
        return 2;
    return switch (n % 10) {
        2 => n + 1,
        3, 5 => n + 2,
        else => 2 + nextPrimeDigitNumber(n / 10) * 10,
    };
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
