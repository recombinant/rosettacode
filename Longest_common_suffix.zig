// https://rosettacode.org/wiki/Longest_common_suffix
// Translation of Go
const std = @import("std");
const math = std.math;
const mem = std.mem;
const print = std.debug.print;

pub fn main() void {
    const samples = [_][]const []const u8{
        &[_][]const u8{ "baabababc", "baabc", "bbbabc" },
        &[_][]const u8{ "baabababc", "baabc", "bbbazc" },
        &[_][]const u8{ "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" },
        &[_][]const u8{ "longest", "common", "suffix" },
        &[_][]const u8{"suffix"},
        &[_][]const u8{""},
    };
    for (samples) |sample| {
        print("{s} -> \"{s}\"\n", .{ sample, lcs(sample) });
    }
}

fn lcs(a: []const []const u8) []const u8 {
    const le = a.len;
    if (le == 0)
        return "";
    if (le == 1)
        return a[0];

    const le0 = a[0].len;

    var min_len: usize = math.maxInt(usize);
    for (a) |s|
        min_len = @min(min_len, s.len);
    if (min_len == 0)
        return "";

    var res: []const u8 = "";
    const a1 = a[1..];
    for (1..min_len + 1) |i| {
        const suffix = a[0][le0 - i ..];
        for (a1) |s|
            if (!mem.endsWith(u8, s, suffix))
                return res;
        res = suffix;
    }
    return res;
}
