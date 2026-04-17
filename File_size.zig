// https://rosettacode.org/wiki/File_size
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    const file1: ?Io.File = Io.Dir.cwd().openFile(io, "File_size.zig", .{}) catch null;
    if (file1) |file| {
        std.log.info("{}", .{try file.length(io)});
        file.close(io);
    }

    const file2: ?Io.File = Io.Dir.openFileAbsolute(io, "/LICENSE.txt", .{}) catch null;
    if (file2) |file| {
        std.log.info("{}", .{try file.length(io)});
        file.close(io);
    }
}
