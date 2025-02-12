// https://rosettacode.org/wiki/Sieve_of_Pritchard
const std = @import("std");
const math = std.math;
const mem = std.mem;
const sort = std.sort;
const testing = std.testing;

pub fn main() !void {
    // ------------------------------------------------------- stdout
    const stdout = std.io.getStdOut().writer();
    // ---------------------------------------------------- allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const ephemeral_allocator = arena.allocator();
    // ---------------------------------------------------- allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------
    var primes = std.ArrayList(usize).init(allocator);
    defer primes.deinit();

    try pritchard(ephemeral_allocator, &primes, 150);
    _ = arena.reset(.retain_capacity);
    for (primes.items) |p|
        try stdout.print("{d} ", .{p});
    try stdout.writeByte('\n');

    try pritchard(ephemeral_allocator, &primes, 1_000_000);
    _ = arena.reset(.retain_capacity);
    try stdout.print("Number of primes up to 1,000,000: {d}\n", .{primes.items.len});
}

/// Pritchard sieve of primes up to limit
pub fn pritchard(allocator: mem.Allocator, primes: *std.ArrayList(usize), limit: usize) !void {
    var members = try std.DynamicBitSet.initEmpty(allocator, limit);
    defer members.deinit();
    members.set(1);

    var steplength: usize = 1;
    var prime: usize = 2;
    const rtlim: usize = math.sqrt(limit);
    var nlimit: usize = 2;

    primes.clearRetainingCapacity();
    while (prime < rtlim) {
        if (steplength < limit) {
            for (1..steplength) |w| {
                if (members.isSet(w)) {
                    var n = w + steplength;
                    while (n <= nlimit) {
                        members.set(n);
                        n += steplength;
                    }
                }
            }
            steplength = nlimit; // advance wheel size
        }

        var np: usize = 5;
        var mcopy = try members.clone(allocator);
        defer mcopy.deinit();
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

        try primes.append(prime);
        prime = if (prime == 2) 3 else np;
        nlimit = @min(steplength * prime, limit); // advance wheel limit
    }

    try primes.ensureTotalCapacity(primes.items.len + members.count());
    members.unset(1);
    var it = members.iterator(.{});
    while (it.next()) |p|
        try primes.append(p);

    // sort.insertion(usize, primes.items, {}, sort.asc(usize));
}

test "sieve of pritchard" {
    var primes = std.ArrayList(usize).init(testing.allocator);
    defer primes.deinit();
    try pritchard(testing.allocator, &primes, 1_000_000);

    try testing.expectEqual(primes.items.len, 78498);
}
