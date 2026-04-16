// https://rosettacode.org/wiki/Hofstadter-Conway_$10,000_sequence
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

    var a: std.ArrayList(u32) = .empty;
    defer a.deinit(gpa);

    try a.appendSlice(gpa, &[3]u32{ 0, 1, 1 }); // ignore 0 element. work 1 based.
    var x: u32 = 1; // last number in list
    var n: usize = 2; // index of last number in list = a.len - 1
    var mallows: usize = 0;
    for (1..21) |p| {
        var max: f64 = 0;
        const next_pot = n * 2;
        while (n < next_pot) {
            n = a.items.len; // advance n
            x = a.items[x] + a.items[n - x];
            try a.append(gpa, x);
            const f = @as(f64, @floatFromInt(x)) / @as(f64, @floatFromInt(n));
            if (f > max) max = f;
            if (f >= 0.55) mallows = n;
        }
        try stdout.print("max between 2^{d} and 2^{d} was {d}\n", .{ p, p + 1, max });
    }
    try stdout.print("winning number {d}\n", .{mallows});

    try stdout.flush();
}
