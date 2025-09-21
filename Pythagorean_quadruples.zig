// https://rosettacode.org/wiki/Pythagorean_quadruples
// {{works with|Zig|0.15.1}}

// from https://github.com/tiehuis/zig-rosetta
const std = @import("std");

const N = 2200;
const N2 = N * N * 2;

pub fn main() !void {
    var r: std.StaticBitSet(N + 1) = .initEmpty();

    // Educated guess for the amount of memory required for `ab` DynamicBitSet
    var buffer: [20 + (N2 + 1) / @sizeOf(usize)]u8 = undefined;
    var fba: std.heap.FixedBufferAllocator = .init(&buffer);
    const allocator = fba.allocator();

    // // 'ab' had a performance issue with Zig 0.14dev when using StaticBitSet
    // // so DynamicBitSet is used. DynamicBitSet is Ok for 'ab'
    // var ab: std.StaticBitSet(N2 + 1) = .initEmpty();
    var ab: std.DynamicBitSet = try .initEmpty(allocator, N2 + 1);

    var a: usize = 1;
    while (a <= N) : (a += 1) {
        const a2 = a * a;
        var b = a;
        while (b <= N) : (b += 1)
            ab.set(a2 + b * b);
    }

    var s: usize = 3;
    var c: usize = 1;
    while (c <= N) : (c += 1) {
        var s1 = s;
        s += 2;
        var s2 = s;
        var d = c + 1;
        while (d <= N) : (d += 1) {
            if (ab.isSet(s1))
                r.set(d);
            s1 += s2;
            s2 += 2;
        }
    }

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var d: usize = 1;
    while (d <= N) : (d += 1)
        if (!r.isSet(d)) {
            try stdout.print("{} ", .{d});
        };
    try stdout.writeByte('\n');

    try stdout.flush();
}
