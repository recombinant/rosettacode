// https://rosettacode.org/wiki/Text_processing/1
// {{works with|Zig|0.17.0}}
// {{libheader|csvzero}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const csvz = @import("csvzero");

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    var file = try std.Io.Dir.cwd().openFile(io, "data/readings.tsv", .{});
    defer file.close(io);

    var buffer: [64 * 1024]u8 = undefined;
    var reader = file.reader(io, &buffer);
    const IteratorTSV = csvz.Csv(.{ .delimiter = '\t' });
    var it = IteratorTSV.init(&reader.interface);

    var total: f64 = 0;
    var readings: usize = 0;
    var rejects: usize = 0;
    var max_rejects: usize = 0;
    var max_rejects_date: ?[]const u8 = null;
    defer if (max_rejects_date) |date| gpa.free(date);

    while (true) {
        const date_field = it.next() catch |err| switch (err) {
            csvz.Iterator.Error.EOF => break,
            else => return err,
        };
        const date = gpa.dupe(u8, date_field.data) catch @panic("OOM");
        defer gpa.free(date);

        while (true) {
            const value_field = it.next() catch |err| switch (err) {
                csvz.Iterator.Error.EOF => break,
                else => return err,
            };
            const value = try std.fmt.parseFloat(f64, value_field.data);

            const flag_field = it.next() catch |err| switch (err) {
                csvz.Iterator.Error.EOF => break,
                else => return err,
            };
            const valid = flag_field.data[0] != '-' and flag_field.data[0] != '0';

            if (valid) {
                total += value;
                readings += 1;
                if (rejects > max_rejects) {
                    max_rejects = rejects;
                    if (max_rejects_date) |memory| gpa.free(memory);
                    max_rejects_date = gpa.dupe(u8, date) catch @panic("OOM");
                }
                rejects = 0;
            } else {
                rejects += 1;
            }

            if (flag_field.last_column)
                break;
        }
    }
    try stdout_writer.print(
        \\Total:    {d:.3}
        \\Average:  {d:.3}
        \\Readings: {}
        \\
        \\
    , .{ total, total / @as(f64, @floatFromInt(readings)), readings });

    if (max_rejects != 0)
        try stdout_writer.print(
            \\Maximum number of consecutive bad readings is {}
            \\Ends on date {s}
            \\
        , .{ max_rejects, max_rejects_date.? })
    else
        try stdout_writer.writeAll("There were no rejects\n");

    try stdout_writer.flush();
}
