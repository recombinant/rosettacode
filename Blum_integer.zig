// https://rosettacode.org/wiki/Blum_integer
// Translation of C
// https://en.wikipedia.org/wiki/Magic_number_(programming)
const std = @import("std");
const io = std.io;
const testing = std.testing;
const assert = std.debug.assert;

// this is at file scope so that it can be tested
// without the 'pub' keyword it cannot be seen outside this file.
const digits = [4]u32{ 1, 3, 7, 9 };

pub fn main() !void {
    const stdout_file = io.getStdOut().writer();
    var bw = io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var blum: [50]u32 = undefined; // Only occurence of the magic value 50

    var bc: u32 = 0;
    var counts: [4]u32 = .{0} ** 4;

    var i: u32 = 1;
    while (true) : (i += if (i % 5 == 3) 4 else 2) {
        const p = firstPrimeFactor(i);
        if (p % 4 == 3) {
            const q = @divTrunc(i, p);
            if (q != p and q % 4 == 3 and isPrime(q)) {
                if (bc < comptime blum.len) blum[bc] = i;
                bc += 1;
                counts[i % 10 / 3] += 1; // from the C implementation

                if (bc == comptime blum.len) {
                    try stdout.print("First {d} Blum integers:\n", .{comptime blum.len});
                    for (&blum, 0..) |b, j| {
                        const ch: u8 = if ((j + 1) % 10 == 0) '\n' else ' ';
                        try stdout.print("{d:3}{c}", .{ b, ch });
                    }
                    try stdout.writeByte('\n');
                } else if (bc == 26_828 or bc % 100_000 == 0) {
                    try stdout.print("The {d:6}th Blum integer is: {d:7}\n", .{ bc, i });
                    if (bc == 400_000) {
                        try stdout.writeAll("\n% distribution of the first 400,000 Blum integers:\n");
                        for (counts, digits) |count, digit|
                            try stdout.print(
                                "  {d:6.3}% end in {d}\n",
                                .{ @as(f64, @floatFromInt(count)) / 4000, digit },
                            );
                        break;
                    }
                }
            }
        }
    }
    try bw.flush();
}

fn isPrime(n: u32) bool {
    if (n <= 3)
        return n > 1;
    if (n % 2 == 0 or n % 3 == 0)
        return false;

    var d: u32 = 5;
    while (d * d <= n) : (d += 6)
        if (n % d == 0 or n % (d + 2) == 0)
            return false;

    return true;
}

/// 2, 3, 5 prime test
/// Assumes n is odd.
fn firstPrimeFactor(n: u32) u32 {
    assert(n & 1 == 1);

    const inc = comptime [8]u32{ 4, 2, 4, 2, 4, 6, 2, 6 };

    if (n == 1) return 1;
    if (n % 3 == 0) return 3;
    if (n % 5 == 0) return 5;

    var k: u32 = 7;
    var i: u4 = 0;
    while (k * k <= n) {
        if (n % k == 0)
            return k
        else {
            k += inc[i];
            i = (i + 1) % 8;
        }
    }
    return n;
}

test "modulo logic for counts" {
    var bits = std.StaticBitSet(4).initEmpty();
    var i: u32 = 0;
    while (i < 10) : (i += 1) {
        const actual = i % 10 / 3; // this line is the logic under test
        const expected: u32 = switch (i % 10) {
            digits[0] => 0,
            digits[1] => 1,
            digits[2] => 2,
            digits[3] => 3,
            else => continue,
        };
        try testing.expectEqual(expected, actual);
        bits.set(actual);
    }
    // all four bits should be set
    try testing.expectEqual(4, bits.count());
}
