// https://rosettacode.org/wiki/Time_a_function
// {{works with|Zig|0.16.0}}
// {{trans|C}}
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    std.log.info("identity (4) takes {f}", .{try timeIt(io, identity, 4)});
    std.log.info("sum      (4) takes {f}", .{try timeIt(io, sum, 4)});
}

fn timeIt(io: Io, action: fn (u128) u128, arg: u128) !Io.Duration {
    var t0: Io.Timestamp = .now(io, .real);

    _ = action(arg);

    return t0.untilNow(io, .real);
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
