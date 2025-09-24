// https://rosettacode.org/wiki/Cubic_special_primes
// {{works with|Zig|0.15.1}}
// {{trans|Wren}}

// see also: https://rosettacode.org/wiki/Quadrat_special_primes

// zig run Cubic_special_primes.zig -I ../primesieve-12.9/zig-out/include/ ../primesieve-12.9/zig-out/lib/primesieve.lib -lstdc++
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
    const stop: u64 = 15_000;
    var size: usize = 0;

    // Get an array with the primes inside [start, stop] */
    var primes: [*]u32 = @ptrCast(@alignCast(ps.primesieve_generate_primes(start, stop, &size, ps.UINT32_PRIMES)));
    // Check for error in primesieve_generate_primes?
    defer ps.primesieve_free(primes);

    try stdout.writeAll("Cubic special primes under 15,000:\n");
    try stdout.writeAll(" Prime1  Prime2    Gap  Cbrt\n");

    var lastCubicSpecial: u32 = 3;
    var count: usize = 1;

    const fmt = "{d:7} {d:7} {d:6} {d:4}\n";
    try stdout.print(fmt, .{ 2, 3, 1, 1 });

    for (primes[2..size]) |p| {
        const gap = p - lastCubicSpecial;

        if (isCube(gap)) |cbrt| {
            try stdout.print(fmt, .{ lastCubicSpecial, p, gap, cbrt });
            lastCubicSpecial = p;
            count += 1;
        }
    }

    try stdout.print("\n{d} such primes found.\n", .{count + 1});

    try stdout.flush();
}

fn isCube(x: u32) ?u32 {
    const cbrt: u32 = @intFromFloat(@floor(std.math.cbrt(@as(f32, @floatFromInt(x)))));
    return if (cbrt * cbrt * cbrt == x) cbrt else null;
}

test isCube {
    try std.testing.expectEqual(1, isCube(1));
    try std.testing.expectEqual(2, isCube(8));
    try std.testing.expectEqual(3, isCube(27));
    try std.testing.expectEqual(4, isCube(64));
    try std.testing.expectEqual(5, isCube(125));
    try std.testing.expectEqual(6, isCube(216));
    try std.testing.expectEqual(18, isCube(5832));
    try std.testing.expectEqual(null, isCube(6));
    try std.testing.expectEqual(null, isCube(26));
    try std.testing.expectEqual(null, isCube(63));
    try std.testing.expectEqual(null, isCube(124));
}
