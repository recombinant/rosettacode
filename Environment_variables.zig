// https://rosettacode.org/wiki/Environment_variables
const std = @import("std");

pub fn main() !void {
    const writer = std.io.getStdOut().writer();

    // no need to free with arena as arena.deinit() frees all allocated with arena
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    const allocator = arena.allocator();

    for ([_][]const u8{ "PATH", "HOME", "USER", "ZIGPATH" }) |v|
        try writer.print("{s}={s}\n", .{ v, std.process.getEnvVarOwned(allocator, v) catch "???" });
}
