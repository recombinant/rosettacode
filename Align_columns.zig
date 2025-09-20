// https://www.rosettacode.org/wiki/Align_columns
// {{works with|Zig|0.15.1}}
// Based on C
const std = @import("std");

const MaxCols = 1024;

const str: []const u8 =
    \\Given$a$text$file$of$many$lines,$where$fields$within$a$line$
    \\are$delineated$by$a$single$'dollar'$character,$write$a$program
    \\that$aligns$each$column$of$fields$by$ensuring$that$words$in$each$
    \\column$are$separated$by$at$least$one$space.
    \\Further,$allow$for$each$word$in$a$column$to$be$either$left$
    \\justified,$right$justified,$or$center$justified$within$its$column.
;

const Alignment = enum {
    left,
    center,
    right,
};

const AlignError = error{
    MaxColsExceeded,
};

fn alignColumns(w: *std.Io.Writer, lines: []const u8, alignment: Alignment) !void {
    var widths: [MaxCols]usize = @splat(0);
    // Determine the required width of each column using maximum field lengths
    {
        var lines_iterator = std.mem.splitScalar(u8, lines, '\n');
        while (lines_iterator.next()) |line| {
            var column: usize = 0;
            var field_iterator = std.mem.splitScalar(u8, line, '$');
            while (field_iterator.next()) |field| : (column += 1)
                widths[column] = @max(widths[column], field.len);
        }
    }
    // Knowing the width of each column print the justified fields
    {
        var lines_iterator = std.mem.splitScalar(u8, lines, '\n');
        while (lines_iterator.next()) |line| {
            var column: usize = 0;
            var field_iterator = std.mem.splitScalar(u8, line, '$');
            while (field_iterator.next()) |field| : (column += 1) {
                const rpad = switch (alignment) {
                    .left => widths[column] - field.len,
                    .center => @divTrunc(widths[column] - field.len, 2),
                    .right => 0,
                };
                const lpad = widths[column] - field.len - rpad;

                _ = try w.splatByte(' ', lpad);
                try w.writeAll(field);
                _ = try w.splatByte(' ', rpad);
            }
            try w.writeByte('\n');
        }
    }
}

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll("\n----  right ----\n");
    try alignColumns(stdout, str, .right);

    try stdout.writeAll("\n----  left  ----\n");
    try alignColumns(stdout, str, .left);

    try stdout.writeAll("\n---- center ----\n");
    try alignColumns(stdout, str, .center);

    try stdout.flush();
}
