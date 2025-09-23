// https://rosettacode.org/wiki/Idoneal_numbers
// {{works with|Zig|0.15.1}}
// {{trans|C}}

// Using, say, a 16 bit integer C would silently fail with integer overflow.
// Zig (Debug & ReleaseSafe modes) would panic on overflow but can be written to
// check for and respond to these overflows in any mode.
const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() void {
    const newline_count = 10;
    var count: usize = 0;
    var n: u16 = 1;
    while (n <= 1850) : (n += 1)
        if (isIdoneal(n)) {
            print("{d:4} ", .{n});
            count += 1;
            if (count % newline_count == 0) print("\n", .{});
        };

    if (count % newline_count != 0)
        print("\n", .{});
}

fn isIdoneal(n: anytype) bool {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("isIdoneal() requires an unsigned integer, found " ++ @typeName(T));

    var a: T = 1;
    while (a < n) : (a += 1) {
        var b = a + 1;
        while (b < n) : (b += 1) {
            const ov1 = @mulWithOverflow(a, b);
            const ov2 = @addWithOverflow(ov1[0], a);
            const ov3 = @addWithOverflow(ov2[0], b);
            if (ov1[1] != 0) break;
            if (ov2[1] != 0) break; // Ok up to 1850
            if (ov3[1] != 0) break;
            if (ov3[0] > n) break; // a * b + a + b
            var c = b + 1;
            while (c < n) : (c += 1) {
                const ov4 = @mulWithOverflow(a, b);
                const ov5 = @mulWithOverflow(b, c);
                const ov6 = @mulWithOverflow(a, c);
                const ov7 = @addWithOverflow(ov4[0], ov5[0]);
                const ov8 = @addWithOverflow(ov6[0], ov7[0]);
                if (ov4[1] != 0) break; // Ok up to 1850
                if (ov5[1] != 0) break;
                if (ov6[1] != 0) break; // Ok up to 1850
                if (ov7[1] != 0) break;
                if (ov8[1] != 0) break;
                const sum = ov8[0]; // a * b + b * c + a * c;
                if (sum == n) return false;
                if (sum > n) break;
            }
        }
    }
    return true;
}
