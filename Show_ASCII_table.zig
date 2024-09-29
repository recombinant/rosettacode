// https://rosettacode.org/wiki/Show_ASCII_table
const std = @import("std");

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    for (0..16) |i| {
        var separator: []const u8 = "";
        var j: u8 = @truncate(i + 32);
        while (j < 128) : (j += 16) {
            try stdout.print("{s}{d:3} : ", .{ separator, j });
            switch (j) {
                ' ' => {
                    try stdout.writeAll("Spc");
                    separator = " " ** 2;
                },
                127 => {
                    try stdout.writeAll("Del");
                    separator = " " ** 2;
                },
                else => {
                    try stdout.writeByte(j);
                    separator = " " ** 4;
                },
            }
        }
        try stdout.writeByte('\n');
    }
    try bw.flush();
}
