// https://rosettacode.org/wiki/Time_a_function
// Translation of C
const std = @import("std");
const fmt = std.fmt;
const time = std.time;
const print = std.debug.print;

pub fn main() !void {
    print("identity (4) takes {d} s\n", .{fmt.fmtDuration(try timeIt(identity, 4))});
    print("sum      (4) takes {d} s\n", .{fmt.fmtDuration(try timeIt(sum, 4))});
}

fn timeIt(action: fn (u128) u128, arg: u128) !u64 {
    var t0 = try time.Timer.start();

    _ = action(arg);

    return t0.read();
}

fn identity(s: u128) u128 {
    return s;
}

fn sum(s_: u128) u128 {
    var s = s_;
    var i: u128 = 0;
    while (i < 1_000_000) : (i += 1)
        s += i;
    return i;
}
