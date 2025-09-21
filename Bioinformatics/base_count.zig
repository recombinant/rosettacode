// https://rosettacode.org/wiki/Bioinformatics/base_count
// {{works with|Zig|0.15.1}}
const std = @import("std");
const sort = std.sort;

const b =
    "CGTAAAAAATTACAACGTCCTTTGGCTATCTCTTAAACTCCTGCTAAATG" ++
    "CTCGTGCTTTCCAATTATGTAAGCGTTCCGAGACGGGGTGGTCGATTCTG" ++
    "AGGACAAAGGTCAAGATGGAGCGCATCGAACGCAATAAGGATCATTTGAT" ++
    "GGGACGTTTCGTCGACAAAGTCTTGTTTCGAGAGTAACGGCTACCGTCTT" ++
    "CGATTCTGCTTATAACACTATGTTCTTATGAAATGGATGTTCTGAGTTGG" ++
    "TCAGTCCCAATGTGCGGGGTTTCTTTTAGTACGTCGGGAGTGGTATTATA" ++
    "TTTAATTTTTCTATATAGCGATCTGTATTTAAGCAATTCATTTAGGTTAT" ++
    "CGCCGCGATGCTCGGTTCGGACCGCCAAGCATCTGGCTCCACTGCTAGTG" ++
    "TCCTAAATTTGAATGGCAAACACAAATAAGATTTAGCAATTCGTGTAGAC" ++
    "GACCGGGGACTTGCATGATGGGAGCAGCTTTGTTAAACTACGAACGTAAT";

pub fn main() !void {
    // --------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ------------------------------------- print sequence
    {
        try stdout.writeAll("SEQUENCE:\n");
        var start: usize = 0;
        while (start < b.len) : (start += 50) {
            const end = @min(start + 50, b.len);
            try stdout.print("{d:5}: {s}\n", .{ start, b[start..end] });
        }
        if (start < b.len)
            try stdout.writeByte('\n');
    }
    // ------------------------------------------ allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ----------------------------------------------------
    var basemap: std.AutoArrayHashMapUnmanaged(u8, u64) = .empty;
    defer basemap.deinit(allocator);
    for (b) |d| {
        const gop = try basemap.getOrPut(allocator, d);
        if (gop.found_existing)
            gop.value_ptr.* += 1
        else
            gop.value_ptr.* = 1;
    }
    // ----------------------------------------------------
    const bases = try allocator.dupe(u8, basemap.keys());
    defer allocator.free(bases);
    sort.heap(u8, bases, {}, sort.asc(u8));
    // ----------------------------------------------------
    try stdout.writeAll("\nBASE COUNT:\n");

    var sum: u64 = 0;
    for (bases) |base| {
        const count = basemap.get(base).?;
        try stdout.print("    {c}: {d:3}\n", .{ base, count });
        sum += count;
    }
    try stdout.writeAll("    ------\n");
    try stdout.print("    Σ: {d:3}\n", .{sum});
    try stdout.writeAll("    ======\n");
    // --------------------------------------- flush stdout
    try stdout.flush();
}
