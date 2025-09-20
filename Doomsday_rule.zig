// https://rosettacode.org/wiki/Doomsday_rule
// {{works with|Zig|0.15.1}}
const std = @import("std");
const c = @cImport({
    @cInclude("time.h");
});

pub fn main() anyerror!void {
    const MonthsError = error{
        NoMonthZero, // there is no month at months[0]
    };
    const months = [13]?[]const u8{ null, "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" };

    const task_dates = [_]Date{
        .{ .year = 1800, .month = 1, .day = 6 },
        .{ .year = 1875, .month = 3, .day = 29 },
        .{ .year = 1915, .month = 12, .day = 7 },
        .{ .year = 1970, .month = 12, .day = 23 },
        .{ .year = 2043, .month = 5, .day = 14 },
        .{ .year = 2077, .month = 2, .day = 12 },
        .{ .year = 2101, .month = 4, .day = 2 },
    };

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const now = c.time(null);
    const tm_now: *c.tm = c.localtime(&now);
    var tm_task: c.tm = std.mem.zeroes(c.tm);

    for (task_dates) |d| {
        const month: []const u8 = months[d.month] orelse return MonthsError.NoMonthZero;

        const tense: []const u8 = blk: {
            const past = "was";
            const present = "is";
            const future = "will be";
            const task_year = @as(c_int, @intCast(d.year)) - 1900;
            // check now against task year.
            if (task_year < tm_now.tm_year) break :blk past;
            if (task_year > tm_now.tm_year) break :blk future;
            // current year so use C difftime()
            tm_task.tm_year = task_year;
            tm_task.tm_mon = d.month;
            tm_task.tm_mday = d.day;
            const diff = c.difftime(c.mktime(&tm_task), now);
            break :blk if (diff < 0) past else if (diff > 0) future else present;
        };

        try stdout.print(
            "{s} {d}, {d} {s} a {s}.\n",
            .{ month, d.day, d.year, tense, weekday(d) },
        );
        try stdout.flush();
    }
}

const Date = struct {
    year: std.time.epoch.Year,
    month: u4,
    day: u5,
};

fn weekday(date: Date) []const u8 {
    const days = [7][]const u8{ "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" };
    const leap_doom = [12]u3{ 4, 1, 7, 2, 4, 6, 4, 1, 5, 3, 7, 5 };
    const norm_doom = [12]u3{ 3, 7, 7, 4, 2, 6, 4, 1, 5, 3, 7, 5 };

    const century = date.year / 100;
    const r = date.year % 100;
    const s = r / 12;
    const t = r % 12;
    const c_anchor = (5 * (century % 4) + 2) % 7;
    const doom = (s + t + t / 4 + c_anchor) % 7;
    const anchor = (if (std.time.epoch.isLeapYear(date.year)) leap_doom else norm_doom)[date.month - 1];
    return days[(7 + doom + date.day - anchor) % 7];
}
