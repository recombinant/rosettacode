// https://rosettacode.org/wiki/Command-line_arguments
const std = @import("std");

pub fn main() !void {
    // ------------------------------------------------------- stdout
    const stdout = std.io.getStdOut().writer();
    // ---------------------------------------------------- allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
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
}
