// https://rosettacode.org/wiki/Harshad_or_Niven_series
// {{works with|Zig|0.16.0}}
const std = @import("std");

const limit = 1000;

const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll("Harshad or Niven series\n\n");

    var n: u16 = 1;
    var found: u16 = 0;

    try stdout.writeAll("First 20: ");
    while (true) : (n += 1) {
        if (n % digsum(n) == 0) {
            if (found < 20) try stdout.print("{} ", .{n});
            found += 1;
            if (n > limit) {
                try stdout.print("\nFirst above {}: {}\n", .{ limit, n });
                break;
            }
        }
    }
    try stdout.flush();
}

fn digsum(n_: u16) u16 {
    var n = n_;
    var sum: u16 = 0;
    while (n != 0) : (n /= 10) sum += n % 10;
    return sum;
}
