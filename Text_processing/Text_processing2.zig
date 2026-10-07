// https://rosettacode.org/wiki/Text_processing/2
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

    // ----------------------------------------------------------
    var stats = try analyse(gpa, &reader.interface);
    defer stats.deinit(gpa);

    try stats.report(gpa, stdout_writer);

    // ----------------------------------------------------------
    try stdout_writer.flush();
}

fn analyse(gpa: Allocator, r: *Io.Reader) !Stats {
    var stats: Stats = .{};

    const IteratorTSV = csvz.Csv(.{ .delimiter = '\t' });
    var it = IteratorTSV.init(r);

    while (true) {
        var field_count: usize = 0;

        // Get the date field first
        const date_field = it.next() catch |err| switch (err) {
            csvz.Iterator.Error.EOF => break,
            else => return err,
        };
        field_count += 1;

        if (stats.times_lookup.getPtr(date_field.data)) |value_ptr|
            value_ptr.* += 1
        else
            try stats.times_lookup.put(gpa, try gpa.dupe(u8, date_field.data), 1);

        var no_errors = true;

        // Get the remaining fields on the line
        while (true) {
            _ = it.next() catch |err| switch (err) {
                csvz.Iterator.Error.EOF => break,
                else => return err,
            };
            field_count += 1;

            const flag_field = it.next() catch |err| switch (err) {
                csvz.Iterator.Error.EOF => break,
                else => return err,
            };
            field_count += 1;
            if (flag_field.data[0] == '-' or flag_field.data[0] == '0')
                no_errors = false;

            if (flag_field.last_column) {
                stats.records += 1;
                stats.good_records += @intFromBool(no_errors);
                break;
            }
        }
        if (field_count != 49)
            stats.bad_records += 1;
    }
    return stats;
}

const Stats = struct {
    records: usize = 0,
    good_records: usize = 0,
    bad_records: usize = 0,
    times_lookup: std.StringHashMapUnmanaged(usize) = .empty,

    fn deinit(self: *Stats, allocator: Allocator) void {
        var it = self.times_lookup.keyIterator();
        while (it.next()) |key| allocator.free(key.*);
        self.times_lookup.deinit(allocator);
    }

    fn report(self: *const Stats, allocator: Allocator, w: *Io.Writer) !void {
        try w.print(
            \\records:            {d: >4}
            \\error free records: {d: >4}
            \\bad records:        {d: >4}
            \\
        , .{ self.records, self.good_records, self.bad_records });

        // No deinit() - toOwnedSlice() & contents are owned by times_lookup keys
        var date_list: std.ArrayList([]const u8) = .empty;

        var it2 = self.times_lookup.iterator();
        while (it2.next()) |entry| {
            if (entry.value_ptr.* > 1)
                try date_list.append(allocator, entry.key_ptr.*);
        }

        try w.writeAll("duplicated dates:\n");
        if (date_list.items.len == 0)
            try w.writeAll("none\n")
        else {
            // sort the dates for presentation
            const dates = try date_list.toOwnedSlice(allocator);
            defer allocator.free(dates);
            std.mem.sortUnstable([]const u8, dates, {}, compareStrings);

            for (dates) |date|
                try w.print("  {s}\n", .{date});
        }
    }

    // For sorting the dates
    fn compareStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
        return std.mem.order(u8, lhs, rhs).compare(std.math.CompareOperator.lt);
    }
};
