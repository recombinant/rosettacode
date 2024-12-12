// https://rosettacode.org/wiki/Find_minimum_number_of_coins_that_make_a_given_value
const std = @import("std");

pub fn main() !void {
    const writer = std.io.getStdOut().writer();

    try makeChange(988, writer);
}

fn makeChange(total: u32, writer: anytype) !void {
    var coins = [_]u32{ 1, 2, 5, 10, 20, 50, 100, 200 };
    std.mem.sort(u32, &coins, {}, std.sort.desc(u32));

    try writer.print("Available denominations: {any}. Total is to be: {d}.\n", .{ coins, total });

    var count: u32 = 0;
    var remaining = total;
    for (coins) |coin| {
        const coins_used = remaining / coin;
        remaining %= coin;
        if (coins_used > 0)
            try writer.print(" {s:>5} coin{s} of {d:>3}\n", .{ asText(coins_used), plural(coins_used), coin });
        count += coins_used;
    }

    try writer.print("\nTotal of {s} coin{s} needed.", .{ asText(count), plural(count) });
}

fn plural(one_or_other: u32) []const u8 {
    return if (one_or_other != 1) "s" else " ";
}

/// Provide the text representation of 'number'.
/// For this application 16 will cover 1..2000 for makeChange()
fn asText(number: u32) []const u8 {
    const text = [17][]const u8{
        "zero", "one", "two",    "three",  "four",     "five",     "six",     "seven",   "eight",
        "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
    };
    return text[number];
}
