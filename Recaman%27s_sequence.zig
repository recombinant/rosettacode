// https://rosettacode.org/wiki/Recaman%27s_sequence
// {{works with|Zig|0.15.1}}
// {{trans|Go}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // arraylist can be initialised with capacity as the answers are known...
    var a: std.ArrayList(isize) = try .initCapacity(allocator, 400_000);
    defer a.deinit(allocator);

    var used: std.AutoHashMapUnmanaged(isize, void) = .empty;
    defer used.deinit(allocator);
    try used.ensureTotalCapacity(allocator, 1001);

    var used1000: std.AutoHashMapUnmanaged(isize, void) = .empty;
    defer used1000.deinit(allocator);
    try used1000.ensureTotalCapacity(allocator, 1001);

    try a.append(allocator, 0);
    try used.put(allocator, 0, {});
    try used1000.put(allocator, 0, {});

    var n: usize = 1;
    var found_dup = false;

    while (n <= 15 or !found_dup or used1000.count() < 1001) : (n += 1) {
        var next = a.items[n - 1] - @as(isize, @intCast(n));
        if (next < 1 or used.contains(next))
            next += 2 * @as(isize, @intCast(n));

        const already_used = used.contains(next);
        try a.append(allocator, next);
        if (!already_used) {
            try used.put(allocator, next, {});
            if (next <= 1000)
                try used1000.put(allocator, next, {});
        }

        if (n == 14)
            try stdout.print("The first 15 terms of the Recaman's sequence are: {any}\n", .{a.items});

        if (!found_dup and already_used) {
            try stdout.print("The first duplicated term is a[{d}] = {d}\n", .{ n, next });
            found_dup = true;
        }

        if (used1000.count() == 1001)
            try stdout.print("Terms up to a[{d}] are needed to generate 0 to 1000\n", .{n});
    }
    try stdout.flush();
}
