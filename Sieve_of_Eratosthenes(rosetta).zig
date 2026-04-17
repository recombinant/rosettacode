// https://rosettacode.org/wiki/Sieve_of_Eratosthenes
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;

const lim = 1000;

pub fn main(init: std.process.Init) anyerror!void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    // primes start at 2
    // non-primes will be null
    var primes: [lim - 2]?usize = undefined;
    for (&primes, 2..) |*prime_, i|
        prime_.* = i;

    var m: usize = 0;
    for (&primes, 0..) |prime_, i|
        if (prime_) |prime| {
            m += 1;
            try stdout.print("{:5}", .{prime});
            if (m % 10 == 0)
                try stdout.writeByte('\n');
            var j = i + prime;
            while (j < primes.len) : (j += prime)
                primes[j] = null;
        };
    try stdout.writeByte('\n');

    try stdout.flush();
}
