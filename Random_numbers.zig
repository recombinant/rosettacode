// https://rosettacode.org/wiki/Random_numbers
const std = @import("std");

const mean = 1.0;
const stddev = 0.5;
const n = 1000;

pub fn main() !void {
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random = prng.random();

    var numbers: [n]f64 = undefined;
    for (&numbers) |*e|
        e.* = random.floatNorm(f64) * stddev + mean;

    var s: f64 = 0;
    for (numbers) |e|
        s += e;

    const cm = s / n;
    var sq: f64 = 0;
    for (numbers) |e| {
        const d = e - cm;
        sq += d * d;
    }

    const writer = std.io.getStdOut().writer();
    try writer.print("mean {d:.4}, stddev {d:.4}\n", .{ cm, @sqrt(sq / (n - 1)) });
}
