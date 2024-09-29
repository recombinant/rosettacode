// https://rosettacode.org/wiki/Primorial_numbers
const std = @import("std");
const fmt = std.fmt;
const heap = std.heap;
const io = std.io;
const math = std.math;
const time = std.time;

const Int = std.math.big.int.Managed;

const AutoSieveType = @import("sieve.zig").AutoSieveType;
const PrimeGen = @import("sieve.zig").PrimeGen;

const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() !void {
    var t0 = try time.Timer.start();

    try part1();
    try part2v2();
    try part3(); // Slow

    print("processed in {}\n", .{fmt.fmtDuration(t0.read())});
}

/// Show the first ten primorial numbers   (0 ──► 9,   inclusive)
fn part1() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var primes = PrimeGen(u8).init(allocator);
    defer primes.deinit();

    var total: u64 = 1;
    var index: usize = 0;
    var buffer: [maxDecimalCommatized()]u8 = undefined;

    while (try primes.next()) |prime| : ({
        total *= prime;
        index += 1;
    }) {
        if (index == 10)
            break;
        print("Primorial({d}) = {s}\n", .{ index, try commatize(&buffer, total) });
    }
}

/// Part2 Show the length of primorial numbers whose indexes are:
///       10 100 1,000 10,000 and 100,000.
fn part2v1() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 1,299,709 is the 100,000th prime
    const T = AutoSieveType(1_288_709);
    var primes = PrimeGen(T).init(allocator);
    defer primes.deinit();

    var prime_ = try Int.initSet(allocator, 1);
    defer prime_.deinit();
    var total_ = try Int.initSet(allocator, 1);
    defer total_.deinit();
    var tmp_ = try Int.init(allocator);
    defer tmp_.deinit();

    var index: usize = 0;

    var buf1: [maxDecimalCommatized()]u8 = undefined;
    var buf2: [maxDecimalCommatized()]u8 = undefined;

    while (try primes.next()) |prime| : ({
        index += 1;
    }) {
        switch (index) {
            10,
            100,
            1_000,
            10_000,
            100_000,
            => {
                const total: []const u8 = try total_.toString(allocator, 10, .lower);
                print(
                    "Primorial({s}) = has {s} digits\n",
                    .{ try commatize(&buf1, index), try commatize(&buf2, total.len) },
                );
                allocator.free(total);

                if (index == 100_000)
                    break;
            },
            else => {},
        }
        try prime_.set(prime);
        tmp_.swap(&total_);
        try total_.mul(&prime_, &tmp_);
    }
}

/// Part2 Show the length of primorial numbers whose indexes are:
///       10 100 1,000 10,000 and 100,000.
/// Uses a translation of the Go example's vecprod() function.
/// part2v2() is faster than part2v1() as there are fewer big integer multiplications.
fn part2v2() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 1,299,709 is the 100,000th prime
    const T = AutoSieveType(1_288_709);
    var primes = PrimeGen(T).init(allocator);
    defer primes.deinit();

    const max_size: usize = comptime 100_000 - 10_000 + 1;
    var primes_array_buffer: [max_size * @sizeOf(Int)]u8 = undefined;
    var fba = heap.FixedBufferAllocator.init(&primes_array_buffer);
    const allocator2 = fba.allocator();

    var primes_array = try std.ArrayList(Int).initCapacity(allocator2, max_size);
    defer for (primes_array.items) |*item| item.deinit(); // should only be one Int remaining

    var one = try Int.initSet(allocator, 1);
    defer one.deinit();
    var index: usize = 0;

    var buf1: [maxDecimalCommatized()]u8 = undefined;
    var buf2: [maxDecimalCommatized()]u8 = undefined;

    while (try primes.next()) |prime| : ({
        index += 1;
    }) {
        switch (index) {
            10,
            100,
            1_000,
            10_000,
            100_000,
            => {
                const total_: Int = if (index == 0) one else try vecProd(&primes_array);
                assert(primes_array.items.len == 1 or index == 0);

                const total: []const u8 = try total_.toString(allocator, 10, .lower);
                print(
                    "Primorial({s}) = has {s} digits\n",
                    .{ try commatize(&buf1, index), try commatize(&buf2, total.len) },
                );
                allocator.free(total);

                if (index == 100_000)
                    break;
            },
            else => {},
        }
        try primes_array.append(try Int.initSet(allocator, prime));
    }
}

/// Show the length of the one millionth primorial number
fn part3() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const T = AutoSieveType(15_485_863); // 1,000,000th prime
    var primes = PrimeGen(T).init(allocator);
    defer primes.deinit();

    const primes_array = try allocator.alloc(Int, 1_000_000);
    defer allocator.free(primes_array);

    for (primes_array) |*p|
        p.* = try Int.initSet(allocator, (try primes.next()).?);

    // Use the vecprod from the Go example.
    var s = primes_array;
    var le = primes_array.len;
    while (le > 1) {
        for (0..le / 2) |i| {
            try s[i].mul(&s[i], &s[le - i - 1]);
            s[le - i - 1].deinit();
        }
        var c = le / 2;
        if (le & 1 == 1)
            c += 1;
        s = s[0..c];
        le = c;
        print("{} ", .{le});
    }
    print("\nfinished\n", .{});
    defer s[0].deinit();
    // TODO: use this string length code rather than the quick fix approximation
    // Zig 0.14dev toString() is extraordinarily slow compared to GNU GMP
    // SLOW // // print("writing string...\n", .{});
    // SLOW // const value = try s[0].toString(allocator, 10, .lower);
    // SLOW // defer allocator.free(value);
    // SLOW //
    // SLOW // var buffer1: [maxDecimalCommatized()]u8 = undefined;
    // SLOW // var buffer2: [maxDecimalCommatized()]u8 = undefined;
    // SLOW //
    // SLOW // print("Primorial({s}) = has {s} digits\n", .{ try commatize(&buffer1, primes_array.len), try commatize(&buffer2, value.len) });

    // Quick fix approximation for extraordinarily slow toString() compared to GNU GMP library's implementation
    // sizeInBaseUpperBound() is accurate to within about 10%
    const approx_length = s[0].sizeInBaseUpperBound(10);

    var buffer1: [maxDecimalCommatized()]u8 = undefined;
    var buffer2: [maxDecimalCommatized()]u8 = undefined;

    print("Primorial({s}) = has {s} digits (aproximately)\n", .{ try commatize(&buffer1, primes_array.len), try commatize(&buffer2, approx_length) });
}

/// Translation of the vecprod from the Go example.
/// Modifies `primes_array` in place leaving
/// the result as the single remaining Int in `primes_array`
/// All other Int values in `primes_array` will be deinit()
/// and `primes_array` shrunk to a list of 1 item.
fn vecProd(primes_array: *std.ArrayList(Int)) !Int {
    var s = primes_array.items;
    var le = s.len;
    while (le > 1) {
        for (0..le / 2) |i| {
            try s[i].mul(&s[i], &s[le - i - 1]);
            s[le - i - 1].deinit();
        }
        var c = le / 2;
        if (le & 1 == 1)
            c += 1;
        s = s[0..c];
        le = c;
    }
    primes_array.shrinkRetainingCapacity(1);
    return primes_array.items[0];
}

fn commatize(buffer: []u8, n: u64) ![]const u8 {
    // number as string without commas
    var buffer2: [maxDecimalChars(@TypeOf(n))]u8 = undefined;
    const size = fmt.formatIntBuf(&buffer2, n, 10, .lower, .{});
    const s = buffer2[0..size];
    //
    var stream = io.fixedBufferStream(buffer);
    const writer = stream.writer();

    // write number string as string with inserted commas
    const last = s.len - 1;
    for (s, 0..) |c, idx| {
        try writer.writeByte(c);
        if (last - idx != 0 and (last - idx) % 3 == 0)
            try writer.writeByte(',');
    }
    return stream.getWritten();
}

fn maxDecimalCommatized() usize {
    const T = u64; // @TypeOf(n) in commatize() above
    return maxDecimalChars(T) + maxDecimalCommas(T);
}

/// Return the maximum number of characters in a string representing a decimal of type T.
fn maxDecimalChars(comptime T: type) usize {
    if (@typeInfo(T) != .int and @typeInfo(T).int.bits != .unsigned)
        @compileError("type must be an unsigned integer.");
    const max_int: comptime_float = @floatFromInt(math.maxInt(T));
    return @intFromFloat(@log10(max_int) + 1);
}

/// Return the maximum number of commas in a 'commatized' string representing a decimal of type T.
fn maxDecimalCommas(comptime T: type) usize {
    if (@typeInfo(T) != .int and @typeInfo(T).int.bits != .unsigned)
        @compileError("type must be an unsigned integer.");
    return (maxDecimalChars(T) - 1) / 3;
}
