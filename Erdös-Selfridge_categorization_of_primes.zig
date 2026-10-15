// https://rosettacode.org/wiki/Erdös-Selfridge_categorization_of_primes
// {{works with|Zig|0.17.0}}
// {{Trans|C++}}

const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

// Using wrapper around cpp primesieve from https://github.com/kimwalisch/primesieve/
const primesieve = @import("primesieve");

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout_writer = &stdout_file.interface;

    const limit1 = 200;
    const limit2 = 1_000_000;

    var es: ErdosSelfridge = .init(gpa, limit2);
    defer es.deinit(gpa);

    try stdout_writer.writeAll("First 200 primes:\n");
    {
        var t0: Io.Timestamp = .now(io, .real);

        var pbc1 = es.getPrimesByCategory(gpa, limit1);
        for (pbc1.keys()) |category| {
            try stdout_writer.print("Category {}:\n", .{category});
            const primes = pbc1.get(category).?.items;
            for (primes, 1..) |prime, i| {
                const spacer: u8 = if (i % 15 == 0) '\n' else ' ';
                try stdout_writer.print("{d:4}{c}", .{ prime, spacer });
            }
            try stdout_writer.writeAll("\n\n");
        }
        for (pbc1.values()) |*array| array.deinit(gpa);
        pbc1.deinit(gpa);

        try stdout_writer.flush();
        std.log.info("processed in {f}", .{t0.untilNow(io, .real)});
    }

    try stdout_writer.writeAll("\nFirst 1,000,000 primes:\n");
    {
        var t0: Io.Timestamp = .now(io, .real);

        var pbc2 = es.getPrimesByCategory(gpa, limit2);
        for (pbc2.keys()) |category| {
            const primes = pbc2.get(category).?.items;
            try stdout_writer.print(
                "Category {d:2}: first = {d:7}  last = {d:8}  count = {}\n",
                .{ category, primes[0], primes[primes.len - 1], primes.len },
            );
        }
        for (pbc2.values()) |*array| array.deinit(gpa);
        pbc2.deinit(gpa);

        try stdout_writer.writeAll("\n\n");
        try stdout_writer.flush();
        std.log.info("processed in {f}", .{t0.untilNow(io, .real)});
    }
}

const Pair = struct {
    prime: u64,
    category: u32,
};

const ErdosSelfridge = struct {
    pairs: []Pair,

    fn init(allocator: Allocator, limit: u64) ErdosSelfridge {
        var prime_array: std.ArrayList(Pair) = .empty;
        var it: primesieve.Iterator = .init();
        it.jumpTo(0, limit);
        var i: usize = 0;
        while (it.next()) |prime| : (i += 1) {
            if (i >= limit)
                break;
            prime_array.append(allocator, .{ .prime = prime, .category = 0 }) catch unreachable;
        }

        return .{ .pairs = prime_array.toOwnedSlice(allocator) catch unreachable };
    }
    fn deinit(self: *ErdosSelfridge, allocator: Allocator) void {
        allocator.free(self.pairs);
    }
    fn getCategory(self: ErdosSelfridge, index: usize) u32 {
        var pair = self.pairs[index];
        if (pair.category != 0)
            return pair.category;
        var max_category: u32 = 0;
        var n = pair.prime + 1;
        var i: usize = 0;
        while (n > 1) : (i += 1) {
            const p = self.pairs[i].prime;
            if (p * p > n)
                break;
            var count: usize = 0;
            while (n % p == 0) : (count += 1)
                n /= p;
            if (count != 0) {
                const category: u32 = if (p <= 3) 1 else 1 + self.getCategory(i);
                max_category = @max(max_category, category);
            }
        }
        if (n > 1) {
            const category: u32 = if (n <= 3) 1 else 1 + self.getCategory(self.getIndex(n));
            max_category = @max(max_category, category);
        }
        pair.category = max_category;
        return max_category;
    }
    fn getIndex(self: *const ErdosSelfridge, prime: u64) usize {
        return std.sort.binarySearch(Pair, self.pairs, prime, comparePrimes) orelse unreachable;
    }

    fn comparePrimes(prime: u64, pair: Pair) std.math.Order {
        return std.math.order(prime, pair.prime);
    }

    const PrimesByCategory = std.AutoArrayHashMapUnmanaged(u32, std.ArrayList(u64));
    fn getPrimesByCategory(self: *const ErdosSelfridge, allocator: Allocator, limit: usize) PrimesByCategory {
        var primes_by_category: PrimesByCategory = .empty;

        for (self.pairs, 0..) |pair, i| {
            if (i >= limit)
                break;
            const prime = pair.prime;
            const category = self.getCategory(i);

            const gop = primes_by_category.getOrPut(allocator, category) catch unreachable;
            if (!gop.found_existing)
                gop.value_ptr.* = .empty;

            gop.value_ptr.append(allocator, prime) catch unreachable;
        }
        return primes_by_category;
    }
};
