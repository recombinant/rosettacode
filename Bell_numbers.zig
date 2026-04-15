// https://rosettacode.org/wiki/Bell_numbers
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    const rows = 50;
    const bt = bellTriangle(rows);
    const slice = &bt;

    try stdout.writeAll("First fifteen and fiftieth Bell numbers:\n");
    for (1..15 + 1) |i|
        try stdout.print("{d:2}: {d}\n", .{ i, getBell(slice, i, 0) });
    try stdout.print("{d:2}: {d}\n", .{ 50, getBell(slice, 50, 0) });

    try stdout.writeByte('\n');
    try stdout.writeAll("The first ten rows of Bell's triangle:\n");
    for (1..10 + 1) |i| {
        try stdout.print("{d:5}", .{getBell(slice, i, 0)});
        for (1..i) |j|
            try stdout.print(", {d:5}", .{getBell(slice, i, j)});
        try stdout.writeByte('\n');
    }

    try stdout.flush();
}

/// row starts with 1; col < row
fn bellIndex(row: usize, col: usize) usize {
    return row * (row - 1) / 2 + col;
}

fn getBell(bell_tri: []const u256, row: usize, col: usize) u256 {
    const index = bellIndex(row, col);
    return bell_tri[index];
}

fn setBell(bell_tri: []u256, row: usize, col: usize, value: u256) void {
    const index = bellIndex(row, col);
    bell_tri[index] = value;
}

fn length(comptime n: usize) usize {
    return n * (n + 1) / 2;
}

fn bellTriangle(comptime n: usize) [length(n)]u256 {
    var tri: [length(n)]u256 = undefined;
    const slice = &tri;

    setBell(slice, 1, 0, 1);
    for (2..n + 1) |i| {
        setBell(slice, i, 0, getBell(slice, i - 1, i - 2));
        for (1..i) |j| {
            const value = getBell(slice, i, j - 1) + getBell(slice, i - 1, j - 1);
            setBell(slice, i, j, value);
        }
    }
    return tri;
}
