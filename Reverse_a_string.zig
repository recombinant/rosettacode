// https://rosettacode.org/wiki/Reverse_a_string
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    // ------------------ for an ASCII string (in place reversal)
    var s = "qwert".*;

    std.debug.print("{s} => ", .{s});

    std.mem.reverse(u8, &s);
    std.debug.print("{s}\n", .{s});

    // ---------------------------------------- for a utf8 string
    const u = "♠♣♦♥";

    var buffer: [u.len]u8 = undefined;
    var r: std.ArrayList(u8) = .initBuffer(&buffer);

    // Copy the unicode characters in reverse,
    // then reverse the result.
    var utf8 = (try std.unicode.Utf8View.init(u)).iterator();
    while (utf8.nextCodepointSlice()) |slice| {
        var it = std.mem.reverseIterator(slice);
        while (it.next()) |byte|
            try r.appendBounded(byte);
    }
    std.debug.assert(r.items.len == u.len);
    std.mem.reverse(u8, r.items);

    std.debug.print("{s} => {s}\n", .{ u, r.items });
}
