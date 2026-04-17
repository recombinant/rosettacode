// https://rosettacode.org/wiki/String_length
// {{works with|Zig|0.16.0}}
// Copied from rosettacode
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

fn printResults(alloc: Allocator, string: []const u8, w: *Io.Writer) !void {
    try w.print("String: \"{s}\"\n", .{string});

    const cnt_codepts_utf8 = try std.unicode.utf8CountCodepoints(string);
    // There is no sane and portable extended ascii, so the best
    // we get is counting the bytes and assume regular ascii.
    const cnt_bytes_utf8 = string.len;
    try w.print("utf8  codepoints = {d}, bytes = {d}\n", .{ cnt_codepts_utf8, cnt_bytes_utf8 });

    const utf16str = try std.unicode.utf8ToUtf16LeAllocZ(alloc, string);
    const cnt_codepts_utf16 = try std.unicode.utf16CountCodepoints(utf16str);
    const cnt_2bytes_utf16 = try std.unicode.calcUtf16LeLen(string);
    try w.print("utf16 codepoints = {d}, bytes = {d}\n\n", .{ cnt_codepts_utf16, 2 * cnt_2bytes_utf16 });
    try w.flush();
}

pub fn main(init: std.process.Init) !void {
    const allocator: Allocator = init.arena.allocator();
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    const string1: []const u8 = "Hello, world!";
    try printResults(allocator, string1, stdout);
    const string2: []const u8 = "møøse";
    try printResults(allocator, string2, stdout);
    const string3: []const u8 = "𝔘𝔫𝔦𝔠𝔬𝔡𝔢";
    try printResults(allocator, string3, stdout);
    // \u{332} is underscore of previous character, which the browser may not
    // copy correctly
    const string4: []const u8 = "J\u{332}o\u{332}s\u{332}e\u{301}\u{332}";
    try printResults(allocator, string4, stdout);
}
