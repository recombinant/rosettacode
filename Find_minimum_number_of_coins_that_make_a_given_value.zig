// https://rosettacode.org/wiki/Find_minimum_number_of_coins_that_make_a_given_value
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try makeChange(988, stdout);

    try stdout.flush();
}

fn makeChange(total: u32, w: *std.Io.Writer) !void {
    var coins = [_]u32{ 1, 2, 5, 10, 20, 50, 100, 200 };
    std.mem.sortUnstable(u32, &coins, {}, std.sort.desc(u32));

    try w.print("Available denominations: {any}. Total is to be: {d}.\n", .{ coins, total });

    var count: u32 = 0;
    var remaining = total;
    for (coins) |coin| {
        const coins_used = remaining / coin;
        remaining %= coin;
        if (coins_used > 0)
            try w.print(" {s:>5} coin{s} of {d:>3}\n", .{ asText(coins_used), plural(coins_used), coin });
        count += coins_used;
    }

    try w.print("\nTotal of {s} coin{s} needed.", .{ asText(count), plural(count) });
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
