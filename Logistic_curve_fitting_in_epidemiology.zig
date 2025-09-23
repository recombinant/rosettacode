// https://rosettacode.org/wiki/Logistic_curve_fitting_in_epidemiology
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const r: f64 = solve(&f, .{});
    const R0: f64 = @exp(12 * r);

    try stdout.print("r = {d:.6}, R0 = {d:.5}\n", .{ r, R0 });

    try stdout.flush();
}

const K = 7_800_000_000;
const n0 = 27;
const actual: [97]f64 = [97]f64{
    27,     27,     27,     44,     44,      59,      59,      59,     59,
    59,     59,     59,     59,     60,      60,      61,      61,     66,
    83,     219,    239,    392,    534,     631,     897,     1350,   2023,
    2820,   4587,   6067,   7823,   9826,    11946,   14554,   17372,  20615,
    24522,  28273,  31491,  34933,  37552,   40540,   43105,   45177,  60328,
    64543,  67103,  69265,  71332,  73327,   75191,   75723,   76719,  77804,
    78812,  79339,  80132,  80995,  82101,   83365,   85203,   87024,  89068,
    90664,  93077,  95316,  98172,  102133,  105824,  109695,  114232, 118610,
    125497, 133852, 143227, 151367, 167418,  180096,  194836,  213150, 242364,
    271106, 305117, 338133, 377918, 416845,  468049,  527767,  591704, 656866,
    715353, 777796, 851308, 928436, 1000249, 1082054, 1174652,
};
fn f(r: f64) f64 {
    var sq: f64 = 0;
    for (0..actual.len) |i| {
        const eri: f64 = @exp(r * @as(f64, @floatFromInt(i)));
        const guess: f64 = (n0 * eri) / (1 + ((n0 * (eri - 1)) / K));
        const diff: f64 = guess - actual[i];
        sq += diff * diff;
    }
    return sq;
}

const SolveParams = struct {
    guess: f64 = 0.5,
    epsilon: f64 = 0,
};
fn solve(func: *const fn (f64) f64, params: SolveParams) f64 {
    var guess = params.guess;
    const epsilon = params.epsilon;
    var delta: f64 = if (guess == 0) 1 else guess;
    var f0: f64 = func(guess);
    var factor: f64 = 2;
    while (delta > epsilon and guess != guess - delta) : (delta *= factor) {
        var nf = func(guess - delta);
        if (nf < f0) {
            f0 = nf;
            guess -= delta;
        } else {
            nf = func(guess + delta);
            if (nf < f0) {
                f0 = nf;
                guess += delta;
            } else {
                factor = 0.5;
            }
        }
    }
    return guess;
}
