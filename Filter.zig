// https://rosettacode.org/wiki/Filter
const std = @import("std");

/// Returns slice of `output`
fn filter(comptime T: type, context: anytype, output: []T, unfiltered: []const T, predicate: fn (@TypeOf(context), item: T) bool) []T {
    var i: usize = 0;
    for (unfiltered) |v|
        if (predicate(context, v)) {
            output[i] = v;
            i += 1;
        };
    return output[0..i];
}

/// Caller owns returned slice and must free with `allocator`.
fn allocFilter(comptime T: type, allocator: std.mem.Allocator, context: anytype, unfiltered: []const T, predicate: fn (@TypeOf(context), item: T) bool) ![]T {
    var result = std.ArrayList(T).init(allocator);
    for (unfiltered) |v|
        if (predicate(context, v))
            try result.append(v);
    return result.toOwnedSlice();
}

pub fn main() !void {
    var input = [_]u16{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
    var output: [input.len]u16 = undefined;

    const result_even = filter(u16, true, &output, &input, isOddOrEven);
    std.debug.print("Even numbers: {any}\n", .{result_even});
    // destructive, modify original Array
    const result_odd = filter(u16, false, &input, &input, isOddOrEven);
    std.debug.print("Odd numbers:  {any}\n", .{result_odd});

    // ---------------------------------------------------- allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------
    const numbers = [_]u32{
        34884, 34724, 30941, 30382, 31813,
        33777, 32849, 31747, 30822, 31826,
    };
    const result_three = try allocFilter(u32, allocator, {}, &numbers, isDivisibleBy3);
    defer allocator.free(result_three);
    std.debug.print("Divisible by three:      {any}\n", .{result_three});

    const words = [_][]const u8{
        "cry",  "act",  "fly", "lee", "dry", "gym",  "imp",
        "lynx", "myth", "wry", "no",  "us",  "hymn", "shy",
        "try",
    };
    const result_words = try allocFilter([]const u8, allocator, @as([]const u8, "aeiou"), &words, containsLetters);
    defer allocator.free(result_words);
    std.debug.print("Contains any of \"aeiou\": {s}", .{result_words});
}

fn isOddOrEven(even_context: bool, item: u16) bool {
    return if (even_context)
        item & 1 == 0
    else
        item & 1 != 0;
}
fn isDivisibleBy3(context: void, item: u32) bool {
    _ = context;
    return item % 3 == 0;
}
fn containsLetters(letters: []const u8, word: []const u8) bool {
    return std.mem.indexOfAny(u8, word, letters) != null;
}
