// https://rosettacode.org/wiki/Compare_length_of_two_strings
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    compareStrings();
    compareStringsC();
    task2(); // extra credit
}

fn greaterThan(_: void, a: []const u8, b: []const u8) bool {
    return a.len > b.len;
}

/// Two Zig representations of ASCII strings
fn compareStrings() void {
    // Alternatives for declaring a string
    const string1 = "person";
    const string2: []const u8 = "hello";

    var list = [_][]const u8{ string1, string2 };
    std.mem.sort([]const u8, &list, {}, greaterThan);

    for (list) |s|
        print("{d}: {s}\n", .{ s.len, s });
    print("\n", .{});
}

fn greaterThanC(_: void, a: [*c]const u8, b: [*c]const u8) bool {
    return std.mem.span(a).len > std.mem.span(b).len;
}

/// Two C ASCII strings
fn compareStringsC() void {
    // Alternatives for declaring C null sentinel terminated strings
    const string1: [*:0]const u8 = "person";
    const string2: [*c]const u8 = "hello";
    // This also works
    // const string3 = "blue";

    var list = [_][*c]const u8{ string1, string2 };
    std.mem.sort([*c]const u8, &list, {}, greaterThanC);

    for (list) |s|
        print("{d}: {s}\n", .{ std.mem.span(s).len, s });
    print("\n", .{});
}

fn task2() void {
    var list = [4][]const u8{ "abcd", "123456789", "abcdef", "1234567" };
    std.mem.sort([]const u8, &list, {}, greaterThan);
    for (list) |s|
        print("{d}: {s}\n", .{ s.len, s });
}
