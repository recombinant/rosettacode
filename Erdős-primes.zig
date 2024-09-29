// https://rosettacode.org/wiki/Emirp_primes
const std = @import("std");
const math = std.math;
const mem = std.mem;
const sort = std.sort;
const testing = std.testing;
const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var factorials = try FactorialList.init(allocator);
    defer factorials.deinit();

    var pit = PrimeIterator.init();

    var primes = std.ArrayList(u64).init(allocator);
    defer primes.deinit();
    try primes.append(2);

    var count: usize = 0;
    var erdos_prime_count: usize = 0;
    const p: u64 = blk: {
        print("\nErdős primes less that 2500: ", .{});
        while (true) {
            const p = pit.next();
            try primes.append(p);

            if (try isErdos(p, primes.items, &factorials)) {
                if (p < 2500) {
                    // Task 1
                    print("{} ", .{p});
                    erdos_prime_count = count;
                } else if (erdos_prime_count != 0) {
                    // Task 1, optional
                    print("\n\nThe number of Erdős primes less that 2500: {}\n", .{erdos_prime_count});
                    erdos_prime_count = 0;
                }
                count += 1;
                if (count == 7875)
                    break :blk p; // Task 2
            }
        }
    };
    print("\nThe {}th Erdős prime is {}\n", .{ count, p }); // Task 2
}

fn orderU64(context: u64, item: u64) math.Order {
    return math.order(item, context);
}

fn isErdos(prime: u64, primes: []const u64, factorials: *FactorialList) !bool {
    var k: u64 = 1;
    while (try factorials.factorial(k) < prime) {
        const value = prime - try factorials.factorial(k);
        if (sort.binarySearch(u64, primes, value, orderU64) != null)
            return false;
        k += 1;
    }
    return true;
}

const FactorialList = struct {
    allocator: mem.Allocator,
    factorial_list: std.ArrayList(u64),

    fn init(allocator: mem.Allocator) !FactorialList {
        var factorial_list = std.ArrayList(u64).init(allocator);
        try factorial_list.append(1); // 0!
        return FactorialList{
            .allocator = allocator,
            .factorial_list = factorial_list,
        };
    }
    fn deinit(self: *FactorialList) void {
        self.factorial_list.deinit();
    }

    fn factorial(self: *FactorialList, n: u64) !u64 {
        if (n < self.factorial_list.items.len)
            return self.factorial_list.items[n];
        // Specialized. Cannot calculate an arbitrary factorial.
        assert(n == self.factorial_list.items.len);
        const prev_factorial = self.factorial_list.items[self.factorial_list.items.len - 1];
        const this_factorial = prev_factorial * n;
        try self.factorial_list.append(this_factorial);
        return this_factorial;
    }
};

fn isPrime(n: u64) bool {
    if (n <= 3)
        return n > 1;
    if (n % 2 == 0 or n % 3 == 0)
        return false;

    var d: u32 = 5;
    while (d * d <= n) : (d += 6)
        if (n % d == 0 or n % (d + 2) == 0)
            return false;

    return true;
}

const PrimeIterator = struct {
    n: u64,
    step: u64,

    fn init() PrimeIterator {
        return .{ .n = 2, .step = 1 };
    }

    fn next(self: *PrimeIterator) u64 {
        var n: u64 = self.n;
        const step = self.step;
        while (!isPrime(n))
            n += step;
        self.step = 2; // Even numbers > 2 are not prime.
        self.n = n + step;
        return n;
    }
};

test FactorialList {
    var factorials = try FactorialList.init(testing.allocator);
    defer factorials.deinit();

    const expected_list = [_]u64{ 1, 1, 2, 6, 24, 120, 720, 5_040, 40_320, 362_880 };

    for (expected_list, 0..) |expected, n|
        try testing.expectEqual(expected, try factorials.factorial(@intCast(n)));
}

test PrimeIterator {
    var it = PrimeIterator.init();
    const expected_list = [_]u64{ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29 };

    for (expected_list) |expected|
        try testing.expectEqual(expected, it.next());
}

test isPrime {
    const primes_list = [_]u64{ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29 };
    const composite_list = [_]u64{ 4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20, 21 };

    for (primes_list) |prime|
        try testing.expect(isPrime(prime));
    for (composite_list) |composite|
        try testing.expect(!isPrime(composite));
}
