// https://rosettacode.org/wiki/M%C3%B6bius_function
// Based on C
const std = @import("std");
const math = std.math;
const mem = std.mem;

const MU_MAX = 1_000_000;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();

    var moebius = try Moebius.init(allocator, MU_MAX);
    defer moebius.deinit();

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
}

const Moebius = struct {
    allocator: mem.Allocator,
    mu: []i2,

    /// Compute Moebius function values via sieve.
    fn init(allocator: mem.Allocator, max: usize) !Moebius {
        // Type for calculations.
        const Calc = i32;
        // Temporary for calculations.
        var mu_calc = try allocator.alloc(Calc, max + 1);
        defer allocator.free(mu_calc);

        for (mu_calc) |*m| m.* = 1;

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
            const sqroot = math.sqrt(mu_calc.len) + 1;
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
        var mu = try allocator.alloc(i2, mu_calc.len);
        mu[0] = @truncate(math.sign(mu_calc[0])); // mu[0] not relevant.
        mu[1] = @truncate(math.sign(mu_calc[1]));

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

        return Moebius{
            .mu = mu,
            .allocator = allocator,
        };
    }

    fn deinit(self: *Moebius) void {
        self.allocator.free(self.mu);
    }

    fn function(self: *const Moebius, n: usize) i2 {
        return self.mu[n];
    }
};
