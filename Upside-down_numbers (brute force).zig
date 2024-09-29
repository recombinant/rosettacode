// https://rosettacode.org/wiki/Upside-down_numbers.zig
const std = @import("std");
const math = std.math;
const mem = std.mem;
const testing = std.testing;
const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() void {
    var count: usize = 1;

    var it = BruteForceUpsideDownIterator.init();
    while (count <= 50) : (count += 1) {
        const sep: []const u8 = if (count % 10 != 0) " " else if (count != 0) "\n" else "";
        print("{d:>4}{s}", .{ it.next(), sep });
    }

    while (count < 500) : (count += 1) _ = it.next();
    print("The 500th upside-down number is: {}\n", .{it.next()});
    count += 1;

    while (count < 5_000) : (count += 1) _ = it.next();
    print("The 5,000th upside-down number is: {}\n", .{it.next()});
    count += 1;
}

const BruteForceUpsideDownIterator = struct {
    number: u64,

    fn init() BruteForceUpsideDownIterator {
        return BruteForceUpsideDownIterator{
            .number = 0,
        };
    }
    fn next(self: *BruteForceUpsideDownIterator) u64 {
        self.number += 1;
        while (!isUpsideDown(self.number))
            self.number += 1;
        return self.number;
    }
};

/// Return a slice holding all the decimal digits representing `number`.
/// Least significant digit first.
fn getDigits(output: []u4, number: u64) []u4 {
    const n_digits: usize = if (number == 0) 1 else math.log10(number) + 1;

    assert(output.len >= n_digits);
    const result = output[0..n_digits];

    var n = number;
    for (result) |*digit| {
        digit.* = @truncate(n % 10);
        n /= 10;
    }
    return result;
}

test getDigits {
    var buffer: [math.log10(math.maxInt(u64)) + 1]u4 = undefined;

    const expected0 = &[_]u4{0};
    const actual0 = getDigits(&buffer, 0);

    try testing.expectEqualSlices(u4, expected0, actual0);

    const expected1 = &[_]u4{1};
    const actual1 = getDigits(&buffer, 1);

    try testing.expectEqualSlices(u4, expected1, actual1);

    const expected2 = &[_]u4{ 3, 9, 4, 5, 6, 1, 7 };
    const actual2 = getDigits(&buffer, 7165493);

    try testing.expectEqualSlices(u4, expected2, actual2);

    var expected3 = [_]u4{
        1, 8, 4, 4, 6, 7, 4, 4, 0, 7,
        3, 7, 0, 9, 5, 5, 1, 6, 1, 5,
    };
    mem.reverse(u4, &expected3);
    const actual3 = getDigits(&buffer, math.maxInt(u64));

    try testing.expectEqualSlices(u4, &expected3, actual3);
}

test "overflow of u4" {
    var overflow_found = false;
    var i: u8 = 0;
    while (i < 10) : (i += 1) {
        var j: u8 = 0;
        while (j < 10) : (j += 1) {
            const i_4: u4 = @intCast(i);
            const j_4: u4 = @intCast(j);
            const ov = @addWithOverflow(i_4, j_4);
            if (ov[1] != 0) {
                overflow_found = true;
                try testing.expect(i_4 +% j_4 != 10);
            }
        }
    }
    try testing.expect(overflow_found);
}

fn isUpsideDown(number: u64) bool {
    var buffer: [math.log10(math.maxInt(u64)) + 1]u4 = undefined;

    const digits = getDigits(&buffer, number);

    const mid = digits.len / 2 + digits.len % 2;
    const end = digits.len - 1;

    for (0..mid) |left| {
        const right = end - left;
        // u4 overflow occurs at 15
        if (digits[left] +% digits[right] != 10)
            return false;
    }
    return true;
}

test isUpsideDown {
    try testing.expect(isUpsideDown(5));
    try testing.expect(isUpsideDown(19));
    try testing.expect(isUpsideDown(91));
    try testing.expect(isUpsideDown(159));
    try testing.expect(isUpsideDown(951));
    try testing.expect(isUpsideDown(3467));
    try testing.expect(isUpsideDown(7643));
    try testing.expect(isUpsideDown(74563));
    try testing.expect(isUpsideDown(36547));

    try testing.expect(!isUpsideDown(0));
    try testing.expect(!isUpsideDown(1));
    try testing.expect(!isUpsideDown(2));
    try testing.expect(!isUpsideDown(3));
    try testing.expect(!isUpsideDown(4));
    try testing.expect(!isUpsideDown(6));
    try testing.expect(!isUpsideDown(7));
    try testing.expect(!isUpsideDown(8));
    try testing.expect(!isUpsideDown(9));
    try testing.expect(!isUpsideDown(11));
}
