// https://rosettacode.org/wiki/Frobenius_numbers
// {{works with|Zig|0.16.0}}
// {{trans|C++}}

// Using cpp primesieve from https://github.com/kimwalisch/primesieve/
const ps = @import("primesieve");

const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const limit = 1_000_000;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(init.io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Frobenius numbers less than {} (asterisk marks primes):\n", .{limit});

    var it: ps.primesieve_iterator = undefined;
    ps.primesieve_init(&it);
    defer ps.primesieve_free_iterator(&it);

    var count: u64 = 1;

    var prime1 = ps.primesieve_next_prime(&it);
    if (it.is_error != 0 or prime1 == ps.PRIMESIEVE_ERROR)
        return error.PrimesieveError;

    while (true) : (count += 1) {
        const prime2 = ps.primesieve_next_prime(&it);
        if (it.is_error != 0 or prime2 == ps.PRIMESIEVE_ERROR)
            return error.PrimesieveError;

        const frobenius = prime1 * prime2 - prime1 - prime2;
        if (frobenius >= limit)
            break;
        try stdout.print("{d:>6}{c}{c}", .{
            frobenius,
            @as(u8, if (isPrime(frobenius)) '*' else ' '),
            @as(u8, if (count % 10 == 0) '\n' else ' '),
        });
        prime1 = prime2;
    }
    try stdout.writeByte('\n');
    try stdout.flush();
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
