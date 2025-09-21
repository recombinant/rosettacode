// https://rosettacode.org/wiki/M%C3%B6bius_function
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

const MU_MAX = 1_000_000;

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const moebius: Moebius(MU_MAX) = .init();

    try stdout.writeAll("First 199 terms of the möbius function are as follows:\n    ");
    for (1..200) |i| {
        const m = moebius.function(i);
        if (m < 0)
            try stdout.print("{d:2}  ", .{m})
        else {
            // Zig: print a non-negative padded signed number
            //      without leading '+' sign by casting it to unsigned.
            const unsigned: u2 = @bitCast(m);
            try stdout.print("{d:2}  ", .{unsigned});
        }
        if ((i + 1) % 20 == 0) try stdout.writeByte('\n');
    }

    try stdout.flush();
}

fn Moebius(comptime max: usize) type {
    return struct {
        const Self = @This();
        mu: [max + 1]i2,

        /// Compute Moebius function values via sieve.
        fn init() Self {
            // Type for calculations.
            const Calc = i32;
            // Temporary for calculations.
            var mu_calc: [max + 1]Calc = undefined;
            for (&mu_calc) |*m| m.* = 1;

            // Calculations for 2 and 4 first.
            {
                var i: usize = 2;
                while (i < mu_calc.len) : (i += 4) mu_calc[i] = -2;
            }
            {
                var i: usize = 4;
                while (i < mu_calc.len) : (i += 4) mu_calc[i] = 0;
            }
            // Calculations for odd numbers.
            {
                const sqroot = std.math.sqrt(mu_calc.len) + 1;
                var i: usize = 3;
                var j: usize = undefined;
                while (i < sqroot) : (i += 2) {
                    if (mu_calc[i] == 1) {
                        const sq = i * i;
                        // for each factor found, swap + and -
                        j = i;
                        while (j < mu_calc.len) : (j += i) mu_calc[j] *= -@as(Calc, @intCast(i));
                        // square factor = 0
                        j = sq;
                        while (j < mu_calc.len) : (j += sq) mu_calc[j] = 0;
                    }
                }
            }
            // Calculations are now complete.

            // Set the actual Möbius number in two bit signed integers
            // based on the results of the calculations above.
            var mu: [mu_calc.len]i2 = undefined;
            mu[0] = @truncate(std.math.sign(mu_calc[0])); // mu[0] not relevant.
            mu[1] = @truncate(std.math.sign(mu_calc[1]));

            for (mu_calc[2..], mu[2..], 2..) |calc, *m, i| {
                m.* = if (calc == i)
                    1
                else if (calc == -@as(Calc, @intCast(i)))
                    -1
                else if (calc < 0)
                    1
                else if (calc > 0)
                    -1
                else
                    0;
            }
            return Self{ .mu = mu };
        }

        fn function(self: *const Self, n: usize) i2 {
            return self.mu[n];
        }
    };
}
