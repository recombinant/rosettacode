// https://rosettacode.org/wiki/Tau_number
// {{works with|Zig|0.15.1}}
// {{trans|C++}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const limit = 100;
    try stdout.print("The first {d} tau numbers are:\n", .{limit});

    var count: u16 = 0;
    var n: u32 = 1;
    while (count < limit) : (n += 1)
        if (n % countDivisors(n) == 0) {
            try stdout.print("{d:6}", .{n});
            count += 1;
            if (count % 10 == 0) try stdout.writeByte('\n');
        };

    try stdout.flush();
}

// See https://en.wikipedia.org/wiki/Divisor_function
fn countDivisors(nn: u32) u16 {
    var n = nn;
    var total: u16 = 1;
    // Deal with powers of 2 first.
    while (n & 1 == 0) : (n >>= 1) total += 1;

    // Odd prime factors up to the square root.
    var p: u32 = 3;
    while (p * p <= n) : (p += 2) {
        var count: u16 = 1;
        while (n % p == 0) : (n /= p) count += 1;
        total *= count;
    }
    // If n > 1 then it's prime.
    if (n > 1) total *= 2;
    return total;
}
