// https://rosettacode.org/wiki/Sleep
// {{works with|Zig|0.14.1}}
// Copied from rosettacode
const std = @import("std");
const time = std.time;
const info = std.log.info;

pub fn main() void {
    info("Sleeping...", .{});

    time.sleep(1 * time.ns_per_s); // `sleep` uses nanoseconds

    info("Awake!", .{});
}
