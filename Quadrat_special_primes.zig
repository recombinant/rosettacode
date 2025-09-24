// https://rosettacode.org/wiki/Quadrat_special_primes
// {{works with|Zig|0.15.1}}
// {{trans|Wren}}

// see also: https://rosettacode.org/wiki/Cubic_special_primes

// zig run Quadrat_special_primes.zig -I ../primesieve-12.9/zig-out/include/ ../primesieve-12.9/zig-out/lib/primesieve.lib -lstdc++
//   or
// zig test Quadrat_special_primes.zig
const std = @import("std");
const ps = @cImport({
    @cInclude("stdlib.h");
    @cInclude("primesieve.h");
});

pub fn main() error{WriteFailed}!void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const start: u64 = 0;
    const stop: u64 = 15_999;
    var size: usize = 0;

    // Get an array with the primes inside [start, stop] */
    var primes: [*]u32 = @ptrCast(@alignCast(ps.primesieve_generate_primes(start, stop, &size, ps.UINT32_PRIMES)));
    // Check for error in primesieve_generate_primes?
    defer ps.primesieve_free(primes);

    try stdout.writeAll("Quadrat special primes under 16,000:\n");
    try stdout.writeAll(" Prime1  Prime2    Gap  Sqrt\n");

    var lastQuadratSpecial: u32 = 3;
    var count: usize = 1;

    const fmt = "{d:7} {d:7} {d:6} {d:4}\n";
    try stdout.print(fmt, .{ 2, 3, 1, 1 });

    for (primes[2..size]) |p| {
        const gap = p - lastQuadratSpecial;

        if (isSquare(gap)) |sqrt| {
            try stdout.print(fmt, .{ lastQuadratSpecial, p, gap, sqrt });
            lastQuadratSpecial = p;
            count += 1;
        }
    }

    try stdout.print("\n{} such primes found.\n", .{count + 1});

    try stdout.flush();
}

fn isSquare(x: u32) ?u32 {
    const sqrt: u32 = @intFromFloat(@floor(@sqrt(@as(f32, @floatFromInt(x)))));
    return if (sqrt * sqrt == x) sqrt else null;
}

test isSquare {
    try std.testing.expectEqual(1, isSquare(1));
    try std.testing.expectEqual(2, isSquare(4));
    try std.testing.expectEqual(3, isSquare(9));
    try std.testing.expectEqual(4, isSquare(16));
    try std.testing.expectEqual(5, isSquare(25));
    try std.testing.expectEqual(6, isSquare(36));
    try std.testing.expectEqual(18, isSquare(324));
    try std.testing.expectEqual(null, isSquare(6));
    try std.testing.expectEqual(null, isSquare(26));
    try std.testing.expectEqual(null, isSquare(63));
    try std.testing.expectEqual(null, isSquare(124));
}
