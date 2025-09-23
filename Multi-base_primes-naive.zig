// https://rosettacode.org/wiki/Multi-base_primes
// {{works with|Zig|0.15.1}}

// Using cpp primesieve from https://github.com/kimwalisch/primesieve/
// zig run Multi-base_primes-naive.zig -I ../primesieve-12.9/zig-out/include/ ../primesieve-12.9/zig-out/lib/primesieve.lib -lstdc++

const std = @import("std");
const ps = @cImport({
    @cInclude("primesieve.h");
});

const DIGITS = 5;
const MIN_BASE = 2;
const MAX_BASE = 36;

const BaseFlags = std.StaticBitSet(MAX_BASE + 1);
const Lookup = std.StringArrayHashMapUnmanaged(BaseFlags);

pub fn main() !void {
    var t0: std.time.Timer = try .start();

    const limit: u64 = try std.math.powi(u64, MAX_BASE, DIGITS);

    // ArenaAllocator is faster but DebugAllocator checks for leaks.
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const primes = try getPrimes(allocator, limit);
    defer allocator.free(primes);

    std.log.info("primes calculated after elapsed {D}", .{t0.read()});

    var characters_table: CharactersTable = try .init(allocator, primes);
    defer characters_table.deinit(allocator);

    std.log.info("characters calculated after elapsed {D}", .{t0.read()});

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var digits: u8 = 1;
    while (digits <= DIGITS) : (digits += 1) {
        const count, const numbers = try characters_table.max(allocator, digits);
        try stdout.print("{}-character strings which are prime in most bases: {}\n", .{ digits, count });
        for (numbers) |number| {
            try stdout.print(" {s} ->", .{number});
            var it = characters_table.characters[digits].getPtr(number).?.iterator(.{});
            while (it.next()) |base| {
                try stdout.print(" {} ", .{base});
            }
            try stdout.writeByte('\n');
        }
        try stdout.writeByte('\n');
        try stdout.flush();
        allocator.free(numbers);
    }

    std.log.info("elapsed time {D}", .{t0.read()});
    std.log.warn("DebugAllocator.deinit() is now checking for leaks (slow)", .{});
}

/// Return an array of prime numbers up to and including limit
fn getPrimes(allocator: std.mem.Allocator, limit: u64) ![]u64 {
    var prime_list: std.ArrayList(u64) = .empty;
    defer prime_list.deinit(allocator);

    var it: ps.primesieve_iterator = undefined;
    ps.primesieve_init(&it);
    defer ps.primesieve_free_iterator(&it);

    while (true) {
        const p = ps.primesieve_next_prime(&it);
        if (it.is_error != 0 or p == ps.PRIMESIEVE_ERROR)
            return error.PrimesieveError;
        if (p >= limit) break;
        try prime_list.append(allocator, p);
    }
    return prime_list.toOwnedSlice(allocator);
}

const CharactersTable = struct {
    characters: [DIGITS + 1]Lookup,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, primes: []u64) !CharactersTable {
        var result: CharactersTable = .{
            .characters = undefined,
            .allocator = allocator,
        };
        for (&result.characters) |*lookup|
            lookup.* = .empty;

        var buffer: [DIGITS + 1]u8 = undefined;

        var base: u8 = MIN_BASE;
        while (base <= MAX_BASE) : (base += 1) {
            for (primes) |p| {
                // const s = toString(&buffer, p, base);
                // const len = s.len;
                const len = std.fmt.printInt(&buffer, p, base, .lower, .{});
                const s = buffer[0..len];

                if (len > DIGITS)
                    break;
                const gop = try result.characters[len].getOrPut(allocator, s);
                if (gop.found_existing)
                    gop.value_ptr.set(base)
                else {
                    gop.key_ptr.* = try allocator.dupe(u8, s);
                    gop.value_ptr.* = BaseFlags.initEmpty();
                    gop.value_ptr.set(base);
                }
            }
        }
        return result;
    }
    fn deinit(self: *CharactersTable, allocator: std.mem.Allocator) void {
        for (&self.characters) |*lookup| {
            for (lookup.keys()) |s|
                self.allocator.free(s);
            lookup.deinit(allocator);
        }
    }
    fn max(self: *const CharactersTable, allocator: std.mem.Allocator, digits: u8) !struct { usize, []const []const u8 } {
        var max_count: usize = 0;
        var max_numbers: std.ArrayList([]const u8) = .empty;
        defer max_numbers.deinit(allocator);
        var it = self.characters[digits].iterator();
        while (it.next()) |entry| {
            const count = entry.value_ptr.count();
            if (count < max_count)
                continue;
            if (count > max_count) {
                max_count = count;
                max_numbers.clearRetainingCapacity();
            }
            try max_numbers.append(allocator, entry.key_ptr.*);
        }
        return .{ max_count, try max_numbers.toOwnedSlice(allocator) };
    }
    /// Convert n_ to string in base. Slightly faster than using
    /// Zig's std.fmt.printInt()
    fn toString(output: []u8, n_: u64, base: u8) []u8 {
        const digits = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
        var n = n_;
        var i: usize = 0;
        while (n != 0) : (i += 1) {
            output[i] = digits[n % base];
            n /= base;
        }
        const result = output[0..i];
        std.mem.reverse(u8, result);
        return result;
    }
};
