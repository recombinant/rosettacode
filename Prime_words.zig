// https://rosettacode.org/wiki/Prime_words
const std = @import("std");
const heap = std.heap;
const math = std.math;
const mem = std.mem;
const testing = std.testing;

pub fn main() !void {
    const text = @embedFile("data/unixdict.txt");

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // cache prime chars with codepoints between 33 and 255, say
    var prime_char_set = std.AutoArrayHashMap(u8, void).init(allocator);
    defer prime_char_set.deinit();
    for (33..256) |i| { // brute force, simple and it works
        const ch: u8 = @truncate(i);
        if (isPrime(ch))
            try prime_char_set.put(ch, {});
    }
    // array for prime words ------------------------------
    var prime_words = std.ArrayList([]const u8).init(allocator);
    // defer prime_words.deinit(); // see toOwnedSlice()

    // find prime words -----------------------------------
    var it = mem.splitScalar(u8, text, '\n');
    while (it.next()) |word| {
        if (word.len != 0)
            for (word) |ch| {
                if (!prime_char_set.contains(ch))
                    break;
            } else {
                try prime_words.append(word);
            };
    }
    // print prime words ----------------------------------
    const prime_word_slice = try prime_words.toOwnedSlice();
    defer allocator.free(prime_word_slice);

    try printWords(prime_word_slice);
}

fn isPrime(n: u32) bool {
    if (n < 2) return false;
    if (n % 2 == 0) return n == 2;
    if (n % 3 == 0) return n == 3;

    var d: u32 = 5;
    while (d * d <= n) {
        if (n % d == 0) return false;
        d += 2;
        if (n % d == 0) return false;
        d += 4;
    }
    return true;
}

fn printWords(words: []const []const u8) !void {
    // buffered stdout ------------------------------------
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    // ----------------------------------------------------
    try stdout.writeAll("Prime words in 'unixdict.txt' are:\n");

    for (words, 1..) |word, i| {
        try stdout.print("{d:2}: {s:<10}", .{ i, word });
        if (i % 4 == 0) try stdout.writeByte('\n');
    }

    // flush buffered stdout ------------------------------
    try bw.flush();
}

test "test isPrime" {
    const expect = testing.expect;

    try expect(!isPrime(0));
    try expect(!isPrime(1));
    try expect(isPrime(2));
    try expect(isPrime(3));
    try expect(!isPrime(4));
    try expect(isPrime(5));
    try expect(!isPrime(6));
    try expect(isPrime(7));
    try expect(!isPrime(8));
    try expect(!isPrime(9));
    try expect(!isPrime(10));
    try expect(isPrime(11));
    try expect(!isPrime(12));
    try expect(isPrime(997));

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const primes = try sieve(allocator, 1000);
    for (primes) |p|
        try expect(isPrime(p));
}

/// Return at least n prime numbers.
fn sieve(allocator: mem.Allocator, n: usize) ![]u32 {
    const float_n: f32 = @floatFromInt(n);
    const limit: usize = @intFromFloat(@log(float_n) * float_n * 1.2); // should be enough

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

    var primes = std.ArrayList(u32).init(allocator);
    try primes.ensureTotalCapacityPrecise(n + 1);

    // skip 0 & 1, they are not prime
    for (sieved[2..], 2..) |b, i|
        if (b) {
            try primes.append(@truncate(i));
            if (primes.items.len == n + 1)
                break;
        };

    return primes.toOwnedSlice();
}
