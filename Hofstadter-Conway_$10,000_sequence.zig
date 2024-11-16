// https://rosettacode.org/wiki/Hofstadter-Conway_$10,000_sequence
// Translation of Go
const std = @import("std");

const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var a = std.ArrayList(u32).init(allocator);
    defer a.deinit();
    try a.appendSlice(&[3]u32{ 0, 1, 1 }); // ignore 0 element. work 1 based.
    var x: u32 = 1; // last number in list
    var n: usize = 2; // index of last number in list = a.len - 1
    var mallows: usize = 0;
    for (1..21) |p| {
        var max: f64 = 0;
        const next_pot = n * 2;
        while (n < next_pot) {
            n = a.items.len; // advance n
            x = a.items[x] + a.items[n - x];
            try a.append(x);
            const f = @as(f64, @floatFromInt(x)) / @as(f64, @floatFromInt(n));
            if (f > max) max = f;
            if (f >= 0.55) mallows = n;
        }
        print("max between 2^{d} and 2^{d} was {d}\n", .{ p, p + 1, max });
    }
    print("winning number {d}\n", .{mallows});
}
