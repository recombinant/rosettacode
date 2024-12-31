// https://rosettacode.org/wiki/Program_name
// Copied from rosettacode
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const program_name = std.fs.path.basename(args[0]);

    const writer = std.io.getStdOut().writer();
    try writer.print("{s}\n", .{program_name});
}
