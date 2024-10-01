// https://rosettacode.org/wiki/Least_common_multiple
const std = @import("std");
const math = std.math;
const assert = std.debug.assert;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("lcm(35, 21) = {}\n", .{lcm(21, 35)});
}

fn lcm(a: anytype, b: anytype) @TypeOf(a, b) {
    // only unsigned integers are allowed and neither can be zero
    comptime switch (@typeInfo(@TypeOf(a, b))) {
        .int => |int| assert(int.signedness == .unsigned),
        .comptime_int => {
            assert(a >= 0);
            assert(b >= 0);
        },
        else => unreachable,
    };
    assert(a != 0 or b != 0);

    return a / math.gcd(a, b) * b;
}

const testing = std.testing;

test "Least Common Multiplier" {
    try testing.expectEqual(36, lcm(12, 18));
    try testing.expectEqual(36, lcm(@as(u16, 12), @as(u16, 18)));
    try testing.expectEqual(60, lcm(@as(u32, 15), @as(u32, 12)));
    try testing.expectEqual(70, lcm(@as(u64, 10), @as(u64, 14)));
}
