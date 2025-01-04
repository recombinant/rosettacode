// https://rosettacode.org/wiki/Ormiston_triples
// Translation of C++
const std = @import("std");
const mem = std.mem;
// Using cpp primesieve from https://github.com/kimwalisch/primesieve/
const ps = @cImport({
    @cInclude("primesieve.h");
});

pub fn main() !void {
    var t0 = try std.time.Timer.start();
    // ----------------------------------------------------------
    const task1_limit = 25;
    const task2_limit = 1_000_000_000;
    const task3_limit = 10_000_000_000;
    // ----------------------------------------------------------
    const writer = std.io.getStdOut().writer();
    try writer.writeAll("Primesieve Ormiston triples\n\n");
    // ----------------------------------------------------------
    var generator = try OrmistonTripleGenerator.init();
    defer generator.deinit();
    // --------------------------------------------------- task 1
    try writer.writeAll("Smallest members of first 25 Ormiston triples:\n");
    var count: usize = 0;
    while (count < task1_limit) : (count += 1) {
        const primes = try generator.next();
        try writer.print("{d}{c}", .{ primes[0], @as(u8, if ((count + 1) % 5 == 0) '\n' else ' ') });
    }
    // ---------------------------------------------- tasks 2 & 3
    var limit: u64 = task2_limit;
    while (limit <= task3_limit) : (count += 1) {
        const primes = try generator.next();
        if (primes[2] > limit) {
            try writer.print("\nNumber of Ormiston triples < {d}: {d}\n", .{ limit, count });
            limit *= 10;
        }
    }
    // ----------------------------------------------------------
    try writer.print("Processed in {}\n", .{std.fmt.fmtDuration(t0.read())});
}

const OrmistonTripleGeneratorError = error{
    PrimesieveError,
};

const OrmistonTripleGenerator = struct {
    const Self = @This();

    it: ps.primesieve_iterator,
    prime1: u64,
    prime2: u64,

    fn init() !Self {
        var it: ps.primesieve_iterator = undefined;
        ps.primesieve_init(&it);

        var primes: [2]u64 = undefined;
        for (&primes) |*prime| {
            prime.* = ps.primesieve_next_prime(&it);
            if (it.is_error != 0 or prime.* == ps.PRIMESIEVE_ERROR)
                return OrmistonTripleGeneratorError.PrimesieveError;
        }
        return Self{
            .it = it,
            .prime1 = primes[0],
            .prime2 = primes[1],
        };
    }
    fn deinit(self: *Self) void {
        defer ps.primesieve_free_iterator(&self.it);
    }
    fn next(self: *Self) ![3]u64 {
        while (true) {
            const prime = ps.primesieve_next_prime(&self.it);
            if (self.it.is_error != 0 or prime == ps.PRIMESIEVE_ERROR)
                return OrmistonTripleGeneratorError.PrimesieveError;

            const prime0 = self.prime1;
            self.prime1 = self.prime2;
            self.prime2 = prime;

            // Simple short-circuit
            // - to be a triple they must differ by 18.
            // https://oeis.org/A072274
            if ((self.prime1 - prime0) % 18 != 0)
                continue;
            if ((self.prime2 - self.prime1) % 18 != 0)
                continue;

            // Calculating signatures locally here is
            // faster than maintaining variables at
            // struct scope in Self
            const signature = calcSignature(prime0);
            if (signature != calcSignature(self.prime1))
                continue;
            if (signature != calcSignature(self.prime2))
                continue;

            return .{ prime0, self.prime1, self.prime2 };
        }
    }
};

/// Same digits different order will give the same signature.
/// Count of each digit in 'n_' packed into an integer.
/// 60 bits (10 decimal digits 0 to 9 inclusive, 6 bits per digit)
/// - for a number with up to 63 identical decimal digits.
fn calcSignature(n_: anytype) u60 {
    const T = @TypeOf(n_);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("calcSignature requires an unsigned integer, found " ++ @typeName(T));

    // n == 0 will return zero
    var n = n_;
    var signature: u60 = 0;

    // Zig's comptime will expand inline switch branch.
    while (n > 0) {
        signature += switch (n % 10) {
            inline 0...9 => |shift| comptime 1 << (shift * 6),
            else => unreachable,
        };
        n /= 10;
    }
    return signature;
}
