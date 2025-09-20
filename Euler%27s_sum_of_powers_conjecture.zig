// https://rosettacode.org/wiki/Euler%27s_sum_of_powers_conjecture
// {{works with|Zig|0.15.1}}
// {{trans|Python}}
const std = @import("std");

const max_n = 250;
const Number = u64;

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var pow5_to_n = std.AutoArrayHashMap(Number, usize).init(allocator);
    // defer pow5_to_n.deinit(); // not necessary with ArenaAllocator
    var pow5: [max_n]Number = undefined;

    // lookup table of number vs number⁵
    for (pow5[0..], 0..) |*e, i| {
        const n: Number = @intCast(i);
        e.* = try std.math.powi(Number, n, 5);
        try pow5_to_n.put(e.*, i);
    }

    // |power, index| pairs
    for (pow5[4..], 4..) |s0, x0|
        for (pow5[3..x0], 3..) |s1, x1|
            for (pow5[2..x1], 2..) |s2, x2|
                for (pow5[1..x2], 1..) |s3, x3| {
                    const pow_5_sum = s0 + s1 + s2 + s3;

                    const optional_y = pow5_to_n.get(pow_5_sum);
                    if (optional_y) |y| {
                        try stdout.print("{}⁵ + {}⁵ + {}⁵ + {}⁵ = {}⁵\n", .{ x3, x2, x1, x0, y });
                        try stdout.flush();
                        return;
                    }
                };

    try stdout.writeAll("Sorry, no solution found.\n");
    try stdout.flush();
}
