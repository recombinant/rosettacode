// https://rosettacode.org/wiki/Trabb_Pardo%E2%80%93Knuth_algorithm
// {{works with|Zig|0.15.1}}
const std = @import("std");

// Please enter 11 numbers : 10 -1 1 2 3 4 4.3 4.305 4.303 4.302 4.301
// f( 4.3010) = 399.8863
// f( 4.3020) = Overflow!
// f( 4.3030) = Overflow!
// f( 4.3050) = Overflow!
// f( 4.3000) = 399.6086
// f( 4.0000) = 322.0000
// f( 3.0000) = 136.7321
// f( 2.0000) =  41.4142
// f( 1.0000) =   6.0000
// f(-1.0000) =  -4.0000
// f(10.0000) = Overflow!

pub fn main() !void {
    const overflow_value = 400;

    var stdin_buffer: [1024]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll("Please enter 11 numbers : ");
    try stdout.flush();

    var buffer1: [1024]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buffer1);

    _ = try stdin.streamDelimiter(&w, '\n');
    const line = w.buffered();

    var buffer2: [11]f64 = undefined;
    var a: std.ArrayList(f64) = .initBuffer(&buffer2);
    var it = std.mem.splitAny(u8, line, " \t\r\n");
    while (it.next()) |word| {
        if (word.len == 0)
            continue;
        const number = try std.fmt.parseFloat(f64, word);
        a.appendBounded(number) catch return error.TooManyNumbers;
    }
    if (a.items.len != 11) return error.InsufficientNumbers;

    std.mem.reverse(f64, a.items);
    for (a.items) |n| {
        const result = @sqrt(@abs(n)) + 5 * std.math.pow(f64, n, 3);

        try stdout.print("f({d:7.4}) = ", .{n});

        if (result > overflow_value)
            try stdout.writeAll("Overflow!\n")
        else
            try stdout.print("{d:8.4}\n", .{result});
    }

    try stdout.flush();
}
