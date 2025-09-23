// https://rosettacode.org/wiki/Day_of_the_week
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

/// Calculate day of week in proleptic Gregorian calendar. Sunday == 0
fn wday(year: u16, month: u4, day: u6) u3 {
    const adjustment: u16 = (14 - month) / 12;
    const mm: u16 = month + 12 * adjustment - 2;
    const yy: u16 = year - adjustment;
    return @intCast((day + (13 * mm - 1) / 5 +
        yy + yy / 4 - yy / 100 + yy / 400) % 7);
}

pub fn main() void {
    var y: u16 = 2008;
    while (y <= 2121) : (y += 1)
        if (wday(y, 12, 25) == 0)
            std.debug.print("{d:04}-12-25\n", .{y});
}
