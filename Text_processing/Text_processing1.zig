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

    const path = "data/readings.tsv";
    var file = try std.Io.Dir.cwd().openFile(io, path, .{});
    defer file.close(io);

    var buffer: [4096]u8 = undefined;
    var reader = file.reader(io, &buffer);
    const IteratorTSV = csvz.Csv(.{ .delimiter = '\t' });
    var it = IteratorTSV.init(&reader.interface);

    var file_stats: FileStats = .init();
    defer file_stats.deinit(gpa);

    while (true) {
        const date_field = it.next() catch |err| switch (err) {
            csvz.Iterator.Error.EOF => break,
            else => return err,
        };
        const date = gpa.dupe(u8, date_field.data) catch @panic("OOM");
        defer gpa.free(date);

        var line_stats: LineStats = .init(date);

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

            line_stats.add(value, valid);
            try file_stats.add(gpa, date, value, valid);

            if (flag_field.last_column) {
                try line_stats.write(stdout_writer);
                break;
            }
        }
    }
    try file_stats.write(stdout_writer, std.fs.path.basename(path));

    try stdout_writer.flush();
}

const FileStats = struct {
    accepted: usize = 0,
    total: f64 = 0,
    contiguous_rejected: usize = 0,
    max_contiguous_rejected: usize = 0,
    max_contiguous_rejected_date: ?[]const u8 = null,

    fn init() FileStats {
        return .{};
    }
    fn deinit(self: *FileStats, allocator: Allocator) void {
        if (self.max_contiguous_rejected_date) |memory| allocator.free(memory);
    }
    fn add(self: *FileStats, allocator: Allocator, date: []const u8, value: f64, valid: bool) !void {
        if (valid) {
            self.total += value;
            self.accepted += 1;
            if (self.contiguous_rejected > self.max_contiguous_rejected) {
                self.max_contiguous_rejected = self.contiguous_rejected;
                if (self.max_contiguous_rejected_date) |memory| allocator.free(memory);
                self.max_contiguous_rejected_date = try allocator.dupe(u8, date);
            }
            self.contiguous_rejected = 0;
        } else {
            self.contiguous_rejected += 1;
        }
    }
    fn write(self: *const FileStats, w: *Io.Writer, filename: []const u8) !void {
        try w.print(
            \\
            \\File:     {s}
            \\Total:    {d:.3}
            \\Average:  {d:.3}
            \\Readings: {}
            \\
            \\
        ,
            .{ filename, self.total, self.total / @as(f64, @floatFromInt(self.accepted)), self.accepted },
        );
        if (self.max_contiguous_rejected != 0)
            try w.print(
                \\Maximum number of consecutive bad readings is {}
                \\Ends on date {s}
                \\
            , .{ self.max_contiguous_rejected, self.max_contiguous_rejected_date.? })
        else
            try w.writeAll("There were no rejects\n");
    }
};

const LineStats = struct {
    date: []const u8,
    accepted: usize = 0,
    rejected: usize = 0,
    total: f64 = 0,

    fn init(date: []const u8) LineStats {
        return .{
            .date = date, // only valid calling function's date is in scope
        };
    }
    fn add(self: *LineStats, value: f64, valid: bool) void {
        if (valid) {
            self.accepted += 1;
            self.total += value;
        } else {
            self.rejected += 1;
        }
    }
    fn write(self: *const LineStats, w: *Io.Writer) !void {
        const average: f64 = if (self.accepted != 0) self.total / @as(f64, @floatFromInt(self.accepted)) else 0;
        const total: f64 = if (self.accepted != 0) self.total else 0;
        try w.print(
            "Line:  {s}  Reject: {d:2}  Accept: {d:2}  Line_tot: {d:8.3}  Line_avg: {d:6.3}\n",
            .{
                self.date,
                self.rejected,
                self.accepted,
                total,
                average,
            },
        );
    }
};
