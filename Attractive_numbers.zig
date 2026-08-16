// https://rosettacode.org/wiki/Attractive_numbers
// {{works with|Zig|0.16.0}}
// {{trans|C}}

const std = @import("std");
const Io = std.Io;

const MAX: u64 = 120;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(init.io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("The attractive numbers up to and including {d} are:\n", .{MAX});

    var count: usize = 0;
    for (1..MAX + 1) |i| {
        const n = countPrimeFactors(i);
        if (isPrime(n)) {
            try stdout.print("{d:>4}", .{i});
            count += 1;
            if (count % 20 == 0) try stdout.writeByte('\n');
        }
    }
    try stdout.writeByte('\n');
    try stdout.flush();
}

fn countPrimeFactors(n_: u64) usize {
    if (n_ == 1) return 0;
    if (isPrime(n_)) return 1;

    var n = n_;

    var count: usize = 0;
    var f: u64 = 2;
    while (true) {
        if (n % f == 0) {
            count += 1;
            n = @divTrunc(n, f);
            if (n == 1) return count;
            if (isPrime(n)) f = n;
        } else if (f >= 3) {
            f += 2;
        } else {
            f = 3;
        }
    }
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
