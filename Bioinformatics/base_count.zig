// https://rosettacode.org/wiki/Bioinformatics/base_count
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
    const stdout = std.io.getStdOut().writer();

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
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ----------------------------------------------------
    var basemap = std.AutoArrayHashMap(u8, u64).init(allocator);
    defer basemap.deinit();
    for (b) |d| {
        const gop = try basemap.getOrPut(d);
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
}
