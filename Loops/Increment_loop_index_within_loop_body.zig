// https://rosettacode.org/wiki/Loops/Increment_loop_index_within_loop_body
const std = @import("std");

const LIMIT = 42;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout);
    var writer = bw.writer();

    var n: u8 = 0;
    var i: u64 = LIMIT;
    while (n < 42) : (i += 1)
        if (isPrime(i)) {
            n += 1;
            try writer.print("n = {d:2}  {d}\n", .{ n, i });
            i += i - 1;
        };

    try bw.flush();
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
