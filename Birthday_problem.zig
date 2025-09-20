// https://rosettacode.org/wiki/Birthday_problem
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

pub fn main() !void {
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

    var bp: BirthdayProblem(.{}) = .init(random);
    var n: usize = 2;
    while (n <= 5) : (n += 1) {
        const result = bp.findHalfChance(n);
        try stdout.print(
            "{d} collision: {d} people, P = {d} +/- {d}\n",
            .{ n, result.np, result.p, result.d },
        );
        try stdout.flush();
    }
}

const BirthdayProblemOptions = struct {
    const Debug = enum { none, some, lots };

    debug: Debug = .none, // defaults to no debug printout
};

/// struct used as namespace for variables and functions that
/// were at global scope in the C original.
fn BirthdayProblem(comptime options: BirthdayProblemOptions) type {
    return struct {
        const Self = @This();
        const DAYS = 365;
        days: [DAYS]usize = undefined,
        random: std.Random,
        stderr: ?std.fs.File.Writer,

        fn init(random: std.Random) Self {
            return .{
                .random = random,
                .stderr = if (options.debug == .none) null else std.io.getStdErr().writer(),
            };
        }

        /// given p people, if n of them have same birthday in one run
        fn simulate1(self: *Self, p_: usize, n: usize) usize {
            var p = p_;
            @memset(&self.days, 0);
            while (p != 0) {
                p -= 1;
                const rand_day = self.random.intRangeLessThan(usize, 0, self.days.len);
                self.days[rand_day] += 1;
                if (self.days[rand_day] == n)
                    return 1;
            }
            return 0;
        }

        /// decide if the probability of n out of np people sharing a
        /// birthday is above or below p_thresh, with n_sigmas sigmas
        /// confidence note that if p_thresh is very low or hi, minimum
        /// runs need to be much higher
        fn prob(self: *Self, np: usize, n: usize, n_sigmas: f64, p_thresh: f64) struct { f64, f64 } {
            var p: f64 = undefined;
            var d: f64 = undefined;
            var runs: usize = 0;
            var yes: usize = 0;
            var printed = false;
            while (true) {
                yes += self.simulate1(np, n);
                runs += 1;
                p = @as(f64, @floatFromInt(yes)) / @as(f64, @floatFromInt(runs));
                d = std.math.sqrt((p * (1 - p)) / @as(f64, @floatFromInt(runs)));
                if (options.debug == .lots and yes % 50_000 == 0) {
                    self.stderr.?.print("\t\t{d}: {d} {d} {d} {d}        \r", .{ np, yes, runs, p, d }) catch unreachable;
                    printed = true;
                }
                // C do{}while() translated to Zig
                if (!((runs < 10) or (@abs(p - p_thresh) < (n_sigmas * d))))
                    break;
            }
            if (options.debug == .lots and printed)
                self.stderr.?.print("\n", .{}) catch unreachable;

            return .{ p, d };
        }

        /// bisect for truth
        fn findHalfChance(self: *Self, n: usize) struct { np: usize, p: f64, d: f64 } {
            var p: f64 = undefined;
            var dev: f64 = undefined;

            var mid: usize = undefined;

            reset: while (true) {
                var lo: usize = 0;
                var hi: usize = self.days.len * (n - 1) + 1;
                while (true) {
                    mid = (hi + lo) / 2;

                    // 5 sigma confidence. Conventionally people think 3 sigmas are good
                    // enough, but for case of 5 people sharing birthday, 3 sigmas actually
                    // sometimes give a slightly wrong answer
                    p, dev = self.prob(mid, n, 5, 0.5);

                    if (options.debug != .none)
                        self.stderr.?.print("\t{d} {d} {d} {d} {d}\n", .{ lo, mid, hi, p, dev }) catch unreachable;

                    if (p < 0.5)
                        lo = mid + 1
                    else
                        hi = mid;

                    if (hi < lo) {
                        // this happens when previous precisions were too low;
                        // easiest fix: reset
                        if (options.debug != .none)
                            self.stderr.?.print("\tMade a mess, will redo.", .{}) catch unreachable;
                        continue :reset;
                    }
                    // C do{}while() translated to Zig
                    if (!(lo < mid or p < 0.5))
                        break :reset;
                }
            }
            return .{ .np = mid, .p = p, .d = dev };
        }
    };
}
