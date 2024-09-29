// https://rosettacode.org/wiki/Egyptian_division
// taken from a version on rosettacode.
const std = @import("std");
const math = std.math;

pub fn main() !void {
    const result = egyptianDivision(20, 2);
    std.debug.print("20 divided by 2 is {} with remainder {}\n", .{ result[0], result[1] });
}

fn egyptianDivision(dividend: u64, divisor: u64) [2]u64 {
    const SIZE = 64;
    var powers = [_]u64{0} ** SIZE;
    var doublings = [_]u64{0} ** SIZE;

    var i: u64 = 0;

    while (i < SIZE) {
        powers[i] = math.shl(u64, 1, i);
        doublings[i] = math.shl(u64, divisor, i);
        if (doublings[i] > dividend)
            break;
        i += 1;
    }

    var accumulator: u64 = 0;
    var answer: u64 = 0;
    i -= 1;
    while (i >= 0) {
        if (accumulator + doublings[i] <= dividend) {
            accumulator += doublings[i];
            answer += powers[i];
        }
        if (i > 0)
            i -= 1
        else
            break;
    }
    const remainder = dividend - accumulator;
    return .{ answer, remainder };
}

const testing = std.testing;

test "Expect 10, 0 from egyptianDivision(20, 2)" {
    const output = egyptianDivision(20, 2);
    try testing.expect(output[0] == 10);
    try testing.expect(output[1] == 0);
}

test "Expect 580 divided by 34 is 17 and the remainder is 2" {
    const output = egyptianDivision(580, 34);
    try testing.expect(output[0] == 17);
    try testing.expect(output[1] == 2);
}
