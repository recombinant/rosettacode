// https://rosettacode.org/wiki/Cyclops_numbers
// {{works with|Zig|0.15.1}}
// {{trans|C++}}

// Using a prime sieve generator is slower than than using the
// slightly optimised CyclopsIterator. Improvements to the latter
// would improve speed.

const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var t0: std.time.Timer = try .start();
    // --------------
    const limit = 50;
    const limit_stretch = 10_000_000;
    // --------------
    print("First {} cyclops numbers:\n", .{limit});
    var it0: CyclopsIterator = .init();
    for (0..limit) |count|
        printCyclops(count, limit, it0.next()[0]);

    var cyclops_number: u64 = 0;
    var cyclops_count: u64 = undefined;
    while (cyclops_number < limit_stretch) cyclops_number, cyclops_count = it0.next();
    print("First cyclops after {} is {} at 1 based index {}\n\n", .{ limit_stretch, cyclops_number, cyclops_count });
    // ------------
    print("First {} prime cyclops numbers:\n\n", .{limit});
    var it1: PrimeCyclopsIterator = .init();
    for (0..limit) |count|
        printCyclops(count, limit, it1.next()[0]);

    cyclops_number = 0;
    while (cyclops_number < limit_stretch) cyclops_number, cyclops_count = it1.next();
    print("First prime cyclops after {} is {} at 1 based index {}\n\n", .{ limit_stretch, cyclops_number, cyclops_count });
    // ------------
    print("First {} blind prime cyclops numbers:\n", .{limit});
    var it2: BlindPrimeCyclopsIterator = .init();
    for (0..limit) |count|
        printCyclops(count, limit, it2.next()[0]);

    cyclops_number = 0;
    while (cyclops_number < limit_stretch) cyclops_number, cyclops_count = it2.next();
    print("First blind prime cyclops after {} is {} at 1 based index {}\n\n", .{ limit_stretch, cyclops_number, cyclops_count });
    // ------------
    print("First {} palindromic prime cyclops numbers:\n", .{limit});
    var it3: PalindromicPrimeCyclopsIterator = .init();
    for (0..limit) |count|
        printCyclops(count, limit, it3.next()[0]);

    cyclops_number = 0;
    while (cyclops_number < limit_stretch) cyclops_number, cyclops_count = it3.next();
    print("First palindromic prime cyclops after {} is {} at 1 based index {}\n\n", .{ limit_stretch, cyclops_number, cyclops_count });
    print("Processed in {D}\n", .{t0.read()});
}

fn printCyclops(count: usize, limit: usize, n: u64) void {
    const sep: []const u8 = if (count % 10 != 0) " " else if (count != 0) "\n" else "";
    print("{s}{d:8}", .{ sep, n });

    if (count == limit - 1 and count % 10 != 0)
        print("\n", .{});
}

const CyclopsIterator = struct {
    next_candidate: u64,
    count: usize,

    fn init() CyclopsIterator {
        return CyclopsIterator{
            .next_candidate = 0,
            .count = 0,
        };
    }

    fn next(self: *CyclopsIterator) struct { u64, usize } {
        var candidate = self.next_candidate;

        while (!isCyclopsNumber(candidate)) {
            const n_digits: u64 = std.math.log10_int(candidate) + 1;
            if (n_digits % 2 == 0) {
                // candidate to the next odd number of digits cyclops.
                candidate = 0;
                const centre = n_digits / 2;
                var one: u64 = 1;
                // odd number of digits
                // zero center and ones either side
                for (0..n_digits + 1) |i| {
                    if (i != centre)
                        candidate += one;
                    one *= 10;
                }
            } else {
                candidate += 1;
            }
        }
        self.next_candidate = candidate + 1;
        self.count += 1;
        return .{ candidate, self.count };
    }
};

const PrimeCyclopsIterator = struct {
    it: CyclopsIterator,
    count: usize,

    fn init() PrimeCyclopsIterator {
        return PrimeCyclopsIterator{
            .count = 0,
            .it = .init(),
        };
    }

    fn next(self: *PrimeCyclopsIterator) struct { u64, usize } {
        while (true) {
            const p, _ = self.it.next();
            if (isPrime(p)) {
                self.count += 1;
                return .{ p, self.count };
            }
        }
    }
};

const BlindPrimeCyclopsIterator = struct {
    it: PrimeCyclopsIterator,
    count: usize,

    fn init() BlindPrimeCyclopsIterator {
        return BlindPrimeCyclopsIterator{
            .count = 0,
            .it = .init(),
        };
    }

    fn next(self: *BlindPrimeCyclopsIterator) struct { u64, usize } {
        while (true) {
            const p, _ = self.it.next();
            if (isPrime(blindCyclops(p))) {
                self.count += 1;
                return .{ p, self.count };
            }
        }
    }
};

const PalindromicPrimeCyclopsIterator = struct {
    it: PrimeCyclopsIterator,
    count: usize,

    fn init() PalindromicPrimeCyclopsIterator {
        return PalindromicPrimeCyclopsIterator{
            .count = 0,
            .it = .init(),
        };
    }

    fn next(self: *PalindromicPrimeCyclopsIterator) struct { u64, usize } {
        while (true) {
            const p, _ = self.it.next();
            if (isPalindrome(p)) {
                self.count += 1;
                return .{ p, self.count };
            }
        }
    }
};

fn isCyclopsNumber(n_: u64) bool {
    if (n_ == 0)
        return true;

    const n_digits: u64 = std.math.log10_int(n_) + 1;
    if (n_digits % 2 == 0)
        return false;

    var n = n_;
    var m = n % 10;
    var count: usize = 0;
    while (m != 0) {
        count += 1;
        n /= 10;
        m = n % 10;
    }
    n /= 10;
    m = n % 10;
    while (m != 0) {
        count -%= 1;
        n /= 10;
        m = n % 10;
    }
    return n == 0 and count == 0;
}

fn isPrime(n: u64) bool {
    if (n < 2) return false;
    if (n % 2 == 0) return n == 2;
    if (n % 3 == 0) return n == 3;
    var d: u64 = 5;
    while (d * d <= n) {
        if (n % d == 0) return false;
        d += 2;
        if (n % d == 0) return false;
        d += 4;
    }
    return true;
}

fn isPalindrome(n: u64) bool {
    var k: u64 = 0;
    var l = n;
    while (l != 0) {
        const m = l % 10;
        k = 10 * k + m;
        l /= 10;
    }
    return n == k;
}

/// Blind the given cyclops number (ie. remove the central 0).
fn blindCyclops(n_: u64) u64 {
    var n = n_;
    var m = n % 10;
    var k: u64 = 0;
    while (m != 0) {
        k = 10 * k + m;
        n /= 10;
        m = n % 10;
    }
    n /= 10;
    while (k != 0) {
        m = k % 10;
        n = 10 * n + m;
        k /= 10;
    }
    return n;
}

const testing = std.testing;

test blindCyclops {
    try testing.expectEqual(11, blindCyclops(101));
    try testing.expectEqual(1233, blindCyclops(12033));
}

test isPalindrome {
    try testing.expect(isPalindrome(101));
    try testing.expect(isPalindrome(22022));
    try testing.expect(!isPalindrome(22033));
    // not necessarily cyclops, but definitely palindrome
    try testing.expect(isPalindrome(22522));
}
