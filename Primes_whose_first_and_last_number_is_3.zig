// https://rosettacode.org/wiki/Primes_whose_first_and_last_number_is_3
// Translation of C
const std = @import("std");

pub fn main() !void {
    const writer = std.io.getStdOut().writer();

    var np: usize = 1;
    try writer.writeAll("   3 ");
    for (1..6) |d| {
        var i: usize = 3;
        while (i < std.math.pow(usize, 10, d) - 1) : (i += 10) {
            const n = i + 3 * std.math.pow(usize, 10, d);
            if (isPrime(n)) {
                np += 1;
                if (n < 4009) {
                    const sep: u8 = if (np % 10 == 0) '\n' else ' ';
                    try writer.print("{d:4}{c}", .{ n, sep });
                }
            }
        }
    }
    if (np % 10 != 0)
        try writer.writeByte('\n');
    try writer.print(
        "\nThere were {d} primes of the form 3x3 below one million.\n",
        .{np},
    );
}

fn isPrime(n: anytype) bool {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("isPrime() expected unsigned integer argument, found " ++ @typeName(T));

    if (n < 2) return false;

    inline for ([3]u3{ 2, 3, 5 }) |p| if (n % p == 0) return n == p;

    const wheel = comptime [_]u3{ 4, 2, 4, 2, 4, 6, 2, 6 };

    var p: T = 7;
    while (true)
        for (wheel) |w| {
            if (p * p > n) return true;
            if (n % p == 0) return false;
            p += w;
        };
}
