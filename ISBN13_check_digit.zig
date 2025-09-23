// https://rosettacode.org/wiki/ISBN13_check_digit
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

pub fn main() void {
    const isbn_array = [_][]const u8{
        "978-0596528126", "978-0596528120",
        "978-1788399081", "978-1788399083",
    };
    for (isbn_array) |isbn|
        std.debug.print("{s}: {s}\n", .{ isbn, if (checkISBN13(isbn)) "good" else "bad" });
}

fn checkISBN13(isbn: []const u8) bool {
    var sum: usize = 0;
    var count: usize = 0;
    // check isbn contains 13 digits and calculate weighted sum
    for (isbn) |ch| {
        switch (ch) {
            '0'...'9' => {
                var n = ch - '0';
                if (count % 2 != 0) n *= 3;
                sum += n;
                count += 1;
            },
            ' ', '-' => continue, // skip hyphens or spaces
            else => return false,
        }
    }
    return count == 13 and sum % 10 == 0;
}
