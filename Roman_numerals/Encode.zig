// https://rosettacode.org/wiki/Roman_numerals/Encode
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    // ------------------------------------------ allocator
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ----------------------------------------------------

    const sample_numbers = [_]u16{
        1,    2,    3,    4,    5,    6,    7,    8,    9,    10,
        11,   12,   13,   14,   15,   16,   17,   18,   19,   20,
        25,   30,   40,   50,   60,   69,   70,   80,   90,   99,
        100,  200,  300,  400,  500,  600,  666,  700,  800,  900,
        1000, 1009, 1444, 1666, 1945, 1997, 1999, 2000, 2008, 2010,
        2011, 2500, 3000, 3888, 3999,
    };

    for (sample_numbers) |number| {
        const r = try encode(allocator, number);
        defer allocator.free(r);
        try stdout.print("{d:4}: {s}\n", .{ number, r });
    }

    try stdout.flush();
}

// Caller owns returned memory slice.
fn encode(allocator: std.mem.Allocator, n_: u16) ![]const u8 {
    const pairs = comptime [_]struct { roman: []const u8, arabic: u16 }{
        .{ .roman = "M", .arabic = 1000 }, .{ .roman = "CM", .arabic = 900 },
        .{ .roman = "D", .arabic = 500 },  .{ .roman = "CD", .arabic = 400 },
        .{ .roman = "C", .arabic = 100 },  .{ .roman = "XC", .arabic = 90 },
        .{ .roman = "L", .arabic = 50 },   .{ .roman = "XL", .arabic = 40 },
        .{ .roman = "X", .arabic = 10 },   .{ .roman = "IX", .arabic = 9 },
        .{ .roman = "V", .arabic = 5 },    .{ .roman = "IV", .arabic = 4 },
        .{ .roman = "I", .arabic = 1 },
    };

    var n = n_;

    var array: std.ArrayList(u8) = .empty;

    for (pairs) |pair|
        while (n >= pair.arabic) {
            try array.appendSlice(allocator, pair.roman);
            n -= pair.arabic;
        };

    return array.toOwnedSlice(allocator);
}

const testing = std.testing;

fn testEncode(allocator: std.mem.Allocator, roman: u16, arabic: []const u8) !void {
    const actual = try encode(allocator, roman);
    try testing.expectEqualStrings(arabic, actual);
    allocator.free(actual);
}

test "to arabic" {
    const allocator = testing.allocator;

    for ([_]struct { u16, []const u8 }{
        .{ 1, "I" },          .{ 2, "II" },
        .{ 3, "III" },        .{ 4, "IV" },
        .{ 5, "V" },          .{ 6, "VI" },
        .{ 7, "VII" },        .{ 8, "VIII" },
        .{ 9, "IX" },         .{ 10, "X" },
        .{ 11, "XI" },        .{ 12, "XII" },
        .{ 13, "XIII" },      .{ 14, "XIV" },
        .{ 15, "XV" },        .{ 16, "XVI" },
        .{ 17, "XVII" },      .{ 18, "XVIII" },
        .{ 19, "XIX" },       .{ 20, "XX" },
        .{ 25, "XXV" },       .{ 30, "XXX" },
        .{ 40, "XL" },        .{ 50, "L" },
        .{ 60, "LX" },        .{ 69, "LXIX" },
        .{ 70, "LXX" },       .{ 80, "LXXX" },
        .{ 90, "XC" },        .{ 99, "XCIX" },
        .{ 100, "C" },        .{ 200, "CC" },
        .{ 300, "CCC" },      .{ 400, "CD" },
        .{ 500, "D" },        .{ 600, "DC" },
        .{ 666, "DCLXVI" },   .{ 700, "DCC" },
        .{ 800, "DCCC" },     .{ 900, "CM" },
        .{ 1000, "M" },       .{ 1009, "MIX" },
        .{ 1444, "MCDXLIV" }, .{ 1666, "MDCLXVI" },
        .{ 1945, "MCMXLV" },  .{ 1997, "MCMXCVII" },
        .{ 1999, "MCMXCIX" }, .{ 2000, "MM" },
        .{ 2008, "MMVIII" },  .{ 2010, "MMX" },
        .{ 2011, "MMXI" },    .{ 2500, "MMD" },
        .{ 3000, "MMM" },     .{ 3888, "MMMDCCCLXXXVIII" },
        .{ 3990, "MMMCMXC" }, .{ 3999, "MMMCMXCIX" },
    }) |pair|
        try testEncode(allocator, pair[0], pair[1]);
}
