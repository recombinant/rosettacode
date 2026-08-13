// https://rosettacode.org/wiki/Abbreviations,_automatic
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;
    const gpa: Allocator = init.gpa;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    // File is UTF-8 (not CP437)
    const filename: []const u8 = "data/days_of_week.txt";
    const f = try Io.Dir.cwd().openFile(io, filename, .{});
    defer f.close(io);

    var file_buffer: [4096]u8 = undefined;
    var file_reader = f.reader(io, &file_buffer);
    const reader = &file_reader.interface;

    var w: Io.Writer.Allocating = .init(gpa);
    const writer = &w.writer;
    defer w.deinit();

    // indexes to UTF-8 characters
    var day_char_indexes: [7]std.ArrayList(usize) = @splat(.empty);
    defer {
        for (&day_char_indexes) |*list|
            list.*.deinit(gpa);
    }

    var days_buffer: [7][]const u8 = undefined;
    var days_list: std.ArrayList([]const u8) = .initBuffer(&days_buffer);

    while (true) {
        w.clearRetainingCapacity();

        // ------------------------------------------ read a line
        _ = readLine(reader, writer) catch |err|
            if (err == error.EndOfStream) break else return err;

        const line = w.written();

        if (line.len != 0) {
            days_list.clearRetainingCapacity();

            // ignore errors
            const abbrev_len = process(gpa, line, &days_list, &day_char_indexes) catch continue;

            try stdout.print("{} ", .{abbrev_len});
            // // Print the utf8 abbreviations...
            // for (days_list.items, day_char_indexes) |day, idx_list|
            //     try stdout.print(" {s}", .{day[0..idx_list.items[abbrev_len - 1]]});

            // Print the days
            for (days_list.items) |day|
                try stdout.print(" {s}", .{day});
        }
        try stdout.writeByte('\n');
    }
    try stdout.flush();
}

fn readLine(reader: *Io.Reader, writer: *Io.Writer) !usize {
    const len = try reader.streamDelimiterEnding(writer, '\n');
    _ = reader.takeByte() catch |err| if (err == error.EndOfStream and len != 0) {} else return err;

    return len;
}

fn process(gpa: Allocator, line: []const u8, word_list: *std.ArrayList([]const u8), day_char_indexes: *[7]std.ArrayList(usize)) !usize {
    // -------------------------------------- get words from line
    var it = std.mem.tokenizeScalar(u8, line, ' ');
    while (it.next()) |word| {
        if (word_list.items.len == word_list.capacity)
            return error.TooManyWords;
        word_list.appendBounded(word) catch unreachable;
    }
    if (word_list.items.len != word_list.capacity) return error.InsufficientWords;

    const days = word_list.items;

    // -------------------------- max UTF-8 abbrev length
    for (day_char_indexes) |*list|
        list.clearRetainingCapacity();

    // Process utf8 characters. Does not handle grapheme clusters.
    const max_abbrev_len: usize = blk: {
        var len: usize = std.math.minInt(usize);
        for (days, 0..) |day, n| {
            var idx: usize = 0;
            var word_len: usize = 0;
            while (idx < day.len) {
                idx += try std.unicode.utf8ByteSequenceLength(day[idx]);
                day_char_indexes[n].append(gpa, idx) catch @panic("OOM");
                word_len += 1;
            }
            len = @max(len, word_len);
        }
        break :blk len;
    };
    // Pad all index lists to max_abbrev_len
    for (day_char_indexes) |*list| {
        const len = list.items.len;
        if (len < max_abbrev_len) {
            const last_item = list.items[list.items.len - 1];
            list.appendNTimes(gpa, last_item, max_abbrev_len - len) catch @panic("OOM");
        }
    }

    var abbrev_set: std.StringArrayHashMapUnmanaged(void) = .empty;
    defer abbrev_set.deinit(gpa);

    outer: for (0..max_abbrev_len) |n| {
        abbrev_set.clearRetainingCapacity();
        for (days, day_char_indexes, 1..) |day, indexes, i| {
            abbrev_set.put(gpa, day[0..indexes.items[n]], {}) catch @panic("OOM");
            if (abbrev_set.count() != i)
                continue :outer;
        }
        return n + 1; // Smallest abbreviation length
    }
    return error.FailedUniqueness;
}
