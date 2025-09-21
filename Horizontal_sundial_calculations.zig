// https://rosettacode.org/wiki/Horizontal_sundial_calculations
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const lat = try getNumber("Enter latitude       => ", stdout);
    const lon = try getNumber("Enter longitude      => ", stdout);
    const ref = try getNumber("Enter legal meridian => ", stdout);
    const slat = @sin(std.math.degreesToRadians(lat));
    const diff = lon - ref;

    try stdout.writeByte('\n');
    try stdout.print("    sine of latitude:   {d:.3}\n", .{slat});
    try stdout.print("    diff longitude:     {d:.3}\n", .{diff});
    try stdout.writeByte('\n');
    try stdout.writeAll("Hour, sun hour angle, dial hour line angle from 6am to 6pm\n");
    var h: f64 = -6;
    while (h <= 6) : (h += 1) {
        const hra: f64 = 15 * h - diff;
        const radians = std.math.degreesToRadians(hra);
        const s = @sin(radians);
        const c = @cos(radians);
        const hla = std.math.radiansToDegrees(std.math.atan2(slat * s, c));
        try stdout.print("{d:2.0} {d:8.3} {d:8.3}\n", .{ h, hra, hla });
    }

    try stdout.flush();
}

fn getNumber(prompt: []const u8, stdout: *std.Io.Writer) !f64 {
    var stdin_buffer: [512]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;

    const len = 7 + 2; // max -360.00 with CRLF

    var buf: [len]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);

    while (true) {
        _ = w.consumeAll();
        try stdout.writeAll(prompt);
        try stdout.flush();

        _ = try stdin.streamDelimiter(&w, '\n');
        _ = try stdin.takeByte(); // consume the '\n'

        const input = std.mem.trim(u8, w.buffered(), "\r\n\t ");
        if (input.len == 0) continue; // await further input

        if (std.fmt.parseFloat(f64, input)) |number|
            return number
        else |_| {}
        // await further input
    }
}
