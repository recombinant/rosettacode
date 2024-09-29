// https://rosettacode.org/wiki/Averages/Arithmetic_mean
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    {
        const v = [_]f64{ 1, 2, 2.718, 3, 3.142 };
        var len = v.len + 1;
        while (len > 0) {
            len -= 1;

            try stdout.print("mean[", .{});

            var sep: []const u8 = "";
            for (v[0..len]) |n| {
                try stdout.print("{s}{d}", .{ sep, n });
                sep = ", ";
            }

            try stdout.print("] = {d}\n", .{mean(v[0..len])});
        }
    }
    {
        const v = [_]f64{ 1, 2, 2.718, 3, 3.142 };
        var len = v.len + 1;
        while (len > 0) {
            len -= 1;

            try stdout.print("mean[", .{});

            var sep: []const u8 = "";
            for (v[0..len]) |n| {
                try stdout.print("{s}{d}", .{ sep, n });
                sep = ", ";
            }

            try stdout.print("] = ", .{});

            if (meanE(v[0..len])) |value|
                try stdout.print("{d}\n", .{value})
            else |err| switch (err) {
                error.DivisionByZero => try stdout.print("{}\n", .{err}),
                else => unreachable,
            }
        }
    }
}

fn mean(v: []const f64) f64 {
    var sum: f64 = 0;
    for (v) |n|
        sum += n;
    return sum / @as(f64, @floatFromInt(v.len));
}

/// Return an error if 'v' has zero length.
fn meanE(v: []const f64) !f64 {
    if (v.len == 0)
        return error.DivisionByZero;

    var sum: f64 = 0;
    for (v) |n|
        sum += n;
    return sum / @as(f64, @floatFromInt(v.len));
}
