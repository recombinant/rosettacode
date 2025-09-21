// https://rosettacode.org/wiki/Sum_digits_of_an_integer
// {{works with|Zig|0.15.1}}
// zig test Sum_digits_of_an_integer.zig
const std = @import("std");

const SumDigitsError = error{
    BaseError,
};

fn sumDigits(num: i64, base: u8) !u8 {
    if (base < 2)
        return SumDigitsError.BaseError;
    var n: u64 = @abs(num);
    var sum: u64 = 0;
    while (n >= base) {
        sum += n % base;
        n /= base;
    }
    return @intCast(sum + n);
}

const testing = std.testing;

test sumDigits {
    try testing.expectEqual(0, try sumDigits(0, 10));
    try testing.expectEqual(1, try sumDigits(1, 10));
    try testing.expectEqual(15, try sumDigits(12345, 10));
    try testing.expectEqual(15, try sumDigits(-12345, 10));
    try testing.expectEqual(15, try sumDigits(123045, 10));
    try testing.expectEqual(0, try sumDigits(0x00, 16));
    try testing.expectEqual(29, try sumDigits(0xfe, 16));
    try testing.expectEqual(29, try sumDigits(0xf0e, 16));
    try testing.expectEqual(232, try sumDigits(0x7fff_ffff_ffff_ffff, 16));
    try testing.expectEqual(232, try sumDigits(-0x7fff_ffff_ffff_ffff, 16));
    try testing.expectEqual(8, try sumDigits(-0x8000_0000_0000_0000, 16));

    try testing.expectError(SumDigitsError.BaseError, sumDigits(1, 1));
    try testing.expectError(SumDigitsError.BaseError, sumDigits(1, 0));
}
