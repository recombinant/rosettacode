// https://rosettacode.org/wiki/Recaman%27s_sequence
// Translation of Go
const std = @import("std");

pub fn main() !void {
    const writer = std.io.getStdOut().writer();

    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // arraylist can be initialised with capacity as the answers are known...
    var a = try std.ArrayList(isize).initCapacity(allocator, 400_000);
    defer a.deinit();

    var used = std.AutoHashMap(isize, void).init(allocator);
    defer used.deinit();
    try used.ensureTotalCapacity(1001);

    var used1000 = std.AutoHashMap(isize, void).init(allocator);
    defer used1000.deinit();
    try used1000.ensureTotalCapacity(1001);

    try a.append(0);
    try used.put(0, {});
    try used1000.put(0, {});

    var n: usize = 1;
    var found_dup = false;

    while (n <= 15 or !found_dup or used1000.count() < 1001) : (n += 1) {
        var next = a.items[n - 1] - @as(isize, @intCast(n));
        if (next < 1 or used.contains(next))
            next += 2 * @as(isize, @intCast(n));

        const already_used = used.contains(next);
        try a.append(next);
        if (!already_used) {
            try used.put(next, {});
            if (next <= 1000)
                try used1000.put(next, {});
        }

        if (n == 14)
            try writer.print("The first 15 terms of the Recaman's sequence are: {any}\n", .{a.items});

        if (!found_dup and already_used) {
            try writer.print("The first duplicated term is a[{d}] = {d}\n", .{ n, next });
            found_dup = true;
        }

        if (used1000.count() == 1001)
            try writer.print("Terms up to a[{d}] are needed to generate 0 to 1000\n", .{n});
    }
}
