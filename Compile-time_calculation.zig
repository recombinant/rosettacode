// https://rosettacode.org/wiki/Compile-time_calculation
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;
const print = std.debug.print;

fn factorialComptime(comptime n: comptime_int) comptime_int {
    return if (n != 0) n * factorialComptime(n - 1) else 1;
}

fn factorialRuntime(n: u64) comptime_int {
    return if (n != 0) n * factorialRuntime(n - 1) else 1;
}

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var timestamp: Io.Timestamp = undefined;
    var duration: Io.Duration = undefined;

    timestamp = .now(io, .real);
    const f2 = factorialRuntime(10);
    duration = timestamp.untilNow(io, .real);
    print("{}\n", .{f2});
    print("factorial 10 runtime processed in {f}\n\n", .{duration});

    timestamp = .now(io, .real);
    const f1 = factorialComptime(10);
    duration = timestamp.untilNow(io, .real);
    print("{}\n", .{f1});
    print("factorial 10 comptime processed in {f}\n\n", .{duration});

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

    timestamp = .now(io, .real);
    const answer1 = factorialComptime(1_000);
    duration = timestamp.untilNow(io, .real);
    print("comptime factorial 1,000 processed in {f}\n\n", .{duration});

    // Print processing is the cause of delay in the display of 'answer1'
    // Large numbers take time to print.
    timestamp = .now(io, .real);
    print("{}\n", .{answer1});
    duration = timestamp.untilNow(io, .real);
    print("comptime factorial 1,000  printing processed in {f}\n\n", .{duration});

    const answer2 = answer1 / divisor; // Smaller number will print faster.

    timestamp = .now(io, .real);
    print("{}\n", .{answer2});
    duration = timestamp.untilNow(io, .real);
    print("smaller number printing processed in {f}\n", .{duration});
}
