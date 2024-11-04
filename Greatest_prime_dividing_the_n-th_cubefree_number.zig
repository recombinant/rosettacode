// https://rosettacode.org/wiki/Greatest_prime_dividing_the_n-th_cubefree_number
const std = @import("std");
const fmt = std.fmt;
const heap = std.heap;
const math = std.math;
const mem = std.mem;
const time = std.time;

const assert = std.debug.assert;
const print = std.debug.print;

// https://rosettacode.org/wiki/Extensible_prime_generator
const PrimeGen = @import("Extensible_prime_generator_alternate.zig").PrimeGen;
const AutoSieveType = @import("Extensible_prime_generator_alternate.zig").AutoSieveType;

// https://rosettacode.org/wiki/Largest_prime_factor
const findLargestPrimeFactor = @import("Largest_prime_factor.zig").findLargestPrimeFactor;

pub fn main() !void {
    var t0 = try time.Timer.start();

    const task1_limit: u32 = 100;
    var task2_count: u32 = 1000;
    const task_stretch_limit: u32 = 10_000_000;

    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Pre-compute a cubefree sieve.
    const cube_free = try getSieve3(allocator, task_stretch_limit);
    defer allocator.free(cube_free);

    var first_hundred = try std.BoundedArray(u32, task1_limit).init(1);
    first_hundred.set(0, 1);

    var count: u32 = 1;
    var n: u32 = 2;
    while (count < task_stretch_limit) : (n += 1) {
        if (cube_free[n]) {
            if (count < task1_limit) {
                const largest = findLargestPrimeFactor(u32, n);
                try first_hundred.append(largest);
            }
            count += 1;
            if (count == task1_limit) {
                print("The first {} terms of a370833 are:\n", .{task1_limit});
                for (first_hundred.slice(), 1..) |num, i| {
                    const sep: u8 = if (i % 10 == 0) '\n' else ' ';
                    print("{d:3}{c}", .{ num, sep });
                }
                print("\n", .{});
            } else if (count == task2_count) {
                assert(n <= cube_free.len); // validate estimate in getSieve3()
                const largest = findLargestPrimeFactor(u32, n);
                print("The {}th term of a370833 is {}\n", .{ count, largest });
                task2_count *= 10;
            }
        }
    }
    print("\nprocessed in {}\n", .{fmt.fmtDuration(t0.read())});
}

/// Sieve for cubefree numbers. Cubefree are true in the returned slice,
/// others are false.
///
/// An array of bool is returned rather than a bitset as Zig 0.14 bitsets
/// were considerably slower than an array of bool for a simple
/// isSet() operation with > 10_000_000 bits.
///
/// Caller owns returned slice memory.
fn getSieve3(allocator: mem.Allocator, comptime maximum: u32) ![]const bool {
    // ----------------------------------- estimate maximum prime
    // (estimate primes in range here rather than cubefree in range)
    // PrimePages
    // https://t5k.org/howmany.html
    const f: f32 = @floatFromInt(maximum);
    const limit: u32 = @intFromFloat(f * (@log(f) + @log(@log(f)) - 0.9427));
    // ----------------------------------------------------------
    var sieve3 = try allocator.alloc(bool, limit);
    @memset(sieve3, true);

    const T = AutoSieveType(limit);
    var primegen = PrimeGen(T).init(allocator);
    defer primegen.deinit();

    while (true) {
        const prime = (try primegen.next()).?;
        const cubed = try math.powi(u32, prime, 3);
        if (cubed >= limit)
            return sieve3;
        sieve3[cubed] = false;
        var n = cubed + cubed;
        while (n < limit) : (n += cubed)
            sieve3[n] = false;
    }
    unreachable;
}
