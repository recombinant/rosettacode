// https://rosettacode.org/wiki/Department_numbers#Zig
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll("Police  Sanitation  Fire\n");
    try stdout.writeAll("------  ----------  ----\n");

    var p: usize = 2;
    while (p <= 7) : (p += 2)
        for (1..7 + 1) |s|
            for (1..7 + 1) |f|
                if (p != s and s != f and f != p and p + f + s == 12) {
                    try stdout.print("  {d}         {d}         {d}\n", .{ p, s, f });
                };
    try stdout.flush();
}
