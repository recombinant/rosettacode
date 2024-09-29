// https://rosettacode.org/wiki/Assertions
// from https://github.com/tiehuis/zig-rosetta
const std = @import("std");
const posix = std.posix;
const assert = std.debug.assert;

pub fn main() void {
    const a = 42;
    // Compile-time assertion
    comptime assert(a == 42);

    var b: [2]u8 = undefined;
    posix.getrandom(&b) catch unreachable;
    // Run-time assertion
    assert(b[0] == 42);
}
