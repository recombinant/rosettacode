// https://rosettacode.org/wiki/Consecutive_primes_with_ascending_or_descending_differences
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

// Using cpp primesieve from https://github.com/kimwalisch/primesieve/
const ps = @import("primesieve");

const LIMIT = 1_000_000;

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;

    var t0: Io.Timestamp = .now(io, .real);

    var it: ps.primesieve_iterator = undefined;
    ps.primesieve_init(&it);
    defer ps.primesieve_free_iterator(&it);

    var p1 = ps.primesieve_next_prime(&it);

    var inc = Sequence(.inc).init(gpa, p1);
    defer inc.deinit();
    var dec = Sequence(.dec).init(gpa, p1);
    defer dec.deinit();

    while (true) {
        const p2 = ps.primesieve_next_prime(&it);
        if (p2 >= LIMIT)
            break;

        inc.process(p1, p2);
        dec.process(p1, p2);

        p1 = p2;
    }
    std.log.info("processed in {f}", .{t0.untilNow(io, .real)});

    try inc.report(stdout);
    try dec.report(stdout);

    try stdout.flush();
}

const Direction = enum {
    inc,
    dec,
};

fn Sequence(comptime dir: Direction) type {
    return struct {
        allocator: Allocator,
        longest: std.ArrayList(u64) = .empty,
        current: std.ArrayList(u64) = .empty,
        diff: u64,

        const Self = @This();

        fn init(allocator: std.mem.Allocator, prime: u64) Self {
            var sequence: Self = .{
                .allocator = allocator,
                .diff = comptime if (dir == .inc) 0 else std.math.maxInt(u64),
            };
            sequence.current.append(allocator, prime) catch @panic("OOM");
            return sequence;
        }
        fn deinit(self: *Self) void {
            self.current.deinit(self.allocator);
            self.longest.deinit(self.allocator);
        }
        fn process(self: *Self, p1: u64, p2: u64) void {
            const diff = p2 - p1;
            const order = switch (dir) {
                .inc => std.math.order(diff, self.diff),
                .dec => std.math.order(self.diff, diff),
            };
            switch (order) {
                .eq, .lt => {
                    self.current.clearRetainingCapacity();
                    self.current.append(self.allocator, p1) catch @panic("OOM");
                    self.current.append(self.allocator, p2) catch @panic("OOM");
                },
                .gt => {
                    self.current.append(self.allocator, p2) catch @panic("OOM");
                    if (self.current.items.len > self.longest.items.len) {
                        self.longest.clearRetainingCapacity();
                        self.longest.appendSlice(self.allocator, self.current.items) catch @panic("OOM");
                    }
                },
            }
            self.diff = diff;
        }
        fn report(self: Self, w: *Io.Writer) !void {
            var p_prev: ?u64 = null;
            const direction: []const u8 = comptime switch (dir) {
                .inc => "Increasing",
                .dec => "Decreasing",
            };
            try w.print("\n{s} - {} primes in sequence:\n", .{ direction, self.longest.items.len });
            for (self.longest.items) |p| {
                if (p_prev) |p0|
                    try w.print("({}) ", .{p - p0});
                p_prev = p;
                try w.print("{} ", .{p});
            }
            try w.writeByte('\n');
        }
    };
}
