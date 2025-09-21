// https://rosettacode.org/wiki/Bioinformatics/Global_alignment
// {{works with|Zig|0.15.1}}
const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() !void {
    // ------------------------------------------ allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ------------------------------------- data from task
    const sequences_array = &[_][]const []const u8{
        &[_][]const u8{ "TA", "AAG", "TA", "GAA", "TA" },
        &[_][]const u8{ "CATTAGGG", "ATTAG", "GGG", "TA" },
        &[_][]const u8{ "AAGAUGGA", "GGAGCGCAUC", "AUCGCAAUAAGGA" },
        &[_][]const u8{
            "ATGAAATGGATGTTCTGAGTTGGTCAGTCCCAATGTGCGGGGTTTCTTTTAGTACGTCGGGAGTGGTATTAT",
            "GGTCGATTCTGAGGACAAAGGTCAAGATGGAGCGCATCGAACGCAATAAGGATCATTTGATGGGACGTTTCGTCGACAAAGT",
            "CTATGTTCTTATGAAATGGATGTTCTGAGTTGGTCAGTCCCAATGTGCGGGGTTTCTTTTAGTACGTCGGGAGTGGTATTATA",
            "TGCTTTCCAATTATGTAAGCGTTCCGAGACGGGGTGGTCGATTCTGAGGACAAAGGTCAAGATGGAGCGCATC",
            "AACGCAATAAGGATCATTTGATGGGACGTTTCGTCGACAAAGTCTTGTTTCGAGAGTAACGGCTACCGTCTT",
            "GCGCATCGAACGCAATAAGGATCATTTGATGGGACGTTTCGTCGACAAAGTCTTGTTTCGAGAGTAACGGCTACCGTC",
            "CGTTTCGTCGACAAAGTCTTGTTTCGAGAGTAACGGCTACCGTCTTCGATTCTGCTTATAACACTATGTTCT",
            "TGCTTTCCAATTATGTAAGCGTTCCGAGACGGGGTGGTCGATTCTGAGGACAAAGGTCAAGATGGAGCGCATC",
            "CGTAAAAAATTACAACGTCCTTTGGCTATCTCTTAAACTCCTGCTAAATGCTCGTGC",
            "GATGGAGCGCATCGAACGCAATAAGGATCATTTGATGGGACGTTTCGTCGACAAAGTCTTGTTTCGAGAGTAACGGCTACCGTCTTCGATT",
            "TTTCCAATTATGTAAGCGTTCCGAGACGGGGTGGTCGATTCTGAGGACAAAGGTCAAGATGGAGCGCATC",
            "CTATGTTCTTATGAAATGGATGTTCTGAGTTGGTCAGTCCCAATGTGCGGGGTTTCTTTTAGTACGTCGGGAGTGGTATTATA",
            "TCTCTTAAACTCCTGCTAAATGCTCGTGCTTTCCAATTATGTAAGCGTTCCGAGACGGGGTGGTCGATTCTGAGGACAAAGGTCAAGA",
        },
    };
    // ----------------------------------------------------
    for (sequences_array) |sequences| {
        const scs = try shortestCommonSuperstring(allocator, sequences);
        defer {
            for (scs) |s| allocator.free(s);
            allocator.free(scs);
        }
        for (scs) |s|
            try printCounts(allocator, s);
    }
}

/// Returns shortest common superstrings of a list of strings.
fn shortestCommonSuperstring(allocator: std.mem.Allocator, sequences: []const []const u8) ![][]const u8 {
    var ss = try deduplicate(allocator, sequences);
    defer allocator.free(ss);

    // There may be more than one string of the shortest length.
    var results: std.ArrayList([]const u8) = .empty;
    // Initialise using simple concatenation.
    try results.append(allocator, try std.mem.join(allocator, "", ss));

    // Only permutate when more than one deduplicated sequence remains.
    if (ss.len > 1) {
        var permutator = try Permutator([]const u8).init(allocator, ss);
        defer permutator.deinit();
        while (permutator.next()) {
            var sup = try allocator.dupe(u8, ss[0]);
            for (ss[1..]) |p|
                sup = try smash(allocator, sup, p);

            if (sup.len > results.items[0].len) {
                allocator.free(sup);
                continue; // too long, process next
            }

            if (sup.len < results.items[0].len) {
                for (results.items) |item|
                    allocator.free(item);
                results.clearAndFree(allocator);
            }
            // for both < and ==
            try results.append(allocator, sup);
        }
    }
    return results.toOwnedSlice(allocator);
}

/// Return `s` concatenated with `t`.
/// The longest suffix of `s` that matches a prefix of `t` will be removed.
/// Callee (this function) owns slice parameter `s` memory.
/// Caller owns returned slice memory.
fn smash(allocator: std.mem.Allocator, s: []u8, t: []const u8) ![]u8 {
    defer allocator.free(s);

    var a: std.Io.Writer.Allocating = .init(allocator);
    defer a.deinit();
    const w = &a.writer;

    for (1..s.len) |i|
        if (std.mem.startsWith(u8, t, s[i..])) {
            try a.ensureTotalCapacity(i + t.len);
            try w.writeAll(s[0..i]);
            try w.writeAll(t);
            return a.toOwnedSlice(); // s[:i] + t
        };
    try a.ensureTotalCapacity(s.len + t.len);
    try w.writeAll(s);
    try w.writeAll(t);
    return a.toOwnedSlice(); // s + t
}

/// Return the array of sequences with those that are a substring
/// of others removed.
fn deduplicate(allocator: std.mem.Allocator, sequences: []const []const u8) ![][]const u8 {
    var ss: [][]const u8 = try distinct(allocator, sequences);
    if (ss.len < 2)
        return ss; // must be allocated with "allocator"
    defer allocator.free(ss);

    var filtered: std.ArrayList([]const u8) = .empty;
    // sorted shortest to longest lengths
    std.mem.sort([]const u8, ss, {}, lessThanLength);
    for (ss[0 .. ss.len - 1], 0..) |shorter, i| {
        for (ss[i + 1 .. ss.len]) |longer| {
            if (std.mem.indexOf(u8, longer, shorter) != null)
                break;
        } else {
            try filtered.append(allocator, shorter); // not contained
        }
    }
    try filtered.append(allocator, ss[ss.len - 1]); // add longest
    return filtered.toOwnedSlice(allocator);
}

/// Returns all distinct elements from a list of strings.
/// Caller owns returned slice.
fn distinct(allocator: std.mem.Allocator, sequences: []const []const u8) ![][]const u8 {
    var set: std.StringArrayHashMapUnmanaged(void) = .empty;
    defer set.deinit(allocator);
    for (sequences) |s|
        try set.put(allocator, s, {});

    return try allocator.dupe([]const u8, set.keys());
}

fn printCounts(allocator: std.mem.Allocator, sequence: []const u8) !void {
    // ----------------------------------------------------
    var base_map: std.AutoArrayHashMapUnmanaged(u8, u64) = .empty;
    defer base_map.deinit(allocator);
    for (sequence) |base| {
        const gop = try base_map.getOrPut(allocator, base);
        if (gop.found_existing)
            gop.value_ptr.* += 1
        else
            gop.value_ptr.* = 1;
    }
    // ----------------------------------------------------
    const bases = [_]u8{ 'A', 'C', 'G', 'T' };
    // ----------------------------------------------------
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ----------------------------------------------------
    try stdout.print("\nNucleotide counts for {s}:\n", .{sequence});

    var sum: u64 = 0;
    for (bases) |base| {
        const count = base_map.get(base) orelse 0;
        try stdout.print("{c:10}{d:12}\n", .{ base, count });
        sum += count;
    }
    try stdout.print("{s:10}{d:12}\n", .{ "Other", sequence.len - sum });
    try stdout.writeAll("  ____________________\n");
    try stdout.print("{s:14}{d:8}\n\n", .{ "Total length", sequence.len });
    // ----------------------------------------------------
    try stdout.flush();
}

/// Iterative permutation with the slice to be permutated shadowing an index
/// array of the same size.
/// Refer Rosetta Code's Permutations.
fn Permutator(comptime T: type) type {
    return struct {
        const Self = @This();
        slice: []T,
        indices: []usize,
        remaining: usize,
        allocator: std.mem.Allocator,

        fn init(allocator: std.mem.Allocator, slice: []T) !Self {
            assert(slice.len < 21); // usize factorial limit
            const indices = try allocator.alloc(usize, slice.len);
            for (indices, 0..) |*index, n|
                index.* = n;
            // reverse so that the first call to next() has indices at 0, 1, 2 usw.
            std.mem.reverse(usize, indices);
            std.mem.reverse(T, slice);
            return Self{
                .slice = slice,
                .indices = indices,
                .remaining = factorial(slice.len),
                .allocator = allocator,
            };
        }
        fn deinit(self: *Self) void {
            self.allocator.free(self.indices);
        }

        /// Mutates array [supplied in .init()] in-place to provide next
        /// permutation. Returns true after the array has been mutated.
        /// Returns false when all possible permutations are exhausted.
        fn next(self: *Self) bool {
            if (self.remaining == 0)
                return false;
            // print("{any}\n", .{self.indices});
            self.remaining -= 1;
            var i = self.indices.len - 1;
            while (i > 0 and self.indices[i - 1] > self.indices[i])
                i -= 1;
            var j = i;
            var k = self.indices.len - 1;
            while (j < k) {
                std.mem.swap(usize, &self.indices[k], &self.indices[j]);
                std.mem.swap(T, &self.slice[k], &self.slice[j]);
                j += 1;
                k -= 1;
            }
            if (i == 0) {
                return true;
            } else {
                j = i;
            }
            while (self.indices[j] < self.indices[i - 1])
                j += 1;
            std.mem.swap(usize, &self.indices[j], &self.indices[i - 1]);
            std.mem.swap(T, &self.slice[j], &self.slice[i - 1]);
            return true;
        }

        fn factorial(n: usize) usize {
            var fact: usize = 1;
            for (2..n + 1) |i|
                fact *= i;
            return fact;
        }
    };
}

fn lessThanLength(_: void, lhs: []const u8, rhs: []const u8) bool {
    return lhs.len < rhs.len;
}

/// Returns whether the lexicographical order of `lhs` is lower than `rhs`.
fn lessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs) == .lt;
}

const testing = std.testing;

test deduplicate {
    const allocator = testing.allocator;

    {
        const sequences = [_][]const u8{ "TA", "AAG", "TA", "GAA", "TA" };

        const result = try deduplicate(allocator, sequences[0..]);
        defer allocator.free(result);
        std.mem.sort([]const u8, result, {}, lessThan);

        try testing.expectEqual(3, result.len);
        try testing.expectEqualStrings("AAG", result[0]);
        try testing.expectEqualStrings("GAA", result[1]);
        try testing.expectEqualStrings("TA", result[2]);
    }
    {
        const sequences = [_][]const u8{ "AAGAUGGA", "GGAGCGCAUC", "AUCGCAAGAUGGAA" };

        const result = try deduplicate(allocator, sequences[0..]);
        defer allocator.free(result);
        try testing.expectEqual(2, result.len);
    }
    {
        const sequences = [_][]const u8{ "CATTAGGG", "ATTAG", "GGG", "TA" };

        const result = try deduplicate(allocator, sequences[0..]);
        defer allocator.free(result);
        try testing.expectEqual(1, result.len);
        try testing.expectEqualStrings("CATTAGGG", result[0]);
    }
    {
        const sequences = [_][]const u8{ "ATA", "TA" };

        const result = try deduplicate(allocator, sequences[0..]);
        defer allocator.free(result);
        try testing.expectEqual(1, result.len);
        try testing.expectEqualStrings("ATA", result[0]);
    }
    {
        const sequences = [_][]const u8{"TA"};

        const result = try deduplicate(allocator, sequences[0..]);
        defer allocator.free(result);
        try testing.expectEqual(1, result.len);
        try testing.expectEqualStrings("TA", result[0]);
    }
    {
        const sequences = [_][]const u8{};

        const result = try deduplicate(allocator, sequences[0..]);
        defer allocator.free(result);
        try testing.expectEqual(0, result.len);
    }
}

test distinct {
    const allocator = testing.allocator;

    {
        const sequences = [_][]const u8{ "TA", "AAG", "TA", "GAA", "TA" };

        const result = try distinct(allocator, sequences[0..]);
        defer allocator.free(result);
        std.sort.heap([]const u8, result, {}, lessThan);

        try testing.expectEqual(3, result.len);
        try testing.expectEqualStrings("AAG", result[0]);
        try testing.expectEqualStrings("GAA", result[1]);
        try testing.expectEqualStrings("TA", result[2]);
    }
    {
        const sequences = [_][]const u8{ "TA", "TA" };

        const result = try distinct(allocator, sequences[0..]);
        defer allocator.free(result);
        try testing.expectEqual(1, result.len);
        try testing.expectEqualStrings("TA", result[0]);
    }
    {
        const sequences = [_][]const u8{"TA"};

        const result = try distinct(allocator, sequences[0..]);
        defer allocator.free(result);
        try testing.expectEqual(1, result.len);
        try testing.expectEqualStrings("TA", result[0]);
    }
    {
        const sequences = [_][]const u8{};

        const result = try distinct(allocator, sequences[0..]);
        defer allocator.free(result);
        try testing.expectEqual(0, result.len);
    }
}

test lessThanLength {
    var sequences = [_][]const u8{ "TA", "ATTAG", "CATTAGGG", "GGG", "TA" };

    std.mem.sort([]const u8, sequences[0..], {}, lessThanLength);
    try testing.expectEqual(8, sequences[4].len);
    try testing.expectEqual(5, sequences[3].len);
    try testing.expectEqual(3, sequences[2].len);
    try testing.expectEqual(2, sequences[1].len);
    try testing.expectEqual(2, sequences[0].len);
}

test shortestCommonSuperstring {
    const allocator = testing.allocator;

    {
        var sequences = [_][]const u8{ "abcbdab", "abdcaba" };

        const result = try shortestCommonSuperstring(allocator, sequences[0..]);

        defer {
            for (result) |s| allocator.free(s);
            allocator.free(result);
        }

        try testing.expectEqual(1, result.len);
        try testing.expectEqualStrings("abcbdabdcaba", result[0]);
    }
    {
        var sequences = [_][]const u8{ "TAG", "AGC" };

        const result = try shortestCommonSuperstring(allocator, sequences[0..]);

        defer {
            for (result) |s| allocator.free(s);
            allocator.free(result);
        }

        try testing.expectEqual(1, result.len);
        try testing.expectEqualStrings("TAGC", result[0]);
    }
    {
        var sequences = [_][]const u8{ "TTAGG", "GGATT" };

        const result = try shortestCommonSuperstring(allocator, sequences[0..]);
        std.mem.sort([]const u8, result, {}, lessThan);

        defer {
            for (result) |s| allocator.free(s);
            allocator.free(result);
        }

        try testing.expectEqual(2, result.len);
        try testing.expectEqualStrings("GGATTAGG", result[0]);
        try testing.expectEqualStrings("TTAGGATT", result[1]);
    }
}

test Permutator {
    const allocator = testing.allocator;

    var names = [_][]const u8{ "Alice", "Bob", "Charlie" };

    var count: usize = 0;
    var permutator = try Permutator([]const u8).init(allocator, names[0..]);
    defer permutator.deinit();
    while (permutator.next()) {
        count += 1;
        switch (count) {
            1 => {
                try testing.expectEqualStrings("Alice", names[0]);
                try testing.expectEqualStrings("Bob", names[1]);
                try testing.expectEqualStrings("Charlie", names[2]);
            },
            else => {
                // shouldn't see the above permutation again
                try testing.expect(!(std.mem.eql(u8, "Alice", names[0]) and std.mem.eql(u8, "Bob", names[1]) and std.mem.eql(u8, "Charlie", names[2])));
            },
        }
    }
    try testing.expectEqual(6, count);
}
