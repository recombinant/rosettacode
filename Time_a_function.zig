// https://rosettacode.org/wiki/Time_a_function
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

pub fn main() !void {
    std.log.info("identity (4) takes {D}", .{try timeIt(identity, 4)});
    std.log.info("sum      (4) takes {D}", .{try timeIt(sum, 4)});
}

fn timeIt(action: fn (u128) u128, arg: u128) !u64 {
    var t0: std.time.Timer = try .start();

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
