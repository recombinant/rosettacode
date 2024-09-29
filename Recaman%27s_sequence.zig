// https://rosettacode.org/wiki/Recaman%27s_sequence
// Translated from C
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var used = std.AutoArrayHashMap(i64, void).init(allocator);
    var used1000 = std.AutoArrayHashMap(i64, void).init(allocator);
    defer used.deinit();
    defer used1000.deinit();

    var a = try allocator.alloc(i64, 400_000);
    defer allocator.free(a);
    a[0] = 0;

    try used.put(0, {});
    try used1000.put(0, {});

    var k: usize = 0;
    var n: usize = 1;
    var found_dup: bool = false;

    while (n <= 15 or !found_dup or k < 1001) : (n += 1) {
        var next = a[n - 1] - @as(i64, @intCast(n));
        if (next < 1 or used.contains(next))
            next += 2 * @as(i64, @intCast(n));

        const already_used = used.contains(next);
        a[n] = next;

        if (!already_used) {
            try used.put(next, {});
            if (next >= 0 and next <= 1000)
                try used1000.put(next, {});
        }

        if (n == 14) {
            try stdout.writeAll("The first 15 terms of the Recaman's sequence are: ");
            try stdout.writeAll("[");
            for (0..15) |i|
                try stdout.print("{d} ", .{a[i]});
            try stdout.writeAll("]\n");
        }

        if (!found_dup and already_used) {
            try stdout.print("The first duplicated term is a[{d}] = {d}\n", .{ n, next });
            found_dup = true;
        }

        k = used1000.count();
        if (k == 1001)
            try stdout.print("Terms up to a[{d}] are needed to generate 0 to 1000\n", .{n});
    }
}
