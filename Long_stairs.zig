// https://www.rosettacode.org/wiki/Long_stairs
// Translation of C
const std = @import("std");
const mem = std.mem;

pub fn main() !void {
    const number_of_tests = 10_000;
    // --------------------------------------------- stdout
    const stdout = std.io.getStdOut().writer();
    // --------------------- pseudo random number generator
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();
    // ----------------------------------------------------
    var secs_tot: u64 = 0;
    var steps_tot: u64 = 0; // keep track of time and steps over all the trials

    try stdout.writeAll("Seconds    steps behind    steps ahead\n");
    try stdout.writeAll("-------    ------------    -----------\n");
    for (0..number_of_tests) |trial| { // 10,000 attempts for the runner
        var sbeh: u64 = 0;
        var slen: u64 = 100;
        var secs: u64 = 0; // initialise this trial
        while (sbeh < slen) { // as long as the runner is still on the stairs
            sbeh += 1; // runner climbs a step
            for (0..5) |_| { // evil wizard conjures five new steps
                if (rand.intRangeLessThan(u64, 0, slen) < sbeh)
                    sbeh += 1; // maybe a new step is behind us
                slen += 1; // either way, the staircase is longer
            }
            secs += 1; // one second has passed
            if (trial == 0 and 599 < secs and secs < 610)
                try stdout.print(
                    "{d}        {d}            {d}\n",
                    .{ secs, sbeh, slen - sbeh },
                );
        }
        secs_tot += secs;
        steps_tot += slen;
    }
    try stdout.print(
        "Average secs taken: {d}\n",
        .{@as(f64, @floatFromInt(secs_tot)) / number_of_tests},
    );
    try stdout.print(
        "Average final length of staircase: {d}\n",
        .{@as(f64, @floatFromInt(steps_tot)) / number_of_tests},
    );
}
