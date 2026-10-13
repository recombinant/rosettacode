// https://rosettacode.org/wiki/Doomsday_rule
// {{works with|Zig|0.17.0}}
const std = @import("std");
const Io = std.Io;
const zeit = @import("zeit");

pub fn main(init: std.process.Init) anyerror!void {
    const io: Io = init.io;

    const task_dates = [_][]const u8{
        "1800-01-06",
        "1875-03-29",
        "1915-12-07",
        "1970-12-23",
        "2043-05-14",
        "2077-02-12",
        "2101-04-02",
    };

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll("Days of week given by Doomsday rule:\n\n");

    const instant = zeit.instant(.{ .now = io }, &zeit.utc).time();
    const current: zeit.Time = .{ .year = instant.year, .month = instant.month, .day = instant.day };
    // Copy current Time to task Time so that that a comparison will only
    // be comparing YMD as the remaining struct elements will already be
    // identical.
    var task: zeit.Time = current;

    for (task_dates) |date| {
        const tense: []const u8 = blk: {
            const past = "was";
            const present = "is";
            const future = "will be";

            task.year = try std.fmt.parseInt(std.time.epoch.Year, date[0..4], 10);
            task.month = @fromBackingInt(try std.fmt.parseInt(@typeInfo(zeit.Month).@"enum".tag_type, date[5..7], 10));
            task.day = try std.fmt.parseInt(@FieldType(zeit.Time, "day"), date[8..10], 10);

            break :blk if (task.before(current)) past else if (task.after(current)) future else present;
        };

        try task.gofmt(stdout, "January 02 2006 ");
        try stdout.print(" {s} a {s}.\n", .{ tense, weekday(task) });

        try stdout.flush();
    }
}

fn weekday(date: zeit.Time) []const u8 {
    const days = [7][]const u8{ "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" };
    const leap_doom = [12]u3{ 4, 1, 7, 2, 4, 6, 4, 1, 5, 3, 7, 5 };
    const norm_doom = [12]u3{ 3, 7, 7, 4, 2, 6, 4, 1, 5, 3, 7, 5 };

    // avoid zeit module's signed numbers & enums
    const year: u16 = @intCast(date.year);
    const month: u16 = @intCast(@backingInt(date.month) - 1);
    //
    const century = year / 100;
    const r = year % 100;
    const s = r / 12;
    const t = r % 12;
    const c_anchor = (5 * (century % 4) + 2) % 7;
    const doom = (s + t + t / 4 + c_anchor) % 7;
    const anchor = (if (std.time.epoch.isLeapYear(year)) leap_doom else norm_doom)[month];
    return days[(7 + doom + date.day - anchor) % 7];
}
