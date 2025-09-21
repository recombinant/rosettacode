// https://rosettacode.org/wiki/Evolutionary_algorithm
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

// ASCII characters
const table = "ABCDEFGHIJKLMNOPQRSTUVWXYZ ";

const MUTATE = 15;
const COPIES = 30;

pub fn main() !void {
    const target = "METHINKS IT IS LIKE A WEASEL";

    // -------------------------------------------- random number
    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const random = prng.random();
    // ----------------------------------------------------------
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ----------------------------------------------------------
    var specimens: [COPIES][target.len]u8 = undefined;
    // initial random string (specimens[0])
    for (0..target.len) |i|
        specimens[0][i] = table[random.intRangeLessThan(usize, 0, table.len)];

    var iteration_count: usize = 0;
    while (true) {
        for (specimens[1..]) |*specimen|
            mutate(random, &specimens[0], specimen);

        var best: usize = 0;
        var best_i: usize = 0;
        // find best fitting string
        for (&specimens, 0..) |*specimen, i| {
            const unfit = unfitness(target, specimen);
            if (unfit < best or i == 0) {
                best = unfit;
                best_i = i;
            }
        }
        if (best_i != 0)
            @memcpy(&specimens[0], &specimens[best_i]);
        iteration_count += 1;
        try stdout.print("iter {}, score {}: {s}\n", .{ iteration_count, best, specimens[0] });

        if (best == 0)
            break;
    }
    try stdout.flush();
}

/// number of different chars between 'a' and 'b'
fn unfitness(a: []const u8, b: []const u8) usize {
    var sum: usize = 0;
    for (a, b) |ch_a, ch_b|
        sum += @intFromBool(ch_a != ch_b);
    return sum;
}

/// each char of 'b' has 1/MUTATE chance of differing from 'a'
fn mutate(random: std.Random, a: []const u8, b: []u8) void {
    @memcpy(b, a);
    for (b) |*ch_b|
        if (random.intRangeLessThan(usize, 0, MUTATE) == 0) {
            ch_b.* = table[random.intRangeLessThan(usize, 0, table.len)];
        };
}
