// https://rosettacode.org/wiki/Consecutive_primes_with_ascending_or_descending_differences
// {{works with|Zig|0.15.1}}
// {{trans|Wren}}
const std = @import("std");

const LIMIT = 1_000_000;

pub fn main() !void {
    // ------------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ---------------------------------------------------- allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------
    var t0: std.time.Timer = try .start();

    try stdout.writeAll("For primes < 1 million:\n");
    try printLongestSequence(allocator, .ascending, stdout);
    try printLongestSequence(allocator, .descending, stdout);
    // ------------------------------------------------------- stdout
    try stdout.flush();
    // --------------------------------------------------------------
    std.log.info("processed in {D}", .{t0.read()});
}

const Dir = enum { ascending, descending };

fn printLongestSequence(allocator: std.mem.Allocator, dir: Dir, w: *std.Io.Writer) !void {
    const primes = blk: {
        var primes: std.ArrayList(usize) = .empty;
        for (sieve(LIMIT), 0..) |b, n|
            if (b)
                try primes.append(allocator, n);
        break :blk try primes.toOwnedSlice(allocator);
    };

    var current_sequence: std.ArrayList(usize) = .empty;
    try current_sequence.append(allocator, 2);

    var longest_sequences: LongestSequences = try .init(allocator);
    try longest_sequences.candidate(current_sequence.items);

    var pd: usize = 0;
    for (primes[1..], primes[0 .. primes.len - 1]) |p1, p0| {
        const d = p1 - p0;
        if ((dir == .ascending and d <= pd) or (dir == .descending and d >= pd)) {
            try longest_sequences.candidate(current_sequence.items);
            current_sequence.clearRetainingCapacity();
            try current_sequence.append(allocator, p0);
        }
        try current_sequence.append(allocator, p1);
        pd = d;
    }
    try longest_sequences.candidate(current_sequence.items);

    const plural: []const u8 = if (longest_sequences.len == 1) "" else "s";
    try w.print(
        "Longest run{s} of primes with {s} differences is {}:\n",
        .{ plural, @tagName(dir), longest_sequences.len },
    );
    for (longest_sequences.get()) |ls| {
        for (ls[1..], ls[0 .. ls.len - 1]) |p1, p0| {
            const diff = p1 - p0;
            try w.print("{d} ({d}) ", .{ p0, diff });
        }
        try w.print("{d}\n", .{ls[ls.len - 1]});
    }
    try w.writeByte('\n');

    longest_sequences.deinit();
    current_sequence.deinit(allocator);
    allocator.free(primes);
}

const LongestSequences = struct {
    allocator: std.mem.Allocator,
    sequences: std.ArrayList([]const usize),
    len: usize = 0,

    fn init(allocator: std.mem.Allocator) !LongestSequences {
        return LongestSequences{
            .allocator = allocator,
            .sequences = .empty,
        };
    }
    fn deinit(self: *LongestSequences) void {
        self.clear();
        self.sequences.deinit(self.allocator);
    }
    fn candidate(self: *LongestSequences, sequence: []const usize) !void {
        if (sequence.len < self.len)
            return;
        if (sequence.len > self.len) {
            self.clear();
            self.len = sequence.len;
        }
        try self.sequences.append(self.allocator, try self.allocator.dupe(usize, sequence));
    }
    fn clear(self: *LongestSequences) void {
        for (self.sequences.items) |sequence|
            self.allocator.free(sequence);
        self.sequences.clearRetainingCapacity();
    }
    /// Return the longest sequences.
    fn get(self: *LongestSequences) []const []const usize {
        return self.sequences.items;
    }
};

/// Simple sieve of Eratothenes.
/// true denotes prime, false denotes composite.
fn sieve(comptime limit: usize) [limit]bool {
    @setEvalBranchQuota(limit * 2);
    var array: [limit]bool = undefined;
    @memset(&array, true);
    array[0] = false; // zero is not prime
    array[1] = false; // one is not prime
    var i: usize = 4;
    while (i < limit) : (i += 2)
        array[i] = false; // even numbers are composite
    var p: usize = 3;
    while (true) {
        const p2 = p * p;
        if (p2 >= limit) break;
        i = p2;
        while (i < limit) : (i += 2 * p)
            array[i] = false;
        while (true) {
            p += 2;
            if (array[p])
                break;
        }
    }
    return array;
}
