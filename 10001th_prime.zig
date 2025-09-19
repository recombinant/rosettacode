// https://rosettacode.org/wiki/10001th_prime
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    const n = 10001;
    const f: f32 = @floatFromInt(n);
    // ----------------------------- estimate maximum prime plus some
    const limit: usize = @intFromFloat(@floor(@log(f) * f * 1.2));
    // ---------------------------------------------------- allocator
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------
    const primes = try pritchard(allocator, u32, limit);
    defer allocator.free(primes);
    std.debug.print("The {}th prime is: {}\n", .{ n, primes[n - 1] });
}

/// Pritchard's sieve of primes up to limit with a StaticBitSet.
pub fn pritchard(allocator: std.mem.Allocator, T: type, comptime limit: usize) ![]T {
    var members: std.bit_set.ArrayBitSet(usize, limit) = .initEmpty();
    var mcopy: std.bit_set.ArrayBitSet(usize, limit) = .initEmpty();
    members.set(1);

    var steplength: usize = 1;
    var prime: usize = 2;
    const rtlim: usize = std.math.sqrt(limit);
    var nlimit: usize = 2;

    var primes: std.ArrayList(T) = .empty;
    while (prime < rtlim) {
        if (steplength < limit) {
            for (1..steplength) |w|
                if (members.isSet(w)) {
                    var n = w + steplength;
                    while (n <= nlimit) {
                        members.set(n);
                        n += steplength;
                    }
                };
            steplength = nlimit; // advance wheel size
        }
        var np: usize = 5;

        // copy `members` to `mcopy` using knowledge of ArrayBitSet internals
        @memcpy(&mcopy.masks, &members.masks);

        for (1..nlimit) |w| {
            if (mcopy.isSet(w)) {
                if (np == 5 and w > prime)
                    np = w;

                const n = prime * w;
                if (n > nlimit)
                    break; // no use trying to remove items that can't even be there

                members.unset(n); // no checking necessary now
            }
        }
        if (np < prime)
            break;

        try primes.append(allocator, @intCast(prime));
        prime = if (prime == 2) 3 else np;
        nlimit = @min(steplength * prime, limit); // advance wheel limit
    }
    try primes.ensureTotalCapacity(allocator, primes.items.len + members.count());
    members.unset(1);
    var it = members.iterator(.{});
    while (it.next()) |p|
        try primes.append(allocator, @intCast(p));

    return primes.toOwnedSlice(allocator);
}

const testing = std.testing;

test pritchard {
    const primes = try pritchard(testing.allocator, i32, 1_000_000);
    defer testing.allocator.free(primes);

    for (primes[0 .. primes.len - 1], primes[1..]) |a, b|
        try testing.expect(b > a);

    try testing.expectEqual(5, primes[2]);
    try testing.expectEqual(541, primes[99]);
    try testing.expectEqual(999983, primes[primes.len - 1]);
}
