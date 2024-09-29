// https://rosettacode.org/wiki/Largest_palindrome_product
const std = @import("std");
const math = std.math;
const print = std.debug.print;
const testing = std.testing;

pub fn main() void {
    // Brute force
    const l3dp = findLargest3DigitProduct();
    print("The largest palindromic product of 3-digit numbers is {d} ({d} * {d})\n\n", .{ l3dp[0], l3dp[1], l3dp[2] });

    // More optimized (Translated from Wren)
    // Slows down noticeably for 'n'' larger than 7.
    for (2..8) |n| {
        const ldp = findLargestPrimeProduct(n);
        print("Largest palindromic product of two {}-digit integers: {} x {} = {}\n", .{ n, ldp[1], ldp[2], ldp[0] });
    }
}

// Brute force.
fn findLargest3DigitProduct() struct { u64, u64, u64 } {
    var factor1: u64 = undefined;
    var factor2: u64 = undefined;
    var largest: u64 = 0;
    for (100..1000) |i|
        for (100..1000) |j| {
            const product: u64 = @as(u64, @intCast(i)) * @as(u64, @intCast(j));
            if (product >= largest and isPalindrome(product)) {
                largest = product;
                factor1 = @intCast(i);
                factor2 = @intCast(j);
            }
        };
    return .{ largest, factor1, factor2 };
}

fn isPalindrome(n: u64) bool {
    var k: u64 = 0;
    var l = n;
    while (l != 0) {
        const m = l % 10;
        k = 10 * k + m;
        l /= 10;
    }
    return n == k;
}

test isPalindrome {
    try testing.expect(isPalindrome(0));
    try testing.expect(isPalindrome(1));
    try testing.expect(!isPalindrome(10));
    try testing.expect(isPalindrome(11));
    try testing.expect(isPalindrome(101));
    try testing.expect(isPalindrome(22022));
    try testing.expect(isPalindrome(22522));
    try testing.expect(!isPalindrome(22033));
}

// Translated from Wren
fn findLargestPrimeProduct(n: u64) struct { u64, u64, u64 } {
    var pow: u64 = math.pow(u64, 10, n);
    const low: u64 = pow * 9;
    pow *= 10;
    const high: u64 = pow - 1;
    print("Largest palindromic product of two {}-digit integers: ", .{n});
    var i: u64 = high;
    while (i >= low) : (i -= 1) {
        const j = reverse(i);
        const p = i * pow + j;
        // k can't be even nor end in 5 to produce a product ending in 9
        var k = high;
        while (k > low) {
            if (k % 10 != 5) {
                const l = p / k;
                if (l > high)
                    break;
                if (p % k == 0)
                    return .{ p, k, l };
            }
            k -= 2;
        }
    }
    unreachable;
}
fn reverse(n_: u64) u64 {
    var result: u64 = 0;
    var n = n_;
    while (n != 0) {
        result = 10 * result + n % 10;
        n /= 10;
    }
    return result;
}
