// https://rosettacode.org/wiki/Composite_numbers_k_with_no_single_digit_factors_whose_factors_are_all_substrings_of_k
// {{works with|Zig|0.16.0}}
// {{trans|C}}
const std = @import("std");

const Io = std.Io;

pub fn main(init: std.process.Init) void {
    const io: Io = init.io;

    var t0: Io.Timestamp = .now(io, .real);

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    var amount: u32 = 7;
    var n: u32 = 11;
    while (amount > 0) : (n += 2) {
        if (factorsAreSubstrings(n)) {
            stdout.print("{}\n", .{n}) catch unreachable;
            stdout.flush() catch unreachable;
            amount -= 1;
        }
    }
    std.log.info("processed in {f}", .{t0.untilNow(io, .real)});
}
fn isSubstring(n_: u32, k: u32) bool {
    var n = n_;
    var startMatch: u32 = 0;
    var pfx: u32 = k;
    while (n > 0) : (n /= 10) {
        if (pfx % 10 == n % 10) {
            pfx /= 10;
            if (startMatch == 0)
                startMatch = n;
        } else {
            pfx = k;
            if (startMatch != 0)
                n = startMatch;
            startMatch = 0;
        }
        if (pfx == 0)
            return true;
    }
    return false;
}
/// Only odd numbers should be passed to this routine.
fn factorsAreSubstrings(n: u32) bool {
    if (n % 3 == 0 or n % 5 == 0 or n % 7 == 0) return false;
    var factor_count: u32 = 0;
    var factor: u32 = 11;
    var n_rest: u32 = n;
    while (factor <= n_rest) : (factor += 2) {
        if (n_rest % factor != 0)
            continue;
        if (!isSubstring(n, factor))
            return false;
        while (n_rest % factor == 0)
            n_rest /= factor;
        factor_count += 1;
    }
    return factor_count > 1;
}
