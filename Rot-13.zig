// https://rosettacode.org/wiki/Rot-13
// {{works with|Zig|0.15.1}}

pub fn main() void {
    const message: []const u8 =
        \\Lbh xabj vg vf tbvat gb or n onq qnl
        \\jura gur yrggref va lbhe nycunorg fbhc
        \\fcryy Q-V-F-N-F-G-R-E.
    ;
    // This works because constant 'message' is comptime known
    var buffer: [message.len]u8 = undefined;

    // Copy constant 'message' to variable 'buffer' for later modification in-place
    @memcpy(&buffer, message);
    defer @memset(&buffer, 0); // Security: overwrite 'buffer' after use

    @import("std").debug.print("rot13={s}\n", .{rot13(&buffer)});
}

/// Modifies parameter 'slice' in-place
fn rot13(slice: []u8) []u8 {
    for (slice) |*c| {
        c.* = switch (c.*) {
            'A'...'Z' - 13, 'a'...'z' - 13 => |n| n + 13,
            'Z' - 12...'Z', 'z' - 12...'z' => |n| n - 26 + 13,
            else => |n| n,
        };
    }
    return slice;
}
