// https://rosettacode.org/wiki/Assertions
// {{works with|Zig|0.16.0}}

// from https://github.com/tiehuis/zig-rosetta
const std = @import("std");
const Io = std.Io;
const assert = std.debug.assert;

pub fn main(init: std.process.Init) void {
    const a = 42;
    // Compile-time assertion
    comptime assert(a == 42);

    var b: [2]u8 = undefined;
    Io.random(init.io, &b);
    // Run-time assertion
    assert(b[0] == 42);
}
