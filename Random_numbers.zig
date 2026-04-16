// https://rosettacode.org/wiki/Random_numbers
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;

const mean = 1.0;
const stddev = 0.5;
const n = 1000;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        Io.random(io, std.mem.asBytes(&seed));
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

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("mean {d:.4}, stddev {d:.4}\n", .{ cm, @sqrt(sq / (n - 1)) });

    try stdout.flush();
}
