// https://rosettacode.org/wiki/Pollard%27s_rho_algorithm
// {{works with|Zig|0.15.1}}
// {{trans|C++}}
const std = @import("std");

pub fn main() void {
    // --------------------------- Pseudo Random Number Generator
    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const random = prng.random();
    // ----------------------------------------------------------
    const T = u70;
    const numbers = [_]T{
        4294967213,
        9759463979,
        34225158206557151,
        763218146048580636353,
    };
    for (numbers) |n| {
        const divisor_one = runPollardsRho(T, random, n);
        const divisor_two = n / divisor_one;
        std.debug.print(
            "{d} = {d} * {d} ({} bits)\n",
            .{ n, divisor_one, divisor_two, @typeInfo(T).int.bits - @clz(n) },
        );
    }
}

fn runPollardsRho(T: type, random: std.Random, number: T) T {
    if (number % 2 == 0)
        return 2;

    // Twice the number of bits as `T`
    const U: type = std.meta.Int(.unsigned, @typeInfo(T).int.bits * 2);

    const bit_length = @typeInfo(T).int.bits - @clz(number);
    const constant = random.intRangeLessThan(U, 0, bit_length);
    var x = random.intRangeAtMost(U, 0, bit_length);
    var y = x;
    var divisor: U = 1;

    // Zig implementation of C++ do..while() loop
    var do = true;
    while (divisor == 1 or do) {
        do = false;
        // Use wraparound semantics, ie. *% and -%
        x = (x *% x + constant) % number;
        y = (y *% y + constant) % number;
        y = (y *% y + constant) % number;
        divisor = std.math.gcd(x -% y, number);
    }
    return @truncate(divisor);
}
