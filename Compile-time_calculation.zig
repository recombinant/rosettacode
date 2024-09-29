// https://rosettacode.org/wiki/Compile-time_calculation
// from https://github.com/tiehuis/zig-rosetta
const std = @import("std");
const math = std.math;
const print = std.debug.print;

fn factorial(comptime n: comptime_int) comptime_int {
    return if (n != 0) n * factorial(n - 1) else 1;
}

pub fn main() void {
    print("{}\n\n", .{factorial(10)});

    const divisor: comptime_int = blk: {
        comptime var n: comptime_int = 10;
        comptime var limit: u16 = 0;
        inline while (limit != 11) : (limit += 1)
            n *= n;
        break :blk n;
    };

    // comptime_int is arbitrary precision and comptime functions are
    // cached so the recursive 'factorial' solution provided above is fast.
    // The comptime evaluation limit is low so needs to be explicitly
    // raised for this to be given enough cycles to run.
    @setEvalBranchQuota(10_000);
    const answer1 = factorial(1_000);
    const answer2 = answer1 / divisor; // Smaller number will print faster.
    print("{}\n\n", .{answer2});
    // Print processing is the cause of delay in the display of 'answer1'
    // Large numbers take time to print.
    print("{}\n", .{answer1});
}
