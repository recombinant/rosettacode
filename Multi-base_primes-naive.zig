// https://rosettacode.org/wiki/Multi-base_primes
// Using cpp primesieve from https://github.com/kimwalisch/primesieve/
const std = @import("std");
const ps = @cImport({
    @cInclude("primesieve.h");
});

const DIGITS = 4;
const MIN_BASE = 2;
const MAX_BASE = 36;

const BaseFlags = std.StaticBitSet(MAX_BASE + 1);
const Lookup = std.StringArrayHashMap(BaseFlags);

pub fn main() !void {
    var t0 = try std.time.Timer.start();

    const limit: u64 = try std.math.powi(u64, MAX_BASE, DIGITS);

    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const primes = try getPrimes(allocator, limit);
    defer allocator.free(primes);

    std.log.info("primes calculated after elapsed {}", .{std.fmt.fmtDuration(t0.read())});

    var characters_table = try CharactersTable.init(allocator, primes);
    defer characters_table.deinit();

    std.log.info("characters calculated after elapsed {}", .{std.fmt.fmtDuration(t0.read())});

    const writer = std.io.getStdOut().writer();

    var digits: u8 = 1;
    while (digits <= DIGITS) : (digits += 1) {
        const count, const numbers = try characters_table.max(allocator, digits);
        try writer.print("{}-character strings which are prime in most bases: {}\n", .{ digits, count });
        for (numbers) |number| {
            try writer.print(" {s} ->", .{number});
            var it = characters_table.characters[digits].getPtr(number).?.iterator(.{});
            while (it.next()) |base| {
                try writer.print(" {} ", .{base});
            }
            try writer.writeByte('\n');
        }
        try writer.writeByte('\n');
        allocator.free(numbers);
    }

    std.log.info("elapsed time {}", .{std.fmt.fmtDuration(t0.read())});
}

/// Return an array of prime numbers up to and including limit
fn getPrimes(allocator: std.mem.Allocator, limit: u64) ![]u64 {
    var prime_list = std.ArrayList(u64).init(allocator);
    defer prime_list.deinit();

    var it: ps.primesieve_iterator = undefined;
    ps.primesieve_init(&it);
    defer ps.primesieve_free_iterator(&it);

    while (true) {
        const p = ps.primesieve_next_prime(&it);
        if (it.is_error != 0 or p == ps.PRIMESIEVE_ERROR)
            return error.PrimesieveError;
        if (p >= limit) break;
        try prime_list.append(p);
    }
    return prime_list.toOwnedSlice();
}

const CharactersTable = struct {
    characters: [DIGITS + 1]Lookup,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, primes: []u64) !CharactersTable {
        var result = CharactersTable{
            .characters = undefined,
            .allocator = allocator,
        };
        for (&result.characters) |*lookup|
            lookup.* = Lookup.init(allocator);

        var buffer: [DIGITS + 1]u8 = undefined;
        var stream = std.io.fixedBufferStream(&buffer);
        const stream_writer = stream.writer();

        var base: u8 = MIN_BASE;
        while (base <= MAX_BASE) : (base += 1) {
            for (primes) |p| {
                // const s = toString(&buffer, p, base);
                stream.reset();
                try std.fmt.formatInt(p, base, .lower, .{}, stream_writer);
                const s = stream.getWritten();
                if (s.len > DIGITS)
                    break;
                const gop = try result.characters[s.len].getOrPut(s);
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
    fn deinit(self: *CharactersTable) void {
        for (&self.characters) |*lookup| {
            for (lookup.keys()) |s|
                self.allocator.free(s);
            lookup.deinit();
        }
    }
    fn max(self: *const CharactersTable, allocator: std.mem.Allocator, digits: u8) !struct { usize, []const []const u8 } {
        var max_count: usize = 0;
        var max_numbers = std.ArrayList([]const u8).init(allocator);
        defer max_numbers.deinit();
        var it = self.characters[digits].iterator();
        while (it.next()) |entry| {
            const count = entry.value_ptr.count();
            if (count < max_count)
                continue;
            if (count > max_count) {
                max_count = count;
                max_numbers.clearRetainingCapacity();
            }
            try max_numbers.append(entry.key_ptr.*);
        }
        return .{ max_count, try max_numbers.toOwnedSlice() };
    }
    /// Convert n_ to string in base. Faster than using
    /// Zig's std.fmt.formatInt()
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
