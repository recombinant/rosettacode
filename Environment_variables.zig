// https://rosettacode.org/wiki/Environment_variables
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    // no need to free with arena as arena.deinit() frees all allocated with arena
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer _ = arena.deinit();
    const allocator = arena.allocator();

    for ([_][]const u8{ "PATH", "HOME", "USER", "ZIGPATH" }) |v|
        try stdout.print("{s}={s}\n", .{ v, std.process.getEnvVarOwned(allocator, v) catch "???" });

    try stdout.flush();
}
