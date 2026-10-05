// https://rosettacode.org/wiki/Inconsummate_numbers_in_base_10
// {{works with|Zig|0.17.0}}
// {{trans|C++}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const SIEVE_SIZE = 10_000;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;

    var is_consummate: std.StaticBitSet(SIEVE_SIZE + 1) = .empty;
    try createIsConsummate(&is_consummate);

    var inconsummates: std.ArrayList(u32) = .empty;
    defer inconsummates.deinit(gpa);

    for (0..SIEVE_SIZE + 1) |i|
        if (!is_consummate.isSet(i))
            try inconsummates.append(gpa, @truncate(i));

    try stdout.writeAll("The first 50 inconsummate numbers in base 10:\n");
    for (1..51) |i| {
        try stdout.printInt(inconsummates.items[i], 10, .lower, .{ .width = 3 });
        try stdout.writeByte(if (i % 10 == 0) '\n' else ' ');
    }

    try stdout.print("\nThe 1,000th inconsummate number is {d}\n", .{inconsummates.items[1_000]});

    try stdout.flush();
}

fn createIsConsummate(is_consummate: *std.StaticBitSet(SIEVE_SIZE + 1)) !void {
    const maximum: usize = @as(usize, 9) * (std.math.log10_int(@as(usize, SIEVE_SIZE)) + 1) * SIEVE_SIZE;
    var n: usize = 1;
    while (n < maximum) : (n += 1) {
        const sum = try digitalSum(n);
        if (n % sum == 0) {
            const quotient = n / sum;
            if (quotient <= SIEVE_SIZE)
                is_consummate.set(quotient);
        }
    }
}

fn digitalSum(number: anytype) !@TypeOf(number) {
    const T = @TypeOf(number);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("isdigitalSum() expected unsigned integer argument, found " ++ @typeName(T));

    var result: T = 0;
    var buffer: [128]u8 = undefined;
    var w: Io.Writer = .fixed(&buffer);
    try w.printIntAny(number, 10, .lower, .{});
    for (w.buffered()) |ch|
        result += ch - '0';
    return result;
}
