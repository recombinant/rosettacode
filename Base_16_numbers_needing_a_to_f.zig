// https://rosettacode.org/wiki/Base_16_numbers_needing_a_to_f
// Translation of C
const std = @import("std");

pub fn main() !void {
    const writer = std.io.getStdOut().writer();

    var h: u16 = 0;
    while (h != 512) : (h += 16) {
        var l: u16 = if (h & 0xff < 0xa0) 10 else 0;
        while (l != 16) : (l += 1) {
            const n = h | l;
            if (n > 500) {
                try writer.writeByte('\n');
                return;
            }
            try writer.print(" {d}", .{n});
        }
    }
}
