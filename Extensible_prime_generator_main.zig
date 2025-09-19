// https://rosettacode.org/wiki/Extensible_prime_generator
// {{works with|Zig|0.15.1}}
// Copied from rosettacode

const std = @import("std");
// const sieve = @import("sieve.zig");
// const sieve = @import("Extensible_prime_generator.zig");
const sieve = @import("Extensible_prime_generator_alternate.zig");
const PrimeGen = sieve.PrimeGen;

pub fn main() !void {
    var t0: std.time.Timer = try .start();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try part1(stdout);
    try part2(stdout);
    try part3(stdout);

    try stdout.flush();

    std.log.info("processed in {D}", .{t0.read()});
}

// exercise 1: Print small primes
fn part1(w: *std.Io.Writer) !void {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var primes: PrimeGen(u8) = .init(allocator);
    defer primes.deinit();

    try w.writeAll("The first 20 primes:");
    while (try primes.next()) |p| {
        try w.print(" {}", .{p});
        if (primes.count == 20)
            break;
    }
    try w.writeAll("\nThe primes between 100 and 150:");
    while (try primes.next()) |p| if (p >= 100 and p <= 150)
        try w.print(" {}", .{p});
    try w.writeByte('\n');

    try w.flush();
}

// exercise 2: count medium primes
fn part2(w: *std.Io.Writer) !void {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var primes: PrimeGen(sieve.AutoSieveType(8000)) = .init(allocator);
    defer primes.deinit();

    const lower = 7700;
    const upper = 8000;

    var count: i32 = 0;
    while (try primes.next()) |p| {
        if (p > upper)
            break;
        if (p > lower)
            count += 1;
    }

    const max_chars = comptime maxDecimalCommatized();
    var buffer1: [max_chars]u8 = undefined;
    var buffer2: [max_chars]u8 = undefined;

    try w.print(
        "There are {} primes between {s} and {s}.\n",
        .{ count, try commatize(&buffer1, lower), try commatize(&buffer2, upper) },
    );
    try w.flush();
}

// exercise 3: find big primes
fn part3(w: *std.Io.Writer) !void {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var primes: PrimeGen(u32) = .init(allocator);
    defer primes.deinit();

    const max_chars = comptime maxDecimalCommatized();
    var buffer1: [max_chars]u8 = undefined;
    var buffer2: [max_chars]u8 = undefined;

    var c: u32 = 10;
    while (try primes.next()) |p| {
        if (primes.count == c) {
            try w.print(
                "The {s}th prime is {s}\n",
                .{ try commatize(&buffer1, c), try commatize(&buffer2, p) },
            );
            try w.flush();
            if (c == 100_000_000)
                break;
            c *= 10;
        }
    }
}

fn commatize(buffer: []u8, n: u64) ![]const u8 {
    // number as string without commas
    var buffer2: [maxDecimalChars(@TypeOf(n))]u8 = undefined;
    const size = std.fmt.printInt(&buffer2, n, 10, .lower, .{});
    const s = buffer2[0..size];
    //
    var w: std.Io.Writer = .fixed(buffer);

    // write number string as string with inserted commas
    const last = s.len - 1;
    for (s, 0..) |c, idx| {
        try w.writeByte(c);
        if (last - idx != 0 and (last - idx) % 3 == 0)
            try w.writeByte(',');
    }
    return w.buffered();
}

fn maxDecimalCommatized() usize {
    const T = u64; // @TypeOf(n) in commatize() above
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("type must be an unsigned integer.");
    return maxDecimalChars(T) + maxDecimalCommas(T);
}

/// Return the maximum number of characters in a string representing a decimal of type T.
fn maxDecimalChars(comptime T: type) usize {
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("type must be an unsigned integer.");
    const max_int: comptime_float = @floatFromInt(std.math.maxInt(T));
    return @intFromFloat(@log10(max_int) + 1);
}

/// Return the maximum number of commas in a 'commatized' string representing a decimal of type T.
fn maxDecimalCommas(comptime T: type) usize {
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("type must be an unsigned integer.");
    return (maxDecimalChars(T) - 1) / 3;
}

const testing = std.testing;

test part2 {
    var buffer: [200]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buffer);

    try part2(&w);

    const expected = "There are 30 primes between 7,700 and 8,000.\n";

    try testing.expectEqualStrings(expected, w.buffered());
}
