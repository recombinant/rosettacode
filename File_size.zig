// https://rosettacode.org/wiki/File_size
const std = @import("std");

pub fn main() !void {
    const file1: ?std.fs.File = std.fs.cwd().openFile("File_size.zig", .{}) catch null;
    if (file1) |file|
        std.log.info("{}", .{try file.getEndPos()});

    const file2: ?std.fs.File = std.fs.openFileAbsolute("/LICENSE.txt", .{}) catch null;
    if (file2) |file|
        std.log.info("{}", .{try file.getEndPos()});
}
