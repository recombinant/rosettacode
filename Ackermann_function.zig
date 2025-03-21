// https://rosettacode.org/wiki/Ackermann_function

// global variable not available at comptime
var depth: usize = 0;

fn ackermann(m: u64, n: u64) u64 {
    if (!@inComptime())
        depth += 1;

    if (m == 0) return n + 1;
    if (n == 0) return ackermann(m - 1, 1);
    return ackermann(m - 1, ackermann(m, n - 1));
}

pub fn main() !void {
    const m, const n = .{ 3, 9 };

    @setEvalBranchQuota(11_164_370);
    var t1: time.Timer = try .start();
    const a1 = comptime ackermann(m, n);
    print("comptime processed in {}\n", .{fmt.fmtDuration(t1.read())});
    print("A({}, {}) = {}\n\n", .{ m, n, a1 });

    var t2: time.Timer = try .start();
    const a2 = ackermann(m, n);
    print("runtime processed in {}\n", .{fmt.fmtDuration(t2.read())});
    print("A({}, {}) = {}\n\n", .{ m, n, a2 });

    // The calculated number used above in @setEvalBranchQuota()
    print("depth = {}\n", .{depth});
}

const std = @import("std");
const fmt = std.fmt;
const time = std.time;
const print = std.debug.print;
