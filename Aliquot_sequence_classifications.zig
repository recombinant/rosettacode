// https://rosettacode.org/wiki/Aliquot_sequence_classifications
const std = @import("std");
const math = std.math;
const mem = std.mem;

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var t0 = try std.time.Timer.start();

    for (1..11) |n| {
        const result = try classification(allocator, n);
        defer allocator.free(result.sequence);
        try stdout.print("{d:14}: {s:<15} {any}\n", .{ n, result.category.string(), result.sequence });
    }

    try stdout.writeByte('\n');

    const numbers = [_]u64{
        11,      12,  28,  496, 220,  1184, 12496,
        1264460, 790, 909, 562, 1064, 1488, 15355717786080,
    };
    for (numbers) |n| {
        const result = try classification(allocator, n);
        defer allocator.free(result.sequence);
        try stdout.print("{d:14}: {s:<15} {any}\n", .{ n, result.category.string(), result.sequence });
    }

    try stdout.writeByte('\n');
    try stdout.print("Processed in {}\n", .{std.fmt.fmtDuration(t0.read())});

    try bw.flush();
}

//  Classification categories.
const Category = enum {
    unknown,
    terminating,
    perfect,
    amicable,
    sociable,
    aspiring,
    cyclic,
    non_terminating,

    /// Limit beyond which the category is considered to be "non_terminating".
    const limit = math.pow(u64, 2, 47);

    fn string(category: Category) []const u8 {
        return switch (category) {
            .unknown => "Unknown",
            .terminating => "Terminating",
            .perfect => "Perfect",
            .amicable => "Amicable",
            .sociable => "Sociable",
            .aspiring => "Aspiring",
            .cyclic => "Cyclic",
            .non_terminating => "Non-Terminating",
        };
    }
};

/// Compute the sum of proper divisors.
fn sumProperDivisors(n: u64) u64 {
    if (n == 1) return 0;
    var result: u64 = 1;
    for (2..math.sqrt(n) + 1) |d| {
        if ((n % d) == 0) {
            result += d;
            if (n / d != d)
                result += n / d;
        }
    }
    return result;
}

/// Iterate the elements of the Aliquot Sequence of "n".
fn iterateAliquotSequence(n: u64) AliquotSequenceIterator {
    return AliquotSequenceIterator{ .k = n };
}

const AliquotSequenceIterator = struct {
    k: ?u64,

    fn next(self: *AliquotSequenceIterator) ?u64 {
        var result: ?u64 = self.k;
        if (self.k) |k| {
            result = sumProperDivisors(k);
            self.k = if (result == 0) null else result;
        }
        return result;
    }
};

/// Return the category of the Aliquot Sequence of a number "n" and the sequence itself.
/// Caller owns returned slice memory for "sequence".
fn classification(allocator: mem.Allocator, n: u64) !struct { category: Category, sequence: []u64 } {
    var count: usize = 0;
    var previous = n;
    var category = Category.unknown;
    var sequence = std.ArrayList(u64).init(allocator);

    var it = iterateAliquotSequence(n);
    while (it.next()) |k| {
        count += 1;
        if (k == 0)
            category = Category.terminating
        else if (k == n)
            category = switch (count) {
                1 => Category.perfect,
                2 => Category.amicable,
                else => Category.sociable,
            }
        else if (k > Category.limit or count > 16)
            category = Category.non_terminating
        else if (k == previous)
            category = Category.aspiring
        else if (mem.indexOfScalar(u64, sequence.items, k) != null)
            category = Category.cyclic;
        previous = k;
        try sequence.append(k);
        if (category != Category.unknown)
            break;
    }
    // Caller owns and should free memory slice .sequence.
    return .{ .category = category, .sequence = try sequence.toOwnedSlice() };
}
