// https://rosettacode.org/wiki/Bioinformatics/Subsequence
const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;
const testing = std.testing;

pub fn main() !void {
    // --------------------------------------------- stdout
    const stdout = std.io.getStdOut().writer();
    // ------------------------------------------ allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------- pseudo random number generator
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();
    // ------------------- generate sequence & sub-sequence
    var generator = DnaGenerator.init(allocator, rand);

    const sequence = try generator.generate(200);
    defer generator.allocator.free(sequence);

    const subsequence = try generator.generate(4);
    defer generator.allocator.free(subsequence);
    // ---------------------- print sequence & sub-sequence
    try stdout.writeAll("SEQUENCE:\n");
    try printSequence(stdout, sequence);
    try stdout.print("Sub-sequence to locate: {s}\n", .{subsequence});
    // -------------------------------- locate sub-sequence
    const locations = try findDnaLocations(allocator, sequence, subsequence);
    defer allocator.free(locations);
    // ----------------------- print sub-sequence locations
    try printDnaLocations(stdout, locations);
}

fn printSequence(writer: anytype, sequence: []const u8) !void {
    const step = 40;
    var start: usize = 0;
    while (start < sequence.len) : (start += step) {
        const end = @min(start + step, sequence.len);
        try writer.print("{d:5}: {s}\n", .{ start, sequence[start..end] });
    }
    if (start < sequence.len)
        try writer.writeByte('\n');
}

fn printDnaLocations(writer: anytype, locations: []const usize) !void {
    if (locations.len == 0)
        try writer.writeAll("No matches found.\n")
    else {
        const singular = locations.len == 1;
        try writer.print(
            "Match{s} found at the following ind{s}:\n",
            if (singular) .{ "", "ex" } else .{ "es", "ices" },
        );
        for (locations) |pos|
            try writer.print(" {d:5}\n", .{pos});
    }
}

// Caller owns returned slice memory.
fn findDnaLocations(allocator: mem.Allocator, haystack: []const u8, needle: []const u8) ![]usize {
    var locations = std.ArrayList(usize).init(allocator);
    var start: usize = 0;
    while (mem.indexOf(u8, haystack[start..], needle)) |pos| {
        try locations.append(start + pos);
        start += pos + 1;
    }
    return locations.toOwnedSlice();
}

const DnaGenerator = struct {
    const bases = "ACGT";
    allocator: mem.Allocator,
    rand: std.Random,

    fn init(allocator: mem.Allocator, rand: std.Random) DnaGenerator {
        return DnaGenerator{
            .allocator = allocator,
            .rand = rand,
        };
    }

    // Caller owns returned slice memory.
    fn generate(self: DnaGenerator, count: usize) ![]const u8 {
        assert(count > 0);
        const sequence = try self.allocator.alloc(u8, count);
        for (sequence) |*base|
            base.* = bases[self.rand.uintLessThan(usize, bases.len)];
        return sequence;
    }
};

test "findDnaLocations" {
    const allocator = testing.allocator;
    const haystack = "ACACACAC";
    const needle = "ACAC";

    const result = try findDnaLocations(allocator, haystack, needle);
    defer allocator.free(result);

    try testing.expectEqual(3, result.len);
}
