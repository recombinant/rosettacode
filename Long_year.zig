// https://rosettacode.org/wiki/Long_year
// {{works with|Zig|0.15.1}}
// {{trans|C++}}
const std = @import("std");
const print = std.debug.print;

// Reference:
// https://en.wikipedia.org/wiki/ISO_week_date#Weeks_per_year

pub fn main() void {
    print("{s}", .{"Long years between 1800 and 2100:\n"});
    printLongYears(1800, 2100);
    print("{s}", .{"\n"});
}

fn p(year: u16) u16 {
    return (year + (year / 4) - (year / 100) + (year / 400)) % 7;
}

fn isLongYear(year: u16) bool {
    return p(year) == 4 or p(year - 1) == 3;
}

fn printLongYears(from: u16, to: u16) void {
    var count: u16 = 0;
    var year = from;
    while (year <= to) : (year += 1) {
        if (isLongYear(year)) {
            if (count > 0) {
                const sep: u8 = if (count % 10 == 0) '\n' else ' ';
                print("{c}", .{sep});
            }
            print("{}", .{year});
            count += 1;
        }
    }
}
