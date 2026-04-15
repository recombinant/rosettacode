// https://rosettacode.org/wiki/Ackermann_function
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;

// global variable not available at comptime
var depth: usize = 0;

fn ackermann(m: u64, n: u64) u64 {
    if (!@inComptime())
        depth += 1;

    if (m == 0) return n + 1;
    if (n == 0) return ackermann(m - 1, 1);
    return ackermann(m - 1, ackermann(m, n - 1));
}

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    const m, const n = .{ 3, 9 };

    @setEvalBranchQuota(11_164_370);
    const t0: Io.Timestamp = .now(io, .real);
    const a1 = comptime ackermann(m, n);
    try stdout.print("evaluated at comptime processed in {f} at runtime\n", .{t0.untilNow(io, .real)});
    try stdout.print("A({}, {}) = {}\n\n", .{ m, n, a1 });

    const t1: Io.Timestamp = .now(io, .real);
    const a2 = ackermann(m, n);
    try stdout.print("runtime processed in {f}\n", .{t1.untilNow(io, .real)});
    try stdout.print("A({}, {}) = {}\n\n", .{ m, n, a2 });

    // The calculated number used above in @setEvalBranchQuota()
    try stdout.print("depth = {}\n", .{depth});

    try stdout.flush();
}
