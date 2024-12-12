// https://rosettacode.org/wiki/Chowla_numbers
const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const max_chars = comptime maxDecimalCommatized(usize);
    var buffer1: [max_chars]u8 = undefined;
    var buffer2: [max_chars]u8 = undefined;

    {
        for (1..38) |i|
            print("chowla({}) = {}\n", .{ i, chowla(i) });
    }
    {
        const limit = 10_000_000;
        var count: usize = @intFromBool(chowla(2) == 0);
        var power: usize = 100;
        var i: usize = 3;
        while (i < limit) : (i += 2) {
            if (chowla(i) == 0)
                count += 1;

            if (i % (power - 1) == 0) {
                print(
                    "Count of primes up to {s} = {s}\n",
                    .{
                        try commatize(&buffer1, power),
                        try commatize(&buffer2, count),
                    },
                );
                power *= 10;
            }
        }
    }
    {
        const limit: usize = 35_000_000;
        var count: usize = 0;
        var k: usize = 2;
        var kk: usize = 3;

        while (true) {
            const p = k * kk;
            if (p > limit) break;
            if (chowla(p) == (p - 1)) {
                print(
                    "{s} is a number that is perfect\n",
                    .{
                        try commatize(&buffer1, p),
                    },
                );
                count += 1;
            }
            k = kk + 1;
            kk += k;
        }
        print(
            "There are {s} perfect numbers <= {s}\n",
            .{
                try commatize(&buffer1, count),
                try commatize(&buffer2, limit),
            },
        );
    }
}

fn chowla(n: usize) usize {
    if (n < 4)
        return 0;
    var sum: usize = 0;
    var i: usize = 2;
    while ((i * i) <= n) : (i += 1)
        if (n % i == 0) {
            const j = n / i;
            sum += i + if (i == j) 0 else j;
        };
    return sum;
}

fn commatize(buffer1: []u8, n: anytype) ![]const u8 {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("commatize() expected unsigned integer type argument, found " ++ @typeName(T));
    // number as string without commas
    var buffer2: [maxDecimalChars(T)]u8 = undefined;
    const size = std.fmt.formatIntBuf(&buffer2, n, 10, .lower, .{});
    const s = buffer2[0..size];
    //
    var stream = std.io.fixedBufferStream(buffer1);
    const writer = stream.writer();
    // write number string as string with inserted commas
    const last = s.len - 1;
    for (s, 0..) |c, idx| {
        try writer.writeByte(c);
        if (last - idx != 0 and (last - idx) % 3 == 0)
            try writer.writeByte(',');
    }
    return stream.getWritten();
}

fn maxDecimalCommatized(T: type) usize {
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("maxDecimalCommatized() expected unsigned integer type argument, found " ++ @typeName(T));
    return maxDecimalChars(T) + maxDecimalCommas(T);
}

/// Return the maximum number of characters in a string representing a decimal of type T.
fn maxDecimalChars(T: type) usize {
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("maxDecimalChars() expected unsigned integer type argument, found " ++ @typeName(T));
    const max_int: comptime_float = @floatFromInt(std.math.maxInt(T));
    return @intFromFloat(@log10(max_int) + 1);
}

/// Return the maximum number of commas in a 'commatized' string representing a decimal of type T.
fn maxDecimalCommas(T: type) usize {
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("maxDecimalCommas() expected unsigned integer type argument, found " ++ @typeName(T));
    return (maxDecimalChars(T) - 1) / 3;
}
