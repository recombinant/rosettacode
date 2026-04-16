// https://rosettacode.org/wiki/Recaman%27s_sequence
// {{works with|Zig|0.16.0}}
// {{trans|Go}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    // arraylist can be initialised with capacity as the answers are known...
    var a: std.ArrayList(isize) = try .initCapacity(gpa, 400_000);
    defer a.deinit(gpa);

    var used: std.AutoHashMapUnmanaged(isize, void) = .empty;
    defer used.deinit(gpa);
    try used.ensureTotalCapacity(gpa, 1001);

    var used1000: std.AutoHashMapUnmanaged(isize, void) = .empty;
    defer used1000.deinit(gpa);
    try used1000.ensureTotalCapacity(gpa, 1001);

    try a.append(gpa, 0);
    try used.put(gpa, 0, {});
    try used1000.put(gpa, 0, {});

    var n: usize = 1;
    var found_dup = false;

    while (n <= 15 or !found_dup or used1000.count() < 1001) : (n += 1) {
        var next = a.items[n - 1] - @as(isize, @intCast(n));
        if (next < 1 or used.contains(next))
            next += 2 * @as(isize, @intCast(n));

        const already_used = used.contains(next);
        try a.append(gpa, next);
        if (!already_used) {
            try used.put(gpa, next, {});
            if (next <= 1000)
                try used1000.put(gpa, next, {});
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
