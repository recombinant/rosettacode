// https://rosettacode.org/wiki/Ascending_primes
// {{works with|Zig|0.16.0}}
// {{trans|Wren}}

// Using cpp primesieve from https://github.com/kimwalisch/primesieve/
// zig run Ascending_primes.zig -I ../primesieve-12.13/zig-out/include/ ../primesieve-12.13/zig-out/lib/primesieve.lib -lstdc++

const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const ps = @cImport({
    @cInclude("stdlib.h");
    @cInclude("primesieve.h");
});

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;
    const gpa: Allocator = init.gpa;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    var ascending: std.ArrayList(u32) = .empty;
    defer ascending.deinit(gpa);

    // Sieved candidates limited to 7 digits
    const start: u64 = 0;
    const stop: u64 = 3_456_789; // inclusive
    var size: usize = 0;

    const t0: Io.Timestamp = .now(io, .real);

    // Get an array with the primes inside [start, stop]
    const primes: [*]u32 = @ptrCast(@alignCast(ps.primesieve_generate_primes(start, stop, &size, ps.UINT32_PRIMES)));
    // Check for error in primesieve_generate_primes? (errno)
    defer ps.primesieve_free(primes);

    for (primes[0..size]) |p|
        if (isAscending(p))
            try ascending.append(gpa, p);

    // 8 & 9 digit candidates
    const candidates = [_]u32{
        12_345_678, 12_345_679, 12_345_689, 12_345_789, 12_346_789,
        12_356_789, 12_456_789, 13_456_789, 23_456_789, 123_456_789,
    };
    for (candidates) |cand|
        if (isPrime(cand))
            try ascending.append(gpa, cand);

    std.log.info("processed in {f}", .{t0.untilNow(io, .real)});

    try stdout.print("{any}\n\nThere are {d} ascending primes.\n", .{ ascending.items, ascending.items.len });
    try stdout.flush();
}

fn isAscending(n: anytype) bool {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("isAscending() expected unsigned integer argument, found " ++ @typeName(T));

    if (n < 10) return true;

    var lastDigit: T = n % 10;
    var remaining = n / 10;

    while (remaining > 0) {
        const currentDigit = remaining % 10;
        if (currentDigit >= lastDigit) return false;
        lastDigit = currentDigit;
        remaining /= 10;
    }
    return true;
}

fn isPrime(n: anytype) bool {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("isPrime() expected unsigned integer argument, found " ++ @typeName(T));

    if (n < 2) return false;

    inline for ([3]u3{ 2, 3, 5 }) |p| if (n % p == 0) return n == p;

    const wheel = comptime [_]u3{ 4, 2, 4, 2, 4, 6, 2, 6 };

    var p: T = 7;
    while (true)
        for (wheel) |w| {
            if (p * p > n) return true;
            if (n % p == 0) return false;
            p += w;
        };
}
