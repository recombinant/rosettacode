// https://rosettacode.org/wiki/Bioinformatics/Subsequence
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    // --------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ------------------------------------------ allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------- pseudo random number generator
    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();
    // ------------------- generate sequence & sub-sequence
    var generator: DnaGenerator = .init(allocator, rand);

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
    // --------------------------------------- flush stdout
    try stdout.flush();
}

fn printSequence(writer: *std.Io.Writer, sequence: []const u8) !void {
    const step = 40;
    var start: usize = 0;
    while (start < sequence.len) : (start += step) {
        const end = @min(start + step, sequence.len);
        try writer.print("{d:5}: {s}\n", .{ start, sequence[start..end] });
    }
    if (start < sequence.len)
        try writer.writeByte('\n');
}

fn printDnaLocations(writer: *std.Io.Writer, locations: []const usize) !void {
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
fn findDnaLocations(allocator: std.mem.Allocator, haystack: []const u8, needle: []const u8) ![]usize {
    var locations: std.ArrayList(usize) = .empty;
    var start: usize = 0;
    while (std.mem.indexOf(u8, haystack[start..], needle)) |pos| {
        try locations.append(allocator, start + pos);
        start += pos + 1;
    }
    return locations.toOwnedSlice(allocator);
}

const DnaGenerator = struct {
    const bases = "ACGT";
    allocator: std.mem.Allocator,
    rand: std.Random,

    fn init(allocator: std.mem.Allocator, rand: std.Random) DnaGenerator {
        return DnaGenerator{
            .allocator = allocator,
            .rand = rand,
        };
    }

    // Caller owns returned slice memory.
    fn generate(self: DnaGenerator, count: usize) ![]const u8 {
        std.debug.assert(count > 0);
        const sequence = try self.allocator.alloc(u8, count);
        for (sequence) |*base|
            base.* = bases[self.rand.uintLessThan(usize, bases.len)];
        return sequence;
    }
};

const testing = std.testing;

test "findDnaLocations" {
    const allocator = testing.allocator;
    const haystack = "ACACACAC";
    const needle = "ACAC";

    const result = try findDnaLocations(allocator, haystack, needle);
    defer allocator.free(result);

    try testing.expectEqual(3, result.len);
}
