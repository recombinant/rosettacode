// https://rosettacode.org/wiki/Erdős-primes
// {{works with|Zig|0.17.0}}

const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

// Using wrapper around cpp primesieve from https://github.com/kimwalisch/primesieve/
const primesieve = @import("primesieve");

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    // sieve for isPrime()
    const limit = 1_000_000;
    const sieve: PrimeSieve = try .init(gpa, limit);
    defer sieve.deinit(gpa);

    var it: primesieve.Iterator = .init();
    defer it.deinit();
    var count: usize = 0;
    var found = false;
    try stdout.writeAll("Erdős primes under 2500:\n");
    while (true) {
        const p = it.next() orelse return error.PrimesieveError;
        if (isErdos(p, &sieve)) {
            if (p > 2500 and !found) {
                // Task 1, optional
                try stdout.print("\n\nThe number of Erdős primes less than 2,500: {}\n", .{count});
                found = true;
            }
            count += 1;
            if (p < 2500)
                try stdout.print("{} ", .{p}) // Task 1
            else if (count == 7875) {
                // Task 2
                try stdout.print("\nThe 7,875th Erdős prime is: {}\n", .{p});
                break;
            }
        }
    }
    try stdout.flush();
}

fn isErdos(prime: u64, sieve: *const PrimeSieve) bool {
    var k: u64 = 1;
    var factorial: u64 = 1;
    while (factorial < prime) {
        if (sieve.isPrime(prime - factorial))
            return false;
        k += 1;
        factorial *= k;
    }
    return true;
}

const PrimeSieve = struct {
    sieve: []const bool,

    fn init(allocator: Allocator, limit: usize) !PrimeSieve {
        var primes = try allocator.alloc(bool, limit);
        @memset(primes, false);

        var it: primesieve.Iterator = .init();
        defer it.deinit();

        _ = it.next().?; // consume (2)
        while (it.next()) |p| {
            if (p >= limit) break;
            primes[p >> 1] = true;
        }
        return PrimeSieve{
            .sieve = primes,
        };
    }
    fn deinit(self: *const PrimeSieve, allocator: Allocator) void {
        allocator.free(self.sieve);
    }
    fn isPrime(self: PrimeSieve, n: u64) bool {
        return n == 2 or ((n & 1) == 1 and self.sieve[n >> 1]);
    }
};
