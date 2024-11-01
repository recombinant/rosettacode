// https://rosettacode.org/wiki/String_matching
const std = @import("std");
const mem = std.mem;

const print = std.debug.print;

pub fn main() void {
    // 1. first string starts with second string
    print("{}\n", .{mem.startsWith(u8, "abcd", "ab")});
    // 2. first string contains the second string at any location
    print("{}\n", .{mem.containsAtLeast(u8, "abab", 1, "bb")});
    print("{}\n", .{mem.containsAtLeast(u8, "abcd", 1, "bc")});
    // 3. first string ends with the second string
    print("{}\n", .{mem.endsWith(u8, "abcd", "zn")});
    print("\n", .{});
    //
    // Optional 1. location of the match for part 2
    print("{?}\n", .{mem.indexOf(u8, "abab", "bb")}); // null, not found
    print("{?}\n", .{mem.indexOf(u8, "abcd", "bc")});
    print("\n", .{});
    //
    // Optional 2. multiple occurrences of a string for part 2
    const haystack = "a skunk sat on a stump and thunk the stump stunk, but the stump thunk the skunk stunk";
    const needle = "unk";
    print("{}:", .{mem.count(u8, haystack, needle)});
    var pos: usize = 0;
    while (mem.indexOfPos(u8, haystack, pos, needle)) |pos_| {
        print(" {}", .{pos_});
        pos = pos_ + 1;
    }
    print("\n", .{});
}
