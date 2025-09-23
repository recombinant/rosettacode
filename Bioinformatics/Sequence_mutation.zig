// https://rosettacode.org/wiki/Bioinformatics/Sequence_mutation
// {{works with|Zig|0.15.1}}
// {{trans|C++}}
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
    // ---------------------------------- generate sequence
    var generator: DnaGenerator = .init(allocator, rand);

    var sequence = try generator.generate(200);
    defer sequence.deinit();
    // ---------------------- print, mutate, print sequence
    try sequence.prettyPrint(stdout);
    try stdout.writeByte('\n');

    for (0..10) |_|
        try sequence.mutate();

    try stdout.writeByte('\n');
    try sequence.prettyPrint(stdout);
    // --------------------------------------- flush stdout
    try stdout.flush();
}

const DnaSequence = struct {
    allocator: std.mem.Allocator,
    rand: std.Random,
    sequence: []u8,

    fn deinit(self: *DnaSequence) void {
        self.allocator.free(self.sequence);
    }

    const Mutate = enum(u2) {
        swap = 0,
        delete = 1,
        insert = 2,
    };

    fn mutate(self: *DnaSequence) !void {
        const mutation: Mutate = @enumFromInt(self.rand.uintLessThan(u2, 3));
        switch (mutation) {
            .swap => self.mutateSwap(),
            .delete => try self.mutateDelete(),
            .insert => try self.mutateInsert(),
        }
    }

    fn mutateSwap(self: *DnaSequence) void {
        const index = self.rand.uintLessThan(usize, self.sequence.len);
        // 'A', 'C', 'G' or 'T'
        const base = DnaGenerator.bases[self.rand.uintLessThan(usize, DnaGenerator.bases.len)];
        std.log.debug("{d:5} swapped {c} for {c}", .{ index, self.sequence[index], base });
        self.sequence[index] = base;
    }
    fn mutateDelete(self: *DnaSequence) !void {
        const index = self.rand.uintLessThan(usize, self.sequence.len);
        // convert sequence slice to ArrayList for removal
        var array: std.ArrayList(u8) = .fromOwnedSlice(self.sequence);
        const c = array.orderedRemove(index);
        std.log.debug("{d:5} deleted {c}", .{ index, c });
        // convert ArrayList back to slice
        self.sequence = try array.toOwnedSlice(self.allocator);
    }
    fn mutateInsert(self: *DnaSequence) !void {
        // insertion can occur after the last element in self.sequence.
        const index = self.rand.uintAtMost(usize, self.sequence.len);
        // 'A', 'C', 'G' or 'T'
        const base = DnaGenerator.bases[self.rand.uintLessThan(usize, DnaGenerator.bases.len)];
        // convert sequence slice to ArrayList for insertion
        var array: std.ArrayList(u8) = .fromOwnedSlice(self.sequence);
        try array.insert(self.allocator, index, base);
        std.log.debug("{d:5} inserted {c}", .{ index, base });
        // convert ArrayList back to slice
        self.sequence = try array.toOwnedSlice(self.allocator);
    }

    /// Pretty print the sequence e.g.
    ///     0: AGATTGAGAC ACTTTCGCCG GTCCGGCGTT AATTACTACT GTTTGCCGAC
    ///    50: ACTGAACGAC CAGGGCCAAA AAGCACGCGC GTGTAGGCAA AAACGTTTCT
    ///   100: CAGACACGGT CCGACTTAAT TGTGCGGATG CGTAGGTATG CTCAGGGGGA
    ///   150: CTATCGCCAT TCATTTCCCG CAGAGCTGAC GAGCGCTCGT TCAATTACTT
    fn prettyPrint(self: *const DnaSequence, writer: *std.Io.Writer) !void {
        const step1 = 50;
        const step2 = 10;
        var start1: usize = 0;
        // split the sequence into lines of length "step1"
        while (start1 < self.sequence.len) : (start1 += step1) {
            const end1 = @min(start1 + step1, self.sequence.len);
            const line_slice = self.sequence[start1..end1];
            try writer.print("{d:5}:", .{start1});
            // split a line into space separated chunks of length "step2"
            var start2: usize = 0;
            while (start2 < line_slice.len) : (start2 += step2) {
                const end2 = @min(start2 + step2, line_slice.len);
                try writer.print(" {s}", .{line_slice[start2..end2]});
            }
            try writer.writeByte('\n');
        }
    }
};

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
    fn generate(self: DnaGenerator, count: usize) !DnaSequence {
        std.debug.assert(count > 0);
        const sequence = try self.allocator.alloc(u8, count);
        for (sequence) |*base|
            base.* = bases[self.rand.uintLessThan(usize, bases.len)];

        return DnaSequence{
            .allocator = self.allocator,
            .rand = self.rand,
            .sequence = sequence,
        };
    }
};
