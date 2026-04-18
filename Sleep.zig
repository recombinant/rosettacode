// https://rosettacode.org/wiki/Sleep
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;
const info = std.log.info;

pub fn main(init: std.process.Init) void {
    const io: Io = init.io;

    info("Sleeping...", .{});

    Io.sleep(io, .fromSeconds(1), .real) catch unreachable;

    info("Awake!", .{});
}
