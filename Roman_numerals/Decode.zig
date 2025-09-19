// https://rosettacode.org/wiki/Roman_numerals/Decode
// {{works with|Zig|0.15.1}}
const std = @import("std");
const testing = std.testing;

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const samples = [_][]const u8{ "MCMXC", "MMVIII", "MDCLXVI", "IV", "I", "MLXVI", "IIC" };
    for (samples) |r|
        try stdout.print("{s} {d}\n", .{ r, try decode(r) });

    try stdout.flush();
}

fn decode(roman: []const u8) RomanDecodeError!u16 {
    if (roman.len == 0)
        return RomanDecodeError.EmptyString;
    var result: u16 = 0;
    var sum: u16 = 0; // groups of same digit
    for (0..roman.len - 1) |i| {
        const rd = try rdecode(roman[i]);
        const rd1 = try rdecode(roman[i + 1]);
        sum += rd;
        switch (std.math.order(rd, rd1)) {
            .lt => result -%= sum,
            .eq => continue,
            .gt => result +%= sum,
        }
        sum = 0;
    }
    sum += try rdecode(roman[roman.len - 1]);
    result +%= sum;
    if (@as(i16, @bitCast(result)) <= 0)
        return RomanDecodeError.OutOfRange;
    return result;
}

const RomanDecodeError = error{
    EmptyString,
    NotRomanNumeral,
    OutOfRange,
};

fn rdecode(c: u8) RomanDecodeError!u16 {
    return switch (c) {
        'M' => 1000,
        'D' => 500,
        'C' => 100,
        'L' => 50,
        'X' => 10,
        'V' => 5,
        'I' => 1,
        else => RomanDecodeError.NotRomanNumeral,
    };
}

fn testDecode(arabic: []const u8, roman: u16) !void {
    const actual = try decode(arabic);
    try testing.expectEqual(roman, actual);
}

test "to arabic" {
    for ([_]struct { []const u8, u16 }{
        .{ "MMVIII", 2008 },
        .{ "MDCCCCX", 1910 }, // Admiralty Arch, London
        .{ "MCMX", 1910 },
        .{ "MDCDIII", 1903 }, // Saint Louis Art Museum
        .{ "MDCLXVI", 1666 },
        .{ "MLXVI", 1066 },
        .{ "CDXCIX", 499 },
        .{ "ID", 499 },
        .{ "LDVLIV", 499 }, // Microsoft Excel
        .{ "XDIX", 499 }, // Microsoft Excel
        .{ "VDIV", 499 }, // Microsoft Excel
        .{ "ID", 499 }, // Microsoft Excel
        .{ "DCCCLXXXVIII", 888 },
        .{ "IC", 99 }, // unodecentum
        .{ "IIC", 98 }, // duodecentum
        .{ "V", 5 },
        .{ "IIII", 4 },
        .{ "IV", 4 },
        .{ "I", 1 },
    }) |pair| {
        try testDecode(pair[0], pair[1]);
    }
}

test "RomanDecodeError.EmptyString" {
    const erroneous = "";
    try testing.expectError(RomanDecodeError.EmptyString, decode(erroneous));
}

test "RomanDecodeError.OutOfRange" {
    const erroneous = "IIIIIIV";
    try testing.expectError(RomanDecodeError.OutOfRange, decode(erroneous));
}

test "to arabic error" {
    const erroneous = "BAD WOLF";
    try testing.expectError(RomanDecodeError.NotRomanNumeral, decode(erroneous));
}

test "to arabic error - upper case only" {
    const lower_case = "i";
    try testing.expectError(RomanDecodeError.NotRomanNumeral, decode(lower_case));
}
