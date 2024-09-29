// https://rosettacode.org/wiki/Numbers_with_prime_digits_whose_sum_is_13
// Translation of C
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    // using 2 for all digits, 6 digits is the max prior to over-shooting 13
    var count: usize = 0;
    for (1..1_000_000) |i| {
        if (primeDigitsSum13(i)) {
            print("{d:6} ", .{i});
            count += 1;
            if (count == 10) {
                count = 0;
                print("\n", .{});
            }
        }
    }
    if (count != 0)
        print("\n", .{});
}

fn primeDigitsSum13(n_: usize) bool {
    var sum: usize = 0;
    var n = n_;
    while (n > 0 and sum <= 13) {
        const digit = n % 10;
        switch (digit) {
            2, 3, 5, 7 => {
                n /= 10;
                sum += digit;
            },
            else => return false,
        }
    }
    return sum == 13;
}
