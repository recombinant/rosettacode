// https://rosettacode.org/wiki/String_matching
// {{works with|Zig|0.15.1}}
const std = @import("std");

const print = std.debug.print;

pub fn main() void {
    // 1. first string starts with second string
    print("{}\n", .{std.mem.startsWith(u8, "abcd", "ab")});
    // 2. first string contains the second string at any location
    print("{}\n", .{std.mem.containsAtLeast(u8, "abab", 1, "bb")});
    print("{}\n", .{std.mem.containsAtLeast(u8, "abcd", 1, "bc")});
    // 3. first string ends with the second string
    print("{}\n", .{std.mem.endsWith(u8, "abcd", "zn")});
    print("\n", .{});
    //
    // Optional 1. location of the match for part 2
    print("{?}\n", .{std.mem.indexOf(u8, "abab", "bb")}); // null, not found
    print("{?}\n", .{std.mem.indexOf(u8, "abcd", "bc")});
    print("\n", .{});
    //
    // Optional 2. multiple occurrences of a string for part 2
    const haystack = "a skunk sat on a stump and thunk the stump stunk, but the stump thunk the skunk stunk";
    const needle = "unk";
    print("{}:", .{std.mem.count(u8, haystack, needle)});
    var pos: usize = 0;
    while (std.mem.indexOfPos(u8, haystack, pos, needle)) |pos_| {
        print(" {}", .{pos_});
        pos = pos_ + 1;
    }
    print("\n", .{});
}
