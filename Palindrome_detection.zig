// https://rosettacode.org/wiki/Palindrome_detection
const std = @import("std");
const ascii = std.ascii;
const print = std.debug.print;
const testing = std.testing;

pub fn main() !void {
    const words = [_][]const u8{
        "noon",
        "rotor",
        "racecar",
        "rosetta",
    };
    for (words) |word|
        print("{s}: {}\n", .{ word, isPalindrome(word) });
}

fn isPalindrome2(s: []const u8) bool {
    var i: usize = 0;
    const end = s.len / 2;
    while (i < end) : (i += 1)
        if (s[i] != s[s.len - i - 1]) return false;

    return true;
}
fn isPalindrome3(s: []const u8) bool {
    var j = s.len;
    if (j < 1) return true;

    for (s[0 .. s.len / 2]) |c| {
        j -= 1;
        if (c != s[j])
            return false;
    }
    return true;
}

fn isPalindrome(s: []const u8) bool {
    if (s.len < 2) return true;
    var low: usize = 0;
    var high = s.len - 1;
    while (low < high) {
        if (!ascii.isAlphabetic(s[low]))
            low += 1
        else if (!ascii.isAlphabetic(s[high]))
            high -= 1
        else {
            if (ascii.toLower(s[low]) != ascii.toLower(s[high]))
                return false
            else {
                low += 1;
                high -= 1;
            }
        }
    }
    return true;
}

test "test palindrome" {
    const expect = testing.expect;
    try expect(isPalindrome("INGIRUMIMUSNOCTEETCONSUMIMURIGNI"));
    try expect(isPalindrome(""));
    try expect(isPalindrome("a"));
    try expect(isPalindrome("noon"));
    try expect(isPalindrome("rotor"));
    try expect(isPalindrome("racecar"));
    try expect(isPalindrome("level"));
    try expect(!isPalindrome("ravecar"));
    try expect(!isPalindrome("rosetta"));

    try expect(isPalindrome2("INGIRUMIMUSNOCTEETCONSUMIMURIGNI"));
    try expect(isPalindrome2(""));
    try expect(isPalindrome2("a"));
    try expect(isPalindrome2("noon"));
    try expect(isPalindrome2("rotor"));
    try expect(isPalindrome2("racecar"));
    try expect(isPalindrome2("level"));
    try expect(!isPalindrome2("ravecar"));
    try expect(!isPalindrome2("rosetta"));

    try expect(isPalindrome3("INGIRUMIMUSNOCTEETCONSUMIMURIGNI"));
    try expect(isPalindrome3(""));
    try expect(isPalindrome3("a"));
    try expect(isPalindrome3("noon"));
    try expect(isPalindrome3("rotor"));
    try expect(isPalindrome3("racecar"));
    try expect(isPalindrome3("level"));
    try expect(!isPalindrome3("ravecar"));
    try expect(!isPalindrome3("rosetta"));
}
