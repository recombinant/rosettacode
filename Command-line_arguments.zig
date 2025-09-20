// https://rosettacode.org/wiki/Command-line_arguments
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    // ------------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ---------------------------------------------------- allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ---------------------------------------------------
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    //
    var i: usize = 0;
    while (args.next()) |arg| {
        try stdout.print("arg {}: {s}\n", .{ i, arg });
        i += 1;
    }
    try stdout.flush();
}
