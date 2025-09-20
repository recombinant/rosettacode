// https://rosettacode.org/wiki/Benford%27s_law
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

pub fn main() !void {
    const data = @embedFile("data/the_first_1001_fibonacci_numbers.txt");

    const actual = getActualDistribution(data);
    const benford = getBenfordDistribution();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll("First 1000 Fibonacci numbers:\n");
    try stdout.writeAll("Digit  Observed  Predicted\n");

    for (actual, benford, 1..) |a, b, i|
        try stdout.print("  {d}      {d:.3}     {d:.3}\n", .{ i, a, b });

    try stdout.flush();
}

fn getActualDistribution(text: []const u8) [9]f64 {
    var tally = std.mem.zeroes([9]f64);

    var it = std.mem.tokenizeScalar(u8, text, '\n');
    while (it.next()) |line|
        switch (line[0]) {
            '1'...'9' => |c| tally[c - '1'] += 1,
            else => {},
        };
    const total = blk: {
        var total: f64 = 0;
        for (tally) |t|
            total += t;
        break :blk total;
    };

    var freq: [9]f64 = undefined;
    for (&freq, tally) |*f, t|
        f.* = t / total;
    return freq;
}

fn getBenfordDistribution() [9]f64 {
    var prob: [9]f64 = undefined;
    for (&prob, 1..) |*p, i|
        p.* = @log10(1 + 1.0 / @as(f64, @floatFromInt(i)));
    return prob;
}
