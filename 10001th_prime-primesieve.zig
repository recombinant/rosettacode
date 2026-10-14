// https://rosettacode.org/wiki/10001th_prime
// {{works with|Zig|0.17.0}}
const std = @import("std");
const Io = std.Io;
const primesieve = @import("primesieve");

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file = Io.File.stdout().writer(init.io, &stdout_buffer);
    const stdout_writer = &stdout_file.interface;

    try stdout_writer.print("The 10,001st prime is {}.\n", .{primesieve.nthPrime(10_001, 0)});

    try stdout_writer.flush();
}
