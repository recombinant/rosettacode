// https://rosettacode.org/wiki/Jaro_similarity
// Translation of C (keeping comments)
const std = @import("std");
const mem = std.mem;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();

    try stdout.print("{d:.6}\n", .{try jaro(allocator, "MARTHA", "MARHTA")});
    try stdout.print("{d:.6}\n", .{try jaro(allocator, "DIXON", "DICKSONX")});
    try stdout.print("{d:.6}\n", .{try jaro(allocator, "JELLYFISH", "SMELLYFISH")});
}

fn jaro(allocator: mem.Allocator, str1: []const u8, str2: []const u8) !f64 {
    // if both strings are empty return 1
    // if only one of the strings is empty return 0
    if (str1.len == 0 and str2.len == 0) return 1;
    if (str1.len == 0 or str2.len == 0) return 0;

    // max distance between two chars to be considered matching
    // floor() is ommitted due to integer division rules
    const match_distance = @max(str1.len, str2.len) / 2 - 1;

    // arrays of bools that signify if that char in the matching string has a match
    var str1_matches = try std.DynamicBitSet.initEmpty(allocator, str1.len);
    defer str1_matches.deinit();

    var str2_matches = try std.DynamicBitSet.initEmpty(allocator, str2.len);
    defer str2_matches.deinit();

    // find the matches
    var matches: f64 = 0;
    for (0..str1.len) |i| {
        // start and end take into account the match distance
        // max(0, i - match_distance)
        const start: usize = if (match_distance >= i) 0 else i - match_distance;
        const end: usize = @min(i + match_distance + 1, str2.len);
        for (start..end) |j| {
            // if str2 already has a match continue
            if (str2_matches.isSet(j))
                continue;
            // if str1 and str2 are not a match
            if (str1[i] != str2[j])
                continue;
            // assume that there is a match
            str1_matches.set(i);
            str2_matches.set(j);
            matches += 1;
            break;
        }
    }

    // if there are no matches return 0
    if (matches == 0)
        return 0;

    // count transpositions
    var transpositions: f64 = 0;
    var k: usize = 0;
    for (0..str1.len) |i| {
        // if there are no matches in str1 continue
        if (!str1_matches.isSet(i))
            continue;
        // while there is no match in str2 increment k
        while (!str2_matches.isSet(k))
            k += 1;
        // increment transpositions
        if (str1[i] != str2[k])
            transpositions += 1;
        k += 1;
    }

    // (faithful to the C original)
    // divide the number of transpositions by two as per the algorithm specs
    // this division is valid because the counted transpositions include both
    // instances of the transposed characters.
    transpositions /= 2;

    const len1: f64 = @floatFromInt(str1.len);
    const len2: f64 = @floatFromInt(str2.len);
    // return the Jaro distance
    return (matches / len1 + matches / len2 + (matches - transpositions) / matches) / 3;
}
