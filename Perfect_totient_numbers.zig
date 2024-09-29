// https://rosettacode.org/wiki/Perfect_totient_numbers
// Translated from C
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const n = 20;

    const perfect_totients: [n]u32 = calcPerfectTotients(n);

    try stdout.print("The first {} perfect Totient numbers are : \n", .{n});

    var sep: []const u8 = "";
    for (perfect_totients, 1..) |number, i| {
        try stdout.print("{s}{d:4}", .{ sep, number });
        sep = if (i % 10 == 0) "\n" else " ";
    }
    try stdout.writeByte('\n');
}

fn calcTotient(n_: u32) u32 {
    var totient = n_;
    var n = n_;
    var i: u32 = 2;
    while (i * i <= n) : (i += 2) {
        if (n % i == 0) {
            while (n % i == 0)
                n /= i;
            totient -= totient / i;
        }
        if (i == 2)
            i = 1;
    }
    if (n > 1)
        totient -= totient / n;
    return totient;
}

fn calcPerfectTotients(comptime n: usize) [n]u32 {
    var perfect_totients: [n]u32 = undefined;
    var count: usize = 0;
    var m: u32 = 1;
    while (count < n) : (m += 1) {
        var totient = m;
        var sum: u32 = 0;
        while (totient != 1) {
            totient = calcTotient(totient);
            sum += totient;
        }
        if (sum == m) {
            perfect_totients[count] = m;
            count += 1;
        }
    }
    return perfect_totients;
}
