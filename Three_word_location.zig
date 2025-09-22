// https://rosettacode.org/wiki/Three_word_location
// {{works with|Zig|0.15.1}}
// {{trans|Go}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll("Starting figures:\n");
    const lat = 28.3852;
    const lon = -81.5638;
    try stdout.print("  latitude = {d:.4}, longitude = {d:.4}\n", .{ lat, lon });

    // convert lat and lon to positive integers
    const ilat: u64 = @intFromFloat(lat * 10_000 + 900_000);
    const ilon: u64 = @intFromFloat(lon * 10_000 + 1_800_000);

    // build 43 bit integer comprising 21 bits (lat) and 22 bits (lon)
    const latlon: u43 = (ilat << 22) + ilon;

    // isolate relevant bits
    const n1 = (latlon >> 28) & 0x7fff;
    const n2 = (latlon >> 14) & 0x3fff;
    const n3 = latlon & 0x3fff;

    var buffer1: [6]u8 = undefined;
    var buffer2: [6]u8 = undefined;
    var buffer3: [6]u8 = undefined;

    // convert to word format
    const w1 = try toWord(&buffer1, n1);
    const w2 = try toWord(&buffer2, n2);
    const w3 = try toWord(&buffer3, n3);

    // and print the results
    try stdout.writeAll("\nThree word location is:\n");
    try stdout.print("  {s} {s} {s}\n", .{ w1, w2, w3 });

    // now reverse the procedure
    const n1_rev = try fromWord(w1);
    const n2_rev = try fromWord(w2);
    const n3_rev = try fromWord(w3);

    const latlon_rev = (n1_rev << 28) | (n2_rev << 14) | n3_rev;
    const ilat_rev = latlon_rev >> 22;
    const ilon_rev = latlon_rev & 0x3fffff;
    const lat_rev = (@as(f64, @floatFromInt(ilat_rev)) - 900_000) / 10_000;
    const lon_rev = (@as(f64, @floatFromInt(ilon_rev)) - 1_800_000) / 10_000;

    // and print the results
    try stdout.writeAll("\nAfter reversing the procedure:\n");
    try stdout.print("  latitude = {d:.4}, longitude = {d:.4}\n", .{ lat_rev, lon_rev });

    try stdout.flush();
}

fn toWord(output: []u8, n: u64) ![]u8 {
    var w: std.Io.Writer = .fixed(output);
    try w.print("W{d:0>5}", .{n});
    return w.buffered();
}

fn fromWord(ws: []const u8) !u64 {
    return try std.fmt.parseInt(u64, ws[1..], 10);
}

const testing = std.testing;
test toWord {
    var buffer: [6]u8 = undefined;
    const word = try toWord(&buffer, 123);

    try testing.expectEqualSlices(u8, "W00123", word);
}
