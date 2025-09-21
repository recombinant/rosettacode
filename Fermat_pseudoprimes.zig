// https://rosettacode.org/wiki/Fermat_pseudoprimes
// {{works with|Zig|0.15.1}}
// {{trans|C++}}
const std = @import("std");

pub fn main() !void {
    var buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&buffer);
    const stdout = &stdout_writer.interface;
    {
        // ----------------------------------------------------------- task
        try stdout.print("First 20 Fermat pseudoprimes:\n", .{});
        var a: u64 = 1;
        while (a <= 20) : (a += 1) {
            try stdout.print("Base {d:2}: ", .{a});
            var count: usize = 0;
            var x: u64 = 4;
            while (count < 20) : (x += 1)
                if (isFermatPseudoprime(a, x)) {
                    count += 1;
                    try stdout.print("{d:5} ", .{x});
                };
            try stdout.writeByte('\n');
        }
    }
    {
        // -------------------------------------------------------- stretch
        const limits = [_]u64{ 12_000, 25_000, 50_000, 10_000 };
        try stdout.print("\nCount <= ", .{});
        for (limits) |limit|
            try stdout.print("{d:6} ", .{limit});

        try stdout.print("\n------------------------------------\n", .{});
        var a: u64 = 1;
        while (a <= 20) : (a += 1) {
            try stdout.print("Base {d:2}: ", .{a});
            var count: usize = 0;
            var x: u64 = 4;
            for (limits) |limit| {
                while (x <= limit) : (x += 1)
                    if (isFermatPseudoprime(a, x)) {
                        count += 1;
                    };
                try stdout.print("{d:6} ", .{count});
            }
            try stdout.writeByte('\n');
        }
    }
    try stdout.flush();
}

fn modpow(base_: u64, exp_: u64, mod: u64) u64 {
    if (mod == 1)
        return 0;
    var result: u64 = 1;
    var base = base_ % mod;
    var exp = exp_;
    while (exp > 0) : (exp >>= 1) {
        if ((exp & 1) == 1)
            result = (result * base) % mod;
        base = (base * base) % mod;
    }
    return result;
}

fn isPrime(n: u64) bool {
    if (n < 2) return false;
    if (n % 2 == 0) return n == 2;
    if (n % 3 == 0) return n == 3;
    if (n % 5 == 0) return n == 5;

    const wheel = [_]u64{ 4, 2, 4, 2, 4, 6, 2, 6 };

    var k: u64 = 7;
    var i: usize = 1;
    while (k * k <= n) : (i = (i + 1) & 7) {
        if (n % k == 0) return false;
        k += wheel[i];
    }
    return true;
}

fn isFermatPseudoprime(a: u64, x: u64) bool {
    return !isPrime(x) and modpow(a, x - 1, x) == 1;
}
