// https://rosettacode.org/wiki/Gapful_numbers
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    try printGaps(io, 100, 30);
    try printGaps(io, 1_000_000, 15);
    try printGaps(io, 1_000_000_000, 15);
}

fn gapful(comptime T: type, n: T) bool {
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("T must be an unsigned int type");

    var m = n;
    while (m >= 10)
        m /= 10;
    return n % ((n % 10) + 10 * (m % 10)) == 0;
}

fn printGaps(io: Io, start: u64, count_limit: usize) !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    var i = start;
    var count: @TypeOf(count_limit) = 0;

    try stdout.print("\nFirst {d} Gapful numbers >= {d} :\n", .{ count_limit, start });

    while (count < count_limit) {
        if (gapful(@TypeOf(i), i)) {
            count += 1;
            try stdout.print("{d:>3} : {d}\n", .{ count, i });
        }
        i += 1;
    }

    try stdout.writeAll("\n");
    try stdout.flush();
}
