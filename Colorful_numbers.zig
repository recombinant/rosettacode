// https://rosettacode.org/wiki/Colorful_numbers
// Translation of C
const std = @import("std");

fn isColorful(n: u32) bool {
    // A colorful number cannot be greater than 98765432.
    if (n > 98765432)
        return false;
    var digit_count: [10]usize = std.mem.zeroes([10]usize);
    var digits: [8]u32 = std.mem.zeroes([8]u32);
    var num_digits: usize = 0;

    var m = n;
    while (m > 0) : (m /= 10) {
        const d = m % 10;
        if (n > 9 and (d == 0 or d == 1))
            return false;
        digit_count[d] += 1;
        if (digit_count[d] > 1)
            return false;
        digits[num_digits] = d;
        num_digits += 1;
    }

    // Maximum number of products is (8 x 9) / 2.
    var products: [36]u32 = std.mem.zeroes([36]u32);

    var i: usize = 0;
    var product_count: usize = 0;
    while (i < num_digits) : (i += 1) {
        var j = i;
        var p: u32 = 1;
        while (j < num_digits) : (j += 1) {
            p *= digits[j];

            var k: usize = 0;
            while (k < product_count) : (k += 1)
                if (products[k] == p)
                    return false;

            products[product_count] = p;
            product_count += 1;
        }
    }
    return true;
}

const Colorful = struct {
    count: [8]u32 = std.mem.zeroes([8]u32),
    used: [10]bool = std.mem.zeroes([10]bool),
    largest: u32 = 0,

    fn countColorful(self: *Colorful, taken: usize, n: u32, digits: usize) void {
        if (taken == 0) {
            var d: u32 = 0;
            while (d < 10) : (d += 1) {
                self.used[d] = true;
                self.countColorful(if (d < 2) 9 else 1, d, 1);
                self.used[d] = false;
            }
        } else {
            if (isColorful(n)) {
                self.count[digits - 1] += 1;
                if (n > self.largest)
                    self.largest = n;
            }
            if (taken < 9) {
                var d: u32 = 2;
                while (d < 10) : (d += 1)
                    if (!self.used[d]) {
                        self.used[d] = true;
                        self.countColorful(taken + 1, (n * 10) + d, digits + 1);
                        self.used[d] = false;
                    };
            }
        }
    }
};

pub fn main() !void {
    var t0 = try std.time.Timer.start();

    const writer = std.io.getStdOut().writer();

    try writer.writeAll("Colorful numbers less than 100:\n");

    var n: u32 = 0;
    var count1: usize = 0;
    while (n < 100) : (n += 1)
        if (isColorful(n)) {
            count1 += 1;
            try writer.print("{d:2}{c}", .{ n, @as(u8, if (count1 % 10 == 0) '\n' else ' ') });
        };

    var c = Colorful{};
    c.countColorful(0, 0, 0);
    try writer.print("\n\nLargest colorful number: {d}\n", .{c.largest});

    try writer.writeAll("\nCount of colorful numbers by number of digits:\n");
    var total: u32 = 0;
    var d: u32 = 0;
    while (d < 8) : (d += 1) {
        try writer.print("{d} {d}\n", .{ d + 1, c.count[d] });
        total += c.count[d];
    }
    try writer.print("\nTotal: {d}\n", .{total});

    std.log.info("processed in {}\n", .{std.fmt.fmtDuration(t0.read())});
}
