// https://rosettacode.org/wiki/Compile-time_calculation
const std = @import("std");
const fmt = std.fmt;
const math = std.math;
const time = std.time;
const print = std.debug.print;

fn factorialComptime(comptime n: comptime_int) comptime_int {
    return if (n != 0) n * factorialComptime(n - 1) else 1;
}

fn factorialRuntime(n: u64) comptime_int {
    return if (n != 0) n * factorialRuntime(n - 1) else 1;
}

pub fn main() !void {
    var t = try time.Timer.start();
    const f2 = factorialRuntime(10);
    const t2 = t.read();
    print("{}\n", .{f2});
    print("factorial 10 runtime processed in {}\n\n", .{fmt.fmtDuration(t2)});

    t = try time.Timer.start();
    const f1 = factorialComptime(10);
    const t1 = t.read();
    print("{}\n", .{f1});
    print("factorial 10 comptime processed in {}\n\n", .{fmt.fmtDuration(t1)});

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

    t = try time.Timer.start();
    const answer1 = factorialComptime(1_000);
    const t3 = t.read();
    print("comptime factorial 1,000 processed in {}\n\n", .{fmt.fmtDuration(t3)});

    // Print processing is the cause of delay in the display of 'answer1'
    // Large numbers take time to print.
    t = try time.Timer.start();
    print("{}\n", .{answer1});
    const t4 = t.read();
    print("comptime factorial 1,000  printing processed in {}\n\n", .{fmt.fmtDuration(t4)});

    const answer2 = answer1 / divisor; // Smaller number will print faster.

    t = try time.Timer.start();
    print("{}\n", .{answer2});
    const t5 = t.read();
    print("smaller number printing processed in {}\n", .{fmt.fmtDuration(t5)});
}
