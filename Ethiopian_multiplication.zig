// https://rosettacode.org/wiki/Ethiopian_multiplication
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const multiplier: u16 = 17;
    const multiplicand: u16 = 34;
    const result = ethiopian(multiplier, multiplicand);

    try stdout.writeAll("using Ethiopian multiplication:\n");
    try stdout.print("    {} * {} = {}\n", .{ multiplier, multiplicand, result });

    try stdout.flush();
}

fn ethiopian(multiplier_: anytype, multiplicand_: anytype) @TypeOf(multiplier_, multiplicand_) {
    const T = @TypeOf(multiplier_, multiplicand_);
    if (@typeInfo(T) != .int and @typeInfo(T) != .comptime_int)
        @compileError("ethiopianMultiplication() expected integer argument, found " ++ @typeName(T));

    const sign = std.math.sign(multiplier_) * std.math.sign(multiplicand_);
    var multiplier: T = @abs(multiplier_);
    var multiplicand: T = @abs(multiplicand_);
    var result: T = 0;

    while (multiplier >= 1) {
        if (!isEven(multiplier))
            result += multiplicand;
        multiplier = halve(multiplier);
        multiplicand = double(multiplicand);
    }
    return result * sign;
}
fn halve(n: anytype) @TypeOf(n) {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int and @typeInfo(T) != .comptime_int)
        @compileError("halve() expected integer argument, found " ++ @typeName(T));
    return @divTrunc(n, 2);
}
fn double(n: anytype) @TypeOf(n) {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int and @typeInfo(T) != .comptime_int)
        @compileError("double() expected integer argument, found " ++ @typeName(T));
    return n * 2;
}
fn isEven(n: anytype) bool {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int and @typeInfo(T) != .comptime_int)
        @compileError("isEven() expected integer argument, found " ++ @typeName(T));
    return @mod(n, 2) == 0;
}

const testing = std.testing;

test halve {
    try testing.expectEqual(5, halve(10));
    try testing.expectEqual(5, halve(11));
    try testing.expectEqual(6, halve(12));
    try testing.expectEqual(6, halve(13));

    try testing.expectEqual(-5, halve(-10));
    try testing.expectEqual(-5, halve(-11));

    try testing.expectEqual(0, halve(0));
}
test double {
    try testing.expectEqual(20, double(10));
    try testing.expectEqual(22, double(11));
    try testing.expectEqual(24, double(12));
    try testing.expectEqual(26, double(13));

    try testing.expectEqual(-26, double(-13));

    try testing.expectEqual(0, double(0));
}
test isEven {
    try testing.expect(isEven(10));
    try testing.expect(!isEven(11));
    try testing.expect(isEven(12));
    try testing.expect(!isEven(13));

    try testing.expect(isEven(-10));
    try testing.expect(!isEven(-11));

    try testing.expect(isEven(0));
}
test ethiopian {
    try testing.expectEqual(578, ethiopian(17, 34));
    try testing.expectEqual(-578, ethiopian(17, -34));
    try testing.expectEqual(-578, ethiopian(-17, 34));
    try testing.expectEqual(578, ethiopian(-17, -34));

    try testing.expectEqual(9801, ethiopian(99, 99));

    try testing.expectEqual(0, ethiopian(0, 0));
    try testing.expectEqual(0, ethiopian(1, 0));
    try testing.expectEqual(0, ethiopian(0, 1));
    try testing.expectEqual(0, ethiopian(-1, 0));
    try testing.expectEqual(0, ethiopian(0, -1));
}
