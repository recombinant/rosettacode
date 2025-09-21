// https://rosettacode.org/wiki/Leonardo_numbers
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

// --------------------------------------- normal leonardo series
// Enter first two Leonardo numbers and increment step : 1 1 1
// First 25 Leonardo numbers :
//  1 1 3 5 9 15 25 41 67 109 177 287 465 753 1219 1973 3193 5167 8361 13529 21891 35421 57313 92735 150049

// --------------------------------------------- fibonacci series
// Enter first two Leonardo numbers and increment step : 0 1 0
// First 25 Leonardo numbers :
//  0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610 987 1597 2584 4181 6765 10946 17711 28657 46368

// --------------------------------------------------------------
pub fn main() !void {
    var stdin_buffer: [1024]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll("Enter first two Leonardo numbers and increment step : ");
    try stdout.flush();

    var buffer1: [1024]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buffer1);

    _ = try stdin.streamDelimiter(&w, '\n');
    const line = w.buffered();

    var buffer2: [3]u64 = undefined;
    var array: std.ArrayList(u64) = .initBuffer(&buffer2);

    var it = std.mem.splitAny(u8, line, " \t\r\n");
    while (it.next()) |word| {
        if (word.len == 0)
            continue;
        const number = try std.fmt.parseInt(u64, word, 10);
        array.appendBounded(number) catch return error.TooManyNumbers;
    }
    if (array.items.len != 3) return error.InsufficientNumbers;

    const a = array.items[0];
    const b = array.items[1];
    const step = array.items[2];

    try leonardo(a, b, step, 25, stdout);

    try stdout.flush();
}

fn leonardo(a_: u64, b_: u64, step: u64, num: u64, w: *std.Io.Writer) !void {
    var a = a_;
    var b = b_;

    try w.writeAll("First 25 Leonardo numbers : \n");

    var i: u64 = 1;
    while (i <= num) : (i += 1) {
        switch (i) {
            1 => try w.print(" {d}", .{a}),
            2 => try w.print(" {d}", .{b}),
            else => {
                try w.print(" {d}", .{a + b + step});
                std.mem.swap(u64, &a, &b);
                b += a + step;
            },
        }
    }
}
