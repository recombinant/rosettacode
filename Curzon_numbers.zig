// https://rosettacode.org/wiki/Curzon_numbers
const std = @import("std");

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    //
    var k: u64 = 2;
    while (k <= 10) : (k += 2) {
        try stdout.print("Curzon numbers with base {d}:\n", .{k});
        var n: u64 = 1;
        var count: u64 = 0;
        while (count < 50) : (n += 1) {
            if (isCurzon(n, k)) {
                count += 1;
                try stdout.print("{d: >4} ", .{n});
                if (count % 10 == 0) try stdout.writeByte('\n');
            }
        }
        while (true) {
            if (isCurzon(n, k)) count += 1;
            if (count == 1000) break;
            n += 1;
        }
        try stdout.print("1,000th Curzon number with base {d}: {d}\n\n", .{ k, n });
    }
    //
    try bw.flush();
}

fn isCurzon(n: u64, k: u64) bool {
    const r = k * n;
    return modPow(k, n, r + 1) == r;
}

fn modPow(base_arg: u64, exp_arg: u64, mod: u64) u64 {
    if (mod == 1)
        return 0;
    var base = base_arg;
    var exp = exp_arg;

    var result: u64 = 1;
    base %= mod;
    while (exp > 0) : (exp >>= 1) {
        if ((exp & 1) == 1)
            result = (result * base) % mod;
        base = (base * base) % mod;
    }
    return result;
}
