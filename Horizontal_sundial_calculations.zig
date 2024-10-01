// https://rosettacode.org/wiki/Horizontal_sundial_calculations
const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const math = std.math;
const mem = std.mem;

pub fn main() !void {
    const lat = try getNumber("Enter latitude       => ");
    const lon = try getNumber("Enter longitude      => ");
    const ref = try getNumber("Enter legal meridian => ");
    const slat = @sin(math.degreesToRadians(lat));
    const diff = lon - ref;

    const stdout = io.getStdOut().writer();
    try stdout.writeByte('\n');
    try stdout.print("    sine of latitude:   {d:.3}\n", .{slat});
    try stdout.print("    diff longitude:     {d:.3}\n", .{diff});
    try stdout.writeByte('\n');
    try stdout.writeAll("Hour, sun hour angle, dial hour line angle from 6am to 6pm\n");
    var h: f64 = -6;
    while (h <= 6) : (h += 1) {
        const hra: f64 = 15 * h - diff;
        const radians = math.degreesToRadians(hra);
        const s = @sin(radians);
        const c = @cos(radians);
        const hla = math.radiansToDegrees(math.atan2(slat * s, c));
        try stdout.print("{d:2.0} {d:8.3} {d:8.3}\n", .{ h, hra, hla });
    }
}

fn getNumber(prompt: []const u8) !f64 {
    const stdout = io.getStdOut().writer();
    const stdin = io.getStdIn().reader();
    const len = comptime 7 + 2; // max -360.00 with CRLF
    var buf: [len]u8 = undefined;
    var fbs = io.fixedBufferStream(&buf);
    while (true) {
        fbs.reset();
        try stdout.writeAll(prompt);
        stdin.streamUntilDelimiter(fbs.writer(), '\n', fbs.buffer.len) catch |e| {
            switch (e) {
                error.StreamTooLong => {
                    while (try stdin.readByte() != '\n') {}
                    continue; // await further input
                },
                else => return e,
            }
        };
        const input = mem.trim(u8, fbs.getWritten(), "\r\n\t ");
        if (fmt.parseFloat(f64, input)) |number|
            return number
        else |_| {}
        // await further input
    }
}
