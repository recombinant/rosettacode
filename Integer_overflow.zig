// https://rosettacode.org/wiki/Integer_overflow
// {{works with|Zig|0.15.1}}
const std = @import("std");
const assert = std.debug.assert;
// To quote the Zig documentation:
//
// Integer literals have no size limitation, and if any undefined behavior occurs, the compiler catches it.
//
// However, once an integer value is no longer known at compile-time, it must have a known size, and is vulnerable to undefined behavior.

// All of the tasks fail at compile time if implemented directly. By using Zig's overflow arithmetic those tasks that compile give the same results at the C solution.
// It should also be noted that Zig has wraparound and saturation arithmetic too.

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ---------------------------------------------------------- i32
    try stdout.writeAll("For 32-bit signed integers:\n");
    // const c: i32 = -(-2147483647 - 1); // will not compile
    var a, var s = minusOne(i32, -2147483647);
    try stdout.print("{d}{s}\n", .{ a, s });
    // const c: i32 = 2000000000 + 2000000000; // will not compile
    a, s = twice(i32, 2000000000);
    try stdout.print("{d}{s}\n", .{ a, s });
    // const c: i32 = -2147483647 - 2147483647; // will not compile
    a, s = sub(i32, -2147483647, 2147483647);
    try stdout.print("{d}{s}\n", .{ a, s });
    // const c: i32 = 46341 * 46341; // will not compile
    a, s = square(i32, 46341);
    try stdout.print("{d}{s}\n", .{ a, s });
    // const c: i32 = (-2147483647 - 1) / -1; // will not compile
    try stdout.writeAll("runtime panic on division by -1\n");
    // ---------------------------------------------------------- i64
    try stdout.writeAll("\nFor 64-bit signed integers:\n");
    // const c: i64 = -(-9223372036854775807 - 1); // will not compile
    var b, s = minusOne(i64, -9223372036854775807);
    try stdout.print("{d}{s}\n", .{ b, s });
    // const c: i64 = 5000000000000000000 + 5000000000000000000; // will not compile
    b, s = twice(i64, 5000000000000000000);
    try stdout.print("{d}{s}\n", .{ b, s });
    // const c: i64 = -9223372036854775807 - 9223372036854775807; // will not compile
    b, s = sub(i64, -9223372036854775807, 9223372036854775807);
    try stdout.print("{d}{s}\n", .{ b, s });
    // const c: i64 = 3037000500 * 3037000500; // will not compile
    b, s = square(i64, 3037000500);
    try stdout.print("{d}{s}\n", .{ b, s });
    // const c: i64 = (-9223372036854775807 - 1) / -1; // will not compile
    try stdout.writeAll("runtime panic on division by -1\n");
    // ---------------------------------------------------------- u32
    try stdout.writeAll("\nFor 32-bit unsigned integers:\n");
    try stdout.writeAll("compiler error on negative number for unsigned\n");
    // const c: u32 = 3000000000 + 3000000000; // will not compile
    var c, s = twice(u32, 3000000000);
    try stdout.print("{d}{s}\n", .{ c, s });
    // const c: u32 = 2147483647 - 4294967295; // will not compile
    c, s = sub(u32, 2147483647, 4294967295);
    try stdout.print("{d}{s}\n", .{ c, s });
    // const c: u32 = 65537 * 65537; // will not compile
    c, s = square(u32, 65537);
    try stdout.print("{d}{s}\n", .{ c, s });
    // ---------------------------------------------------------- u64
    try stdout.writeAll("\nFor 64-bit unsigned integers:\n");
    try stdout.writeAll("compiler error on negative number for unsigned\n");
    // const c: u64 = 10000000000000000000 + 10000000000000000000; // will not compile
    var d, s = twice(u64, 10000000000000000000);
    try stdout.print("{d}{s}\n", .{ d, s });
    // const c: u64 = 9223372036854775807 - 18446744073709551615; // will not compile
    d, s = sub(u64, 9223372036854775807, 18446744073709551615);
    try stdout.print("{d}{s}\n", .{ d, s });
    // const c: u64 = 4294967296 * 4294967296; // will not compile
    d, s = square(u64, 4294967296);
    try stdout.print("{d}{s}\n", .{ d, s });
    // ----------------------------------------------------------
    try stdout.flush();
}
/// To give the result and a string.
fn Result(comptime T: type) type {
    return struct { T, []const u8 };
}
/// -(a - 1)
fn minusOne(comptime T: type, a: T) Result(T) {
    const one: T = 1;
    const zero: T = 0;
    const b = a - one;
    const ov2 = @subWithOverflow(zero, b);
    assert(ov2[1] != 0); // expect overflow
    return .{ ov2[0], if (ov2[1] == 0) "" else " (overflow)" };
}
/// a + a
fn twice(comptime T: type, a: T) Result(T) {
    const ov = @addWithOverflow(a, a);
    assert(ov[1] != 0); // expect overflow
    return .{ ov[0], if (ov[1] == 0) "" else " (overflow)" };
}
/// a - b
fn sub(comptime T: type, a: T, b: T) Result(T) {
    const ov = @subWithOverflow(a, b);
    assert(ov[1] != 0); // expect overflow
    return .{ ov[0], if (ov[1] == 0) "" else " (overflow)" };
}
/// a * a
fn square(comptime T: type, a: T) Result(T) {
    const ov = @mulWithOverflow(a, a);
    assert(ov[1] != 0); // expect overflow
    return .{ ov[0], if (ov[1] == 0) "" else " (overflow)" };
}
