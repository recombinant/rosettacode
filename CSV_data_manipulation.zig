// http://rosettacode.org/wiki/CSV_data_manipulation
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

// Transliteration of C solution complete with design flaws
// e.g. CSV.open() does not check or reset the state of the CSV.

pub const TITLE = "CSV data manipulation";
pub const URL = "http://rosettacode.org/wiki/CSV_data_manipulation";

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;

    try stdout.print("{s}\n{s}\n\n", .{ TITLE, URL });

    const csv = CSV.create(gpa, 0, 0, .{});
    _ = try csv.open(io, "fixtures/csv-data-manipulation.csv");
    try csv.display(stdout);

    _ = csv.set(0, 0, "Column0");
    _ = csv.set(1, 1, "100");
    _ = csv.set(2, 2, "200");
    _ = csv.set(3, 3, "300");
    _ = csv.set(4, 4, "400");
    try csv.display(stdout);

    try csv.save(io, "tmp/csv-data-manipulation.result.csv");
    CSV.destroy(csv);

    try stdout.flush();
}

pub const CSVOptions = struct {
    delim: u8 = ',',
};

const CSV = struct {
    allocator: Allocator,
    delim: u8,
    rows: usize = 0,
    cols: usize = 0,
    table: []?[]const u8,

    fn init(gpa: Allocator, cols: usize, rows: usize, options: CSVOptions) CSV {
        const csv: CSV = .{
            .allocator = gpa,
            .rows = rows,
            .cols = cols,
            .delim = options.delim,
            .table = gpa.alloc(?[]const u8, rows * cols) catch @panic("OOM"),
        };
        @memset(csv.table, null);
        return csv;
    }
    fn deinit(self: *CSV) void {
        for (self.table) |content|
            if (content) |value|
                self.allocator.free(value);
        self.allocator.free(self.table);
    }
    /// Get value in CSV table at COL, ROW
    pub fn get(self: *CSV, col: usize, row: usize) ?[]const u8 {
        const idx = col + (row * self.cols);
        return self.table[idx];
    }
    /// Set value in CSV table at COL, ROW
    pub fn set(self: *CSV, col: usize, row: usize, content: ?[]const u8) void {
        const idx = col + (row * self.cols);

        if (self.table[idx]) |value|
            self.allocator.free(value);

        if (content) |value|
            self.table[idx] = self.allocator.dupe(u8, value) catch @panic("OOM")
        else
            self.table[idx] = null;
    }
    pub fn display(self: *CSV, w: *Io.Writer) !void {
        if (self.rows == 0 or self.cols == 0) {
            _ = try w.writeAll("[Empty table]\n");
            return;
        }
        _ = try w.print("\n[Table cols={d} rows={d}]\n", .{ self.cols, self.rows });

        for (0..self.rows) |row| {
            _ = try w.writeAll("[|");
            for (0..self.cols) |col| {
                const content = self.get(col, row) orelse "";
                _ = try w.print("{s}\t|", .{content});
            }
            _ = try w.writeAll("]\n");
        }
        _ = try w.writeByte('\n');
    }
    /// Resize CSV table
    pub fn resize(self: *CSV, cols: usize, rows: usize) void {
        std.debug.assert(cols >= self.cols and rows >= self.rows);
        if (cols == self.cols and rows == self.rows)
            return;

        const tmp: *CSV = self.allocator.create(CSV) catch @panic("OOM");
        tmp.* = .init(self.allocator, cols, rows, .{ .delim = self.delim });

        outer: for (0..rows) |row| {
            if (row == self.rows)
                break;
            for (0..cols) |col| {
                if (col == self.cols)
                    continue :outer;
                const content = self.get(col, row);
                if (content != null) {
                    tmp.set(col, row, content);
                    self.set(col, row, null);
                }
            }
        }
        self.deinit();
        self.* = tmp.*;
        self.allocator.destroy(tmp);
    }
    /// Open CSV file and load its content into provided CSV structure
    pub fn open(self: *CSV, io: Io, filename: []const u8) !void {
        const file = try std.Io.Dir.cwd().openFile(io, filename, .{});
        defer file.close(io);

        var buffer: [4096]u8 = undefined;
        var file_reader = file.reader(io, &buffer);
        const r = &file_reader.interface;

        var w: Io.Writer.Allocating = .init(self.allocator);
        defer w.deinit();

        var m_rows: usize = 0;
        var m_cols: usize = 0;

        while (true) : (w.clearRetainingCapacity()) {
            const n = try r.streamDelimiterEnding(&w.writer, '\n');
            if (n == 0)
                break;
            // consume the '\n' (or catch eof)
            _ = r.takeByte() catch |err| switch (err) {
                error.EndOfStream => {},
                else => return err,
            };
            m_rows += 1;
            var it = std.mem.tokenizeScalar(u8, w.written(), self.delim);

            var cols: usize = 0;
            while (it.next()) |token| {
                const trimmed = std.mem.trim(u8, token, &std.ascii.whitespace);
                cols += 1;
                if (cols > m_cols)
                    m_cols = cols;
                _ = self.resize(m_cols, m_rows);
                _ = self.set(cols - 1, m_rows - 1, trimmed);
            }
        }
        self.rows = m_rows;
        self.cols = m_cols;
    }
    /// Open CSV file and save CSV structure content into it
    pub fn save(self: *CSV, io: Io, filename: []const u8) !void {
        const file = try std.Io.Dir.cwd().createFile(io, filename, .{ .truncate = true });
        defer file.close(io);

        var buffer: [4096]u8 = undefined;
        var file_writer = file.writer(io, &buffer);
        const w = &file_writer.interface;

        for (0..self.rows) |row| {
            for (0..self.cols) |col| {
                _ = try w.writeAll(self.get(col, row) orelse "");
                if (col != self.cols - 1)
                    _ = try w.writeByte(self.delim);
            }
            _ = try w.writeAll("\r\n"); // rfc 4180
        }
        try w.flush();
    }

    /// Allocate memory for a CSV structure
    pub fn create(gpa: Allocator, cols: usize, rows: usize, options: CSVOptions) *CSV {
        const csv: *CSV = gpa.create(CSV) catch @panic("OOM");
        csv.* = CSV.init(gpa, cols, rows, options);
        return csv;
    }
    /// De-allocate csv structure
    pub fn destroy(csv: *CSV) void {
        const allocator: Allocator = csv.allocator;
        csv.deinit();
        allocator.destroy(csv);
    }
};
