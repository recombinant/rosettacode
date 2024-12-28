// https://rosettacode.org/wiki/Meissel%E2%80%93Mertens_constant
const std = @import("std");
const math = std.math;
const mem = std.mem;

const Float = f64;
const max_number = 100_000_000;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const euler = 0.57721566490153286;

    const primes = try sieve(allocator, max_number);
    const modulo = max_number / 10;

    var sum: Float = 0;

    for (primes, 1..) |p, i| {
        const rp: Float = 1 / @as(Float, @floatFromInt(p));
        sum += @log(1 - rp) + rp;
        if (i % modulo == 0)
            try stdout.print("{d:>12}   {d}\n", .{ i, sum + euler });
    }
    try stdout.print("{d:>12}   {d}\n", .{ primes.len, sum + euler });
}

/// Return at least n prime numbers.
fn sieve(allocator: mem.Allocator, n: usize) ![]u64 {
    const limit: usize = @intFromFloat(blk: {
        const n_: f32 = @floatFromInt(n);
        // https://en.wikipedia.org/wiki/Prime_number_theorem#Approximations_for_the_nth_prime_number
        break :blk @log(n_) + @log(@log(n_));
    });

    var primes = std.ArrayList(u64).init(allocator);
    defer primes.deinit();

    var sieved = try allocator.alloc(bool, limit);
    defer allocator.free(sieved); // redundant if ArenaAllocator used

    // true for prime
    for (sieved) |*b| b.* = true;
    // 0 & 1 are skipped later, so no need to set false here.

    const root_n = math.sqrt(sieved.len);
    for (2..root_n + 1) |p|
        if (sieved[p]) {
            var k = p * p;
            while (k < sieved.len) : (k += p)
                sieved[k] = false; // not prime
        };

    try primes.ensureTotalCapacityPrecise(n + 1);

    // skip 0 & 1, they are not prime
    for (sieved[2..], 2..) |b, i|
        if (b) {
            try primes.append(@intCast(i));
        };

    return primes.toOwnedSlice();
}
