// https://rosettacode.org/wiki/Disarium_numbers
// {{works with|Zig|0.17.1}}
// {{trans|Crow}}
const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
// An n-digit number d1 d2 ... dn is a Disarium number when the sum over its positions of
// d^i - d * 10^(n - i) is 0: one independent term per position. Each length is searched a
// position at a time from the outside in (the first digits move the sum by their place, the
// last by their power), and a branch is cut when what the positions left can add cannot
// bring the sum back to 0. The innermost positions are not searched: a table of what they
// add, built once per length, answers them (meet in the middle). That finds all 20.

pub fn main(init: std.process.Init) !void {
    const allocator: Allocator = init.gpa;
    // // arena is approximately 5x faster than gpa
    // const allocator: Allocator = init.arena.allocator();
    const io: Io = init.io;

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    var t0: Io.Timestamp = .now(io, .real);

    var numbers: ArrayList(u64) = .empty;
    defer numbers.deinit(allocator);

    var n: usize = 1;
    while (numbers.items.len < 20) : (n += 1) {
        const batch = try getDisariumOfLength(allocator, n);
        defer allocator.free(batch);
        try numbers.appendSlice(allocator, batch);
    }

    const duration: Io.Duration = t0.untilNow(io, .real);

    try stdout.writeAll("The first 18 Disarium numbers:\n");
    try stdout.print("{}", .{numbers.items[0]});
    for (numbers.items[1..]) |number|
        try stdout.print(", {}", .{number});

    try stdout.writeAll("\n\nAll 20 Disarium numbers:\n");
    for (numbers.items) |x|
        try stdout.print("{d}\n", .{x});

    try stdout.flush();

    std.log.info("processed in {f}", .{duration});
}

fn getDisariumOfLength(allocator: Allocator, n: usize) ![]u64 {
    var searcher: Search = try .init(allocator, n);
    defer searcher.deinit(allocator);

    var found: ArrayList(u64) = .empty;
    errdefer found.deinit(allocator);

    try searcher.search(allocator, 0, 0, 0, &found);
    std.mem.sort(u64, found.items, {}, std.sort.asc(u64));
    return try found.toOwnedSlice(allocator);
}

const InnerTable = std.AutoHashMap(i128, ArrayList(u64));

/// The outer places in search order, the least and the most the places from
/// the j-th on can add, and the inner places' table.
const Search = struct {
    places: []Place,
    low: []i128,
    high: []i128,
    table: InnerTable,

    fn init(allocator: Allocator, n: usize) !Search {
        const order = try getOutsideIn(allocator, n);
        defer allocator.free(order);

        const inner_count: usize = @max(1, @min(n / 3, 6));
        const outer_count: usize = n - inner_count;

        const outer = try allocator.alloc(Place, outer_count);
        errdefer allocator.free(outer);
        const inner = try allocator.alloc(Place, inner_count);
        defer allocator.free(inner);

        for (outer, order[0..outer_count]) |*p, o|
            p.* = .init(n, o);
        for (inner, order[outer_count..]) |*p, o|
            p.* = .init(n, o);

        var lo: i128 = 0;
        var hi: i128 = 0;
        for (inner) |*p| {
            lo += p.minTerm();
            hi += p.maxTerm();
        }
        const lows = try allocator.alloc(i128, outer_count + 1);
        errdefer allocator.free(lows);
        const highs = try allocator.alloc(i128, outer_count + 1);
        errdefer allocator.free(highs);

        lows[outer_count] = lo;
        highs[outer_count] = hi;

        var k: usize = outer_count;
        while (k > 0) {
            k -= 1;
            lo += outer[k].minTerm();
            hi += outer[k].maxTerm();
            lows[k] = lo;
            highs[k] = hi;
        }
        const table = try buildInnerTable(allocator, inner);
        return .{
            .places = outer,
            .low = lows,
            .high = highs,
            .table = table,
        };
    }
    fn deinit(self: *Search, allocator: Allocator) void {
        allocator.free(self.places);
        allocator.free(self.low);
        allocator.free(self.high);

        var it = self.table.valueIterator();
        while (it.next()) |list|
            list.deinit(allocator);
        self.table.deinit();
    }
    /// Recursively search outer places and match against the inner lookup
    /// table. The Disarium numbers whose outer places from the j-th on are
    /// still to choose: the terms chosen so far add up to `partial`, their
    /// digits to `number`
    fn search(
        self: *const Search,
        allocator: Allocator,
        j: usize,
        partial: i128,
        number: u64,
        found: *ArrayList(u64),
    ) !void {
        if (j == self.places.len) {
            if (self.table.get(-partial)) |rests|
                for (rests.items) |rest|
                    try found.append(allocator, number + rest);
            return;
        }
        const p = &self.places[j];
        const low = self.low[j + 1];
        const high = self.high[j + 1];

        for (0..p.count) |k| {
            const t = partial + p.terms[k];
            if (t + low <= 0 and t + high >= 0)
                try search(self, allocator, j + 1, t, number + p.numbers[k], found);
        }
    }
    /// Build a hash map of every sum the inner places can make, paired with their number suffixes
    fn buildInnerTable(allocator: Allocator, inner: []const Place) !InnerTable {
        var sums: ArrayList(i128) = .empty;
        defer sums.deinit(allocator);
        var numbers: ArrayList(u64) = .empty;
        defer numbers.deinit(allocator);

        try sums.appendSlice(allocator, inner[0].terms[0..inner[0].count]);
        try numbers.appendSlice(allocator, inner[0].numbers[0..inner[0].count]);

        for (inner[1..]) |p| {
            const capacity = sums.items.len * p.count;

            var grown_sums: ArrayList(i128) = try .initCapacity(allocator, capacity);
            errdefer grown_sums.deinit(allocator);
            var grown_numbers: ArrayList(u64) = try .initCapacity(allocator, capacity);
            errdefer grown_numbers.deinit(allocator);

            for (sums.items, numbers.items) |s, num|
                for (0..p.count) |j| {
                    grown_sums.appendAssumeCapacity(s + p.terms[j]);
                    grown_numbers.appendAssumeCapacity(num + p.numbers[j]);
                };
            sums.deinit(allocator);
            numbers.deinit(allocator);
            sums = grown_sums;
            numbers = grown_numbers;
        }
        var table: InnerTable = .init(allocator);
        errdefer {
            var it = table.valueIterator();
            while (it.next()) |list| list.deinit(allocator);
            table.deinit();
        }
        for (sums.items, numbers.items) |s, num| {
            const gop = try table.getOrPut(s);
            if (!gop.found_existing)
                gop.value_ptr.* = .empty;
            try gop.value_ptr.append(allocator, num);
        }

        return table;
    }
};

const Place = struct {
    count: usize,
    terms: [10]i128,
    numbers: [10]u64,

    fn init(n: usize, i: usize) Place {
        var p: Place = .{
            .count = 0,
            .terms = undefined,
            .numbers = undefined,
        };
        const first: usize = if (i == 1 and n > 1) 1 else 0;
        const weight: u64 = std.math.pow(u64, 10, @intCast(n - i));

        for (first..10) |d| {
            const num, const ov = @mulWithOverflow(@as(u64, @truncate(d)), weight);
            if (ov == 1) break;
            const pwr: i128 = std.math.pow(i128, @intCast(d), @intCast(i));
            p.terms[p.count] = pwr - @as(i128, num);
            p.numbers[p.count] = num;
            p.count += 1;
        }
        return p;
    }
    fn minTerm(self: *const Place) i128 {
        return std.mem.min(i128, self.terms[0..self.count]);
    }
    fn maxTerm(self: *const Place) i128 {
        return std.mem.max(i128, self.terms[0..self.count]);
    }
};

/// Return positions ordered from the outside in: 1, n, 2, n - 1, ...
fn getOutsideIn(allocator: Allocator, n: usize) ![]usize {
    const order = try allocator.alloc(usize, n);
    var lo: usize = 1;
    var hi: usize = n;
    var idx: usize = 0;

    while (lo <= hi) {
        order[idx] = lo;
        idx += 1;
        if (hi != lo) {
            order[idx] = hi;
            idx += 1;
        }
        lo += 1;
        hi -= 1;
    }
    return order;
}

// --------------------------------------------------------------
// -------------------------------------------------------- tests

/// Brute force check for use with testing
fn isDisarium(num: u64) bool {
    var n = num;
    var sum: u64 = 0;
    var len = if (n <= 9) 1 else std.math.log_int(u64, 10, n) + 1;
    while (n > 0) {
        sum += std.math.pow(u64, n % 10, len);
        n /= 10;
        len -= 1;
    }
    return num == sum;
}

const testing = std.testing;

test isDisarium {
    try testing.expect(isDisarium(0));
    try testing.expect(isDisarium(89));
    try testing.expect(isDisarium(135));
    try testing.expect(isDisarium(12_157_692_622_039_623_539));

    try testing.expect(!isDisarium(10));
    try testing.expect(!isDisarium(88));
    try testing.expect(!isDisarium(136));
}

test getOutsideIn {
    const allocator = testing.allocator;

    const sequence0 = try getOutsideIn(allocator, 0);
    defer allocator.free(sequence0);
    try testing.expectEqualSlices(usize, &.{}, sequence0);

    const sequence1 = try getOutsideIn(allocator, 1);
    defer allocator.free(sequence1);
    try testing.expectEqualSlices(usize, &.{1}, sequence1);

    const sequence2 = try getOutsideIn(allocator, 2);
    defer allocator.free(sequence2);
    try testing.expectEqual(2, sequence2.len);
    try testing.expectEqualSlices(u64, &.{ 1, 2 }, sequence2);

    const sequence3 = try getOutsideIn(allocator, 3);
    defer allocator.free(sequence3);
    try testing.expectEqualSlices(u64, &.{ 1, 3, 2 }, sequence3);

    const sequence4 = try getOutsideIn(allocator, 4);
    defer allocator.free(sequence4);
    try testing.expectEqualSlices(usize, &.{ 1, 4, 2, 3 }, sequence4);

    const sequence5 = try getOutsideIn(allocator, 5);
    defer allocator.free(sequence5);
    try testing.expectEqualSlices(usize, &.{ 1, 5, 2, 4, 3 }, sequence5);

    for (2..999) |n| {
        const sequence_n = try getOutsideIn(allocator, @intCast(n));
        defer allocator.free(sequence_n);
        try testing.expectEqual(n, sequence_n.len);
        try testing.expectEqual(1, sequence_n[0]);
        try testing.expectEqual(n, sequence_n[1]);
        try testing.expectEqual(n / 2 + 1, sequence_n[n - 1]);
    }
}

test Place {
    // 1-digit number allows 0..9
    const single: Place = .init(1, 1);
    try testing.expectEqual(@as(usize, 10), single.count);
    try testing.expectEqual(@as(i128, 0), single.terms[0]);
    try testing.expectEqual(@as(u64, 0), single.numbers[0]);

    // Multi-digit leading position (i = 1, n = 3) allows 1..9
    const leading: Place = .init(3, 1);
    try testing.expectEqual(@as(usize, 9), leading.count);
    try testing.expectEqual(@as(u64, 100), leading.numbers[0]);
    try testing.expectEqual(@as(i128, -99), leading.terms[0]); // 1^1 - 100

    // Inner position (i = 3, n = 3) allows 0..9
    const trailing: Place = .init(3, 3);
    try testing.expectEqual(@as(usize, 10), trailing.count);
    try testing.expectEqual(@as(i128, 720), trailing.terms[9]); // 9^3 - 9 = 729 - 9
}

test getDisariumOfLength {
    const allocator = testing.allocator;

    // 1-digit Disarium numbers: 0..9
    const len1 = try getDisariumOfLength(allocator, 1);
    defer allocator.free(len1);
    try testing.expectEqualSlices(u64, &.{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }, len1);

    // 2-digit Disarium numbers: only 89
    const len2 = try getDisariumOfLength(allocator, 2);
    defer allocator.free(len2);
    try testing.expectEqualSlices(u64, &.{89}, len2);

    // 3-digit Disarium numbers: 135, 175, 518, 598
    const len3 = try getDisariumOfLength(allocator, 3);
    defer allocator.free(len3);
    try testing.expectEqualSlices(u64, &.{ 135, 175, 518, 598 }, len3);

    // 5-digit Disarium numbers: none exist
    const len5 = try getDisariumOfLength(allocator, 5);
    defer allocator.free(len5);
    try testing.expectEqual(@as(usize, 0), len5.len);
}
