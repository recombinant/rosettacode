// https://rosettacode.org/wiki/Levenshtein_distance
const std = @import("std");

/// Recursive method without memoization.
fn levenshtein(s: []const u8, t: []const u8) usize {
    // If either string is empty, difference is inserting all chars
    // from the other
    if (s.len == 0) return t.len;
    if (t.len == 0) return s.len;

    // If last letters are the same, the difference is whatever is
    // required to edit the rest of the strings
    if (s[s.len - 1] == t[t.len - 1])
        return levenshtein(s[0 .. s.len - 1], t[0 .. t.len - 1]);

    // Else try:
    //     changing last letter of s to that of t; or
    //     remove last letter of s; or
    //     remove last letter of t,
    // any of which is 1 edit plus editing the rest of the strings
    const a = levenshtein(s[0 .. s.len - 1], t[0 .. t.len - 1]);
    const b = levenshtein(s, t[0 .. t.len - 1]);
    const c = levenshtein(s[0 .. s.len - 1], t);

    return @min(a, @min(b, c)) + 1;
}

pub fn main() void {
    for ([_][2][]const u8{
        .{ "kitten", "sitting" },
        .{ "rosettacode", "raisethysword" },
    }) |pair| {
        const s1, const s2 = pair;
        std.debug.print("distance between `{s}' and `{s}': {}\n", .{ s1, s2, levenshtein(s1, s2) });
    }
}
