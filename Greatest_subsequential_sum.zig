// https://rosettacode.org/wiki/Greatest_subsequential_sum
// {{works with|Zig|0.15.1}}
// {{trans|Go}}
const std = @import("std");
const print = std.debug.print;

const samples = [_][]const i16{
    &[_]i16{ 1, 2, 3, 4, 5, -8, -9, -20, 40, 25, -5 },
    &[_]i16{ -1, -2, 3, 5, 6, -2, -1, 4, -4, 2, -1 },
    &[_]i16{ -1, 1, 2, -5, -6 },
    &[_]i16{},
    &[_]i16{ -1, -2, -1 },
};

pub fn main() void {
    for (samples) |sample| {
        print("Input:   {any}\n", .{sample});

        const sub_seq, const sum = gss(sample);
        print("Sub seq: {any}\n", .{sub_seq});
        print("Sum:     {any}\n\n", .{sum});
    }
}

fn gss(s: []const i16) struct { []const i16, i32 } {
    var start, var end = [2]usize{ 0, 0 };
    var best: i32 = 0;
    var sum: i32 = 0;
    var sum_start: usize = 0;
    for (s, 0..) |x, i| {
        sum += x;
        if (sum > best) {
            best = sum;
            start, end = .{ sum_start, i + 1 };
        } else if (sum < 0) {
            sum = 0;
            sum_start = i + 1;
        }
    }
    return .{ s[start..end], best };
}
