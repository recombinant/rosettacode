// https://rosettacode.org/wiki/Number_names
// Translation of: Go
const std = @import("std");
const math = std.math;
const mem = std.mem;

const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    for ([_]i64{ 12, 1048576, 9e18, -2, 0 }) |n| {
        const text = try spellInteger(allocator, n);
        defer allocator.free(text);
        print("{s}\n", .{text});
    }
}

const small = [_][]const u8{
    "zero",     "one",      "two",      "three",   "four",    "five",
    "six",      "seven",    "eight",    "nine",    "ten",     "eleven",
    "twelve",   "thirteen", "fourteen", "fifteen", "sixteen", "seventeen",
    "eighteen", "nineteen",
};
const tens = [_][]const u8{
    "",      "",      "twenty",  "thirty", "forty",
    "fifty", "sixty", "seventy", "eighty", "ninety",
};
const millions = [_][]const u8{
    "",          " thousand",    " million",     " billion",
    " trillion", " quadrillion", " quintillion",
};

/// Supports integers in range math.minInt(i64) to math.maxInt(i64)
/// (which is a greater range than the Go solution - by one)
/// Caller owns returned slice memory.
fn spellInteger(allocator: mem.Allocator, n_: i64) ![]const u8 {
    var t = std.ArrayList(u8).init(allocator);
    if (n_ < 0)
        try t.appendSlice("negative ");

    var n: u64 = if (n_ >= 0) @as(u64, @bitCast(n_)) else if (n_ != math.minInt(i64)) @as(u64, @bitCast(-n_)) else comptime (math.maxInt(u64) >> 1) + 1;

    switch (n) {
        0...19 => try t.appendSlice(small[@intCast(n)]),
        20...99 => {
            try t.appendSlice(tens[n / 10]);
            const s = n % 10;
            if (s > 0) {
                try t.append('-');
                try t.appendSlice(small[s]);
            }
        },
        100...999 => {
            try t.appendSlice(small[n / 100]);
            try t.appendSlice(" hundred");
            const s = n % 100;
            if (s > 0) {
                try t.append(' ');
                const text = try spellInteger(allocator, @intCast(s));
                defer allocator.free(text);
                try t.appendSlice(text);
            }
        },
        else => {
            // work right-to-left
            var sx = std.ArrayList(u8).init(allocator);
            // defer sx.deinit(); // toOwnedSlice()

            var i: usize = 0;
            while (n != 0) : (i += 1) {
                const p = n % 1000;
                n /= 1000;
                if (p != 0) {
                    const text1 = try spellInteger(allocator, @intCast(p));
                    defer allocator.free(text1);

                    var ix = std.ArrayList(u8).init(allocator);
                    // defer ix.deinit(); // swapped with empty ArrayList

                    try ix.appendSlice(text1);
                    try ix.appendSlice(millions[i]);
                    if (sx.items.len != 0) {
                        try ix.append(' ');
                        const text2 = try sx.toOwnedSlice();
                        defer allocator.free(text2);

                        try ix.appendSlice(text2);
                    }
                    // sx is empty ie. sx.items.len == 0
                    // ix contains text
                    mem.swap(std.ArrayList(u8), &sx, &ix);
                }
            }
            const text = try sx.toOwnedSlice();
            defer allocator.free(text);

            try t.appendSlice(text); // t may already contain "negative "
        },
    }
    return try t.toOwnedSlice();
}
