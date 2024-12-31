// https://rosettacode.org/wiki/Reverse_a_string
const std = @import("std");

pub fn main() !void {
    // ------------------ for an ASCII string (in place reversal)
    var s = "qwert".*;

    std.debug.print("{s} => ", .{s});

    std.mem.reverse(u8, &s);
    std.debug.print("{s}\n", .{s});

    // ---------------------------------------- for a utf8 string
    const u = "♠♣♦♥";

    var r = try std.BoundedArray(u8, u.len).init(0);

    var utf8 = (try std.unicode.Utf8View.init(u)).iterator();
    while (utf8.nextCodepointSlice()) |slice|
        try r.insertSlice(0, slice); // effective, not efficient

    std.debug.print("{s} => {s}\n", .{ u, r.constSlice() });
}
