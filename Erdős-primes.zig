// https://rosettacode.org/wiki/Erdős-primes
// {{works with|Zig|0.15.1}}

// zig run Erdős-primes.zig -I ../primesieve-12.9/zig-out/include/ ../primesieve-12.9/zig-out/lib/primesieve.lib -lstdc++
const std = @import("std");
const ps = @cImport({
    @cInclude("primesieve.h");
});

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    // sieve for isPrime()
    const limit = 1_000_000;
    const sieve = try PrimeSieve.init(allocator, limit);
    defer sieve.deinit(allocator);

    var it: ps.primesieve_iterator = undefined;
    ps.primesieve_init(&it);
    defer ps.primesieve_free_iterator(&it);

    var count: usize = 0;
    var found = false;
    try stdout.writeAll("Erdős primes under 2500:\n");
    while (true) {
        const p = ps.primesieve_next_prime(&it);
        if (it.is_error != 0 or p == ps.PRIMESIEVE_ERROR)
            return error.PrimesieveError;
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

    fn init(allocator: std.mem.Allocator, limit: usize) !PrimeSieve {
        var primes = try allocator.alloc(bool, limit);
        @memset(primes, false);
        var it: ps.primesieve_iterator = undefined;
        ps.primesieve_init(&it);
        defer ps.primesieve_free_iterator(&it);
        {
            // consume 2
            const p = ps.primesieve_next_prime(&it);
            if (it.is_error != 0 or p == ps.PRIMESIEVE_ERROR)
                return error.PrimesieveError;
        }
        while (true) {
            const p = ps.primesieve_next_prime(&it);
            if (it.is_error != 0 or p == ps.PRIMESIEVE_ERROR)
                return error.PrimesieveError;
            if (p >= limit) break;
            primes[p >> 1] = true;
        }
        return PrimeSieve{
            .sieve = primes,
        };
    }
    fn deinit(self: *const PrimeSieve, allocator: std.mem.Allocator) void {
        allocator.free(self.sieve);
    }
    fn isPrime(self: PrimeSieve, n: u64) bool {
        return n == 2 or ((n & 1) == 1 and self.sieve[n >> 1]);
    }
};
