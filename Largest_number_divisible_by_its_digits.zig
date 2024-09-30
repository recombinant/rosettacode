// https://rosettacode.org/wiki/Largest_number_divisible_by_its_digits
// Translation of: Kotlin
const std = @import("std");
const fmt = std.fmt;
const math = std.math;
const mem = std.mem;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    if (base10()) |n|
        try stdout.print("Largest decimal number is {d}\n", .{n})
    else
        try stdout.writeAll("Largest decimal number not found\n");

    if (base16()) |n|
        try stdout.print("Largest hexadecimal number is 0x{x}\n", .{n})
    else
        try stdout.writeAll("Largest hexadecimal number not found\n");
}

fn base10() ?u32 {
    const maximum: u32 = 9876432;
    // buffer length == 1 + log10(max)
    var buffer: [1 + math.log10_int(maximum)]u8 = undefined;

    const step: u32 = 9 * 8 * 7;
    const start: u32 = maximum / step * step;
    var n = start + step;
    while (n >= step) {
        n -= step;
        if (n % 10 == 0) continue; // can't end in '0'
        const s = fmt.bufPrint(&buffer, "{}", .{n}) catch unreachable;
        if (mem.indexOfAny(u8, s, "05") != null) continue; // can't contain '0' or '5'
        if (!distinct(s)) continue; // digits must be unique
        if (divByAllDecimal(n, s))
            return n;
    }
    return null; // not found
}

fn base16() ?u64 {
    const maximum = 0xfedcba987654321;
    // comptime buffer length == 1 + log16(max)
    var buffer: [1 + math.log_int(usize, 16, maximum)]u8 = undefined;

    const step: u64 = 15 * 14 * 13 * 12 * 11;
    const start: u64 = maximum / step * step;
    var n: u64 = start + step;
    while (n >= step) {
        n -= step;
        if (n % 16 == 0) continue; // can't end in '0'
        // {x} generates lower case a-f
        const s = fmt.bufPrint(&buffer, "{x}", .{n}) catch unreachable;
        if (mem.indexOfScalar(u8, s, '0') != null) continue; // can't contain '0'
        if (!distinct(s)) continue; // digits must be unique
        if (divByAllHex(n, s))
            return n;
    }
    return null;
}

/// Are all digits distinct? i.e. no digit is repeated within digits.
fn distinct(digits: []const u8) bool {
    for (digits[0 .. digits.len - 1], 1..) |digit, i|
        if (mem.indexOfScalar(u8, digits[i..], digit) != null)
            return false;
    return true;
}

fn divByAllDecimal(number: u32, digits: []const u8) bool {
    for (digits) |digit|
        if (number % (digit - '0') != 0)
            return false;
    return true;
}

fn divByAllHex(number: u64, digits: []const u8) bool {
    for (digits) |digit| {
        const value = switch (digit) {
            '1'...'9' => digit - '0',
            'a'...'f' => digit - comptime ('a' - 0xa),
            'A'...'F' => digit - comptime ('A' - 0xa),
            else => unreachable,
        };
        if (number % value != 0)
            return false;
    }
    return true;
}

const testing = std.testing;

test "divByAllDecimal" {
    try testing.expect(divByAllDecimal(135, "135"));
    try testing.expect(divByAllDecimal(9867312, "9867312"));
    // not divByAllDecimal()
    try testing.expect(!divByAllDecimal(1135, "1135"));
    try testing.expect(!divByAllDecimal(235, "235"));
}

test "divByAllHex" {
    try testing.expect(divByAllHex(0xfedcb59726a1348, "fedcb59726a1348"));
    // not divByAllHex()
    try testing.expect(!divByAllHex(0xedcb59726a1348, "edcb59726a1348"));
}

test "distinct" {
    try testing.expect(distinct("0"));
    try testing.expect(distinct("1234"));
    try testing.expect(distinct("4321"));
    try testing.expect(distinct("fedcba987654321"));
    try testing.expect(!distinct("121")); // not distinct()
}
