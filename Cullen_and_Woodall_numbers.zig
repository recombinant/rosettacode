// https://rosettacode.org/wiki/Cullen_and_Woodall_numbers
// TODO: complete stretch task - Woodhall primes and Cullen primes - requires GMP
const std = @import("std");
const math = std.math;
const print = std.debug.print;

pub fn main() void {
    displayNumberSequence(20, .cullen);
    displayNumberSequence(20, .woodhall);

    print("These two run out of bits and stop.\nThey require a bit integer implementation with Miller-Rabin primality test.\n\n", .{});
    displayPrimeNumberNSequence(5, .cullen);
    displayPrimeNumberNSequence(12, .woodhall);
}

fn displayNumberSequence(count: usize, number_type: NumberType) void {
    print("The first {} {} numbers are:\n", .{ count, number_type });

    var it = NumberIterator.init(number_type);

    for (0..count) |_|
        print("{} ", .{it.next()});

    print("\n\n", .{});
}

fn displayPrimeNumberNSequence(count: usize, number_type: NumberType) void {
    print("The first (up to) {} {} prime numbers are:\n", .{ count, number_type });

    var it = PrimeNumberNIterator.init(number_type);

    for (0..count) |_| {
        const n = it.next() catch break;
        print("{} ", .{n});
    }
    print("\n\n", .{});
}

const NumberType = enum {
    cullen,
    woodhall,

    pub fn format(
        self: NumberType,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.writeAll(switch (self) {
            .cullen => "Cullen",
            .woodhall => "Woodhall",
        });
    }
};

const NumberIterator = struct {
    number_type: NumberType,
    n: u64,

    fn init(number_type: NumberType) NumberIterator {
        return NumberIterator{
            .number_type = number_type,
            .n = 0,
        };
    }

    fn next(self: *NumberIterator) u64 {
        self.n += 1;
        const two_to_the_n = math.shl(u64, 1, self.n);
        return switch (self.number_type) {
            .cullen => self.n * two_to_the_n + 1,
            .woodhall => self.n * two_to_the_n - 1,
        };
    }
};

/// TODO: requires big integers and Baillie–PSW primality test/Miller-Rabin primality test
const PrimeNumberNIterator = struct {
    number_type: NumberType,
    n: u128,

    fn init(number_type: NumberType) PrimeNumberNIterator {
        return PrimeNumberNIterator{
            .number_type = number_type,
            .n = 0,
        };
    }

    fn next(self: *PrimeNumberNIterator) !u128 {
        while (true) {
            self.n += 1;
            const two_to_the_n = math.shl(u128, 1, self.n);
            const ov = @mulWithOverflow(self.n, two_to_the_n);
            if (ov[1] != 0)
                return error.Overflow;
            const result = switch (self.number_type) {
                .cullen => self.n * two_to_the_n + 1,
                .woodhall => self.n * two_to_the_n - 1,
            };
            const b = isPrime(result) catch |err| return err;
            if (b)
                return self.n;
        }
    }
};

fn isPrime(n: u128) !bool {
    if (n <= 3)
        return n > 1;
    if (n % 2 == 0 or n % 3 == 0)
        return false;

    var d: u128 = 5;
    var d2 = d * d;
    while (d2 <= n) : (d += 6) {
        if ((n % d) == 0 or (n % (d + 2)) == 0)
            return false;
        const ov = @mulWithOverflow(d, d);
        if (ov[1] != 0)
            return error.Overflow;
        d2 = ov[0];
        // Remove following line when use of big integers is implemented.
        if (d2 > comptime math.maxInt(u48)) return error.Stopping; // arbitrarily give up now
    }
    return true;
}
