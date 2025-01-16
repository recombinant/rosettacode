// https://rosettacode.org/wiki/Multi-base_primes
// Translation of C++
// Using cpp primesieve from https://github.com/kimwalisch/primesieve/
const std = @import("std");
const ps = @cImport({
    @cInclude("primesieve.h");
});

// pub const std_options = std.Options{
//     .log_level = .info,
// };

pub fn main() !void {
    // var t0 = try std.time.Timer.start();

    const max_base = 36;
    const max_length = 5;

    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const writer = std.io.getStdOut().writer();

    try multiBasePrimes(allocator, max_base, max_length, writer);

    // std.log.info("processed in {}\n", .{std.fmt.fmtDuration(t0.read())});
}

fn multiBasePrimes(allocator: std.mem.Allocator, max_base: u6, max_length: u4, writer: anytype) !void {
    const sieve = try PrimeSieve.init(allocator, try std.math.powi(u64, max_base, max_length));
    defer sieve.deinit(allocator);
    var length: u4 = 1;
    while (length <= max_length) : (length += 1) {
        try writer.print("{}-character strings which are prime in most bases: ", .{length});
        var most_bases: u6 = 0;

        var max_strings = std.ArrayList(Pair).init(allocator);
        defer {
            for (max_strings.items) |pair|
                pair.deinit(allocator);
            max_strings.deinit();
        }

        var digits = try allocator.alloc(u6, length);
        defer allocator.free(digits);
        @memset(digits, 0);
        digits[0] = 1;

        var bases = std.ArrayList(u6).init(allocator);
        defer bases.deinit();

        var do = false;
        while (true) {
            if (do and !increment(digits, max_base))
                break;
            do = true;

            const min_base: u6 = @max(2, maxElement(digits) + 1);
            if (most_bases > max_base - min_base + 1)
                continue;
            bases.clearRetainingCapacity();

            var b = min_base;
            while (b <= max_base) : (b += 1) {
                if (max_base - b + 1 + bases.items.len < most_bases)
                    break;
                var n: u64 = 0;
                for (digits) |d|
                    n = n * b + d;
                if (sieve.isPrime(n))
                    try bases.append(b);
            }
            if (bases.items.len > most_bases) {
                most_bases = @intCast(bases.items.len);
                for (max_strings.items) |pair|
                    pair.deinit(allocator);
                max_strings.clearRetainingCapacity();
            }
            if (bases.items.len == most_bases)
                try max_strings.append(try Pair.init(allocator, digits, bases.items));
        } // while (increment(digits, max_base));
        try writer.print("{}\n", .{most_bases});
        var buffer: [128]u8 = undefined;
        for (max_strings.items) |m|
            try writer.print("{s} -> {any}\n", .{ toString(&buffer, m.digits), m.bases });
        try writer.writeByte('\n');
    }
}

fn increment(digits: []u6, max_base: u6) bool {
    var i = digits.len;
    while (i != 0) {
        i -= 1;
        if (digits[i] + 1 != max_base) {
            digits[i] += 1;
            return true;
        }
        digits[i] = 0;
    }
    return false;
}

/// Return the maximum scalar in `list` (assumes
/// `list` is not empty)
fn maxElement(list: []const u6) u6 {
    var max = list[0];
    for (list[1..]) |i|
        if (i > max) {
            max = i;
        };
    return max;
}

fn toString(output: []u8, v: []const u6) []const u8 {
    const digits = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    const slice = output[0..v.len];
    for (slice, v) |*dest, i|
        dest.* = digits[i];
    return slice;
}

const Pair = struct {
    digits: []const u6,
    bases: []const u6,
    fn init(allocator: std.mem.Allocator, digits: []const u6, bases: []const u6) !Pair {
        return Pair{
            .digits = try allocator.dupe(u6, digits),
            .bases = try allocator.dupe(u6, bases),
        };
    }
    fn deinit(self: *const Pair, allocator: std.mem.Allocator) void {
        allocator.free(self.digits);
        allocator.free(self.bases);
    }
};

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

const testing = std.testing;
test PrimeSieve {
    const allocator = testing.allocator;
    const sieve = try PrimeSieve.init(allocator, try std.math.powi(u64, 36, 4));
    defer sieve.deinit(allocator);

    const primes_list = [_]u64{ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 1679609 };
    const composite_list = [_]u64{ 4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20, 21, 1679607 };

    try testing.expect(!sieve.isPrime(0));
    try testing.expect(!sieve.isPrime(1));

    for (primes_list) |prime|
        try testing.expect(sieve.isPrime(prime));
    for (composite_list) |composite|
        try testing.expect(!sieve.isPrime(composite));
}
