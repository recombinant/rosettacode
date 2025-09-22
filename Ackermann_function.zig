// https://rosettacode.org/wiki/Ackermann_function
// {{works with|Zig|0.15.1}}
const std = @import("std");

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
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const m, const n = .{ 3, 9 };

    @setEvalBranchQuota(11_164_370);
    var t1: std.time.Timer = try .start();
    const a1 = comptime ackermann(m, n);
    try stdout.print("evaluated at comptime processed in {D} at runtime\n", .{t1.read()});
    try stdout.print("A({}, {}) = {}\n\n", .{ m, n, a1 });

    var t2: std.time.Timer = try .start();
    const a2 = ackermann(m, n);
    try stdout.print("runtime processed in {D}\n", .{t2.read()});
    try stdout.print("A({}, {}) = {}\n\n", .{ m, n, a2 });

    // The calculated number used above in @setEvalBranchQuota()
    try stdout.print("depth = {}\n", .{depth});

    try stdout.flush();
}
