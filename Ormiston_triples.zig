// https://rosettacode.org/wiki/Ormiston_triples
// Translated from C++
const std = @import("std");
const fmt = std.fmt;
const heap = std.heap;
const io = std.io;
const mem = std.mem;
const time = std.time;

// https://rosettacode.org/wiki/Extensible_prime_generator
const AutoSieveType = @import("sieve.zig").AutoSieveType;
const PrimeGen = @import("sieve.zig").PrimeGen;

pub fn main() !void {
    var t0 = try time.Timer.start();

    const task1_limit = 25;
    const task2_limit = 1_000_000_000;
    const task3_limit = 10_000_000_000;
    const T = AutoSieveType(task3_limit * 10); // allow some leeway

    const stdout = io.getStdOut().writer();
    try stdout.writeAll("Primesieve Ormiston triples\n\n");

    // -------------------------
    // allocator for the prime number generator within
    // the triple generator
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var generator = try OrmistonTripleGenerator(T).init(allocator);
    defer generator.deinit();

    // --------------------------------------------------- task 1
    try stdout.writeAll("Smallest members of first 25 Ormiston triples:\n");
    var count: usize = 0;
    while (count < task1_limit) : (count += 1) {
        const primes = try generator.next();
        try stdout.print("{d}{c}", .{ primes[0], @as(u8, if ((count + 1) % 5 == 0) '\n' else ' ') });
    }
    // ---------------------------------------------- tasks 2 & 3
    var limit: T = task2_limit;
    while (limit <= task3_limit) : (count += 1) {
        const primes = try generator.next();
        if (primes[2] > limit) {
            try stdout.print("\nNumber of Ormiston triples < {d}: {d}\n", .{ limit, count });
            limit *= 10;
        }
    }
    // -------------------------
    try stdout.print("Processed in {}\n", .{fmt.fmtDuration(t0.read())});
}

const OrmistonTripleGeneratorError = error{
    PrimeGenNull,
};

fn OrmistonTripleGenerator(T: type) type {
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("OrmistonTripleGenerator requires an unsigned integer, found " ++ @typeName(T));

    return struct {
        const Self = @This();

        prime_iterator: PrimeGen(T),
        prime1: T,
        prime2: T,

        fn init(allocator: mem.Allocator) !Self {
            var it = PrimeGen(T).init(allocator);

            var primes: [2]T = undefined;
            for (&primes) |*prime| {
                if (try it.next()) |p|
                    prime.* = p
                else
                    return OrmistonTripleGeneratorError.PrimeGenNull;
            }
            return Self{
                .prime_iterator = it,
                .prime1 = primes[0],
                .prime2 = primes[1],
            };
        }
        fn deinit(self: *Self) void {
            self.prime_iterator.deinit();
        }

        fn next(self: *Self) ![3]u64 {
            while (true) {
                if (try self.prime_iterator.next()) |prime| {
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
                    const signature = calcSignature(T, prime0);
                    if (signature != calcSignature(T, self.prime1))
                        continue;
                    if (signature != calcSignature(T, self.prime2))
                        continue;

                    return .{ prime0, self.prime1, self.prime2 };
                } else {
                    return OrmistonTripleGeneratorError.PrimeGenNull;
                }
            }
        }
    };
}

/// Same digits different order will give the same signature.
/// Count of each digit in 'n_' packed into an integer.
/// 60 bits (10 decimal digits 0 to 9 inclusive, 6 bits per digit)
/// - for a number with up to 63 identical decimal digits.
fn calcSignature(T: type, n_: T) u60 {
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
