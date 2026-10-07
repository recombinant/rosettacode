// https://rosettacode.org/wiki/Text_processing/Max_licenses_in_use
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

    const path = "data/mlijobs.txt";
    var file = try std.Io.Dir.cwd().openFile(io, path, .{});
    defer file.close(io);

    var buffer: [4096]u8 = undefined;
    var reader = file.reader(io, &buffer);

    var max_checkouts: MaxCheckouts = try getMaxCheckouts(gpa, &reader.interface);
    defer max_checkouts.deinit(gpa);

    try max_checkouts.write(stdout_writer);

    try stdout_writer.flush();
}

fn getMaxCheckouts(gpa: Allocator, r: *Io.Reader) !MaxCheckouts {
    var checkouts: usize = 0;
    var max_checkouts: MaxCheckouts = .empty;

    // Use csvzero, because it works and is fast
    const Iterator = csvz.Csv(.{ .delimiter = ' ' });
    var it = Iterator.init(r);

    // As the data is well defined - EOF is only checked
    // on the first field in a row.

    // Iterate rows.
    while (true) {
        // "License" or break while loop
        _ = it.next() catch |err| switch (err) {
            csvz.Iterator.Error.EOF => break,
            else => return err,
        };
        const inout = it.next() catch |err| return err;
        if (std.mem.eql(u8, "OUT", inout.data))
            checkouts += 1
        else {
            checkouts -= 1;
            // assume "IN" and take extra space
            _ = it.next() catch |err| return err;
        }
        // "@"
        _ = it.next() catch |err| return err;

        const time = it.next() catch |err| return err;

        // "for" "job" & job number
        _ = it.next() catch |err| return err;
        _ = it.next() catch |err| return err;
        const job_number = it.next() catch |err| return err;
        std.debug.assert(job_number.last_column);

        try max_checkouts.update(gpa, checkouts, time.data);
    }
    return max_checkouts;
}

const MaxCheckouts = struct {
    max: usize = 0,
    times: std.ArrayList([]const u8) = .empty,

    const empty: MaxCheckouts = .{};

    fn deinit(self: *MaxCheckouts, allocator: Allocator) void {
        self.clear(allocator);
        self.times.deinit(allocator);
    }
    fn clear(self: *MaxCheckouts, allocator: Allocator) void {
        for (self.times.items) |item| allocator.free(item);
        self.times.clearRetainingCapacity();
    }
    fn update(self: *MaxCheckouts, allocator: Allocator, checkouts: usize, time: []const u8) !void {
        if (checkouts > self.max) {
            self.max = checkouts;
            self.clear(allocator);
        }
        if (checkouts == self.max)
            try self.times.append(allocator, try allocator.dupe(u8, time));
    }
    fn write(self: *const MaxCheckouts, w: *Io.Writer) !void {
        for (self.times.items) |time|
            try w.print("{s} {}\n", .{ time, self.max });
    }
};
