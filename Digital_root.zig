// https://rosettacode.org/wiki/Digital_root
// {{works with|Zig|0.17.1}}
// {{trans|C}}
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout_writer = &stdout_file.interface;

    const numbers = [_]u64{ 627_615, 39_390, 588_225, 393_900_588_225 };

    for (numbers) |n| {
        const p, const d = calcDigitalRoot2(n, 10);
        try stdout_writer.print("{}: pers {}, root {}\n", .{ n, p, d });
    }
    try stdout_writer.writeByte('\n');

    for (numbers) |n|
        try stdout_writer.print("{}: root {}\n", .{ n, calcDigitalRoot(n, 10) });

    try stdout_writer.flush();
}

/// Calculate the additive persistence and the digital root.
fn calcDigitalRoot2(n_: anytype, base: u8) struct { @TypeOf(n_), @TypeOf(n_) } {
    const T = @TypeOf(n_);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("calcDigitalRoot2() expected unsigned integer argument, found " ++ @typeName(T));

    var n = n_;
    var d: T = undefined;
    var p: T = 0;

    while (n >= base) : ({
        n = d;
        p += 1;
    }) {
        d = 0;
        while (n != 0) {
            d += n % base;
            n /= base;
        }
    }
    return .{ p, d };
}

/// Calculate just the digital root.
fn calcDigitalRoot(n: anytype, base: u8) @TypeOf(n) {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("calcDigitalRoot() expected unsigned integer argument, found " ++ @typeName(T));

    if (n == 0)
        return 0;

    const d: T = n % (base - 1);
    if (d != 0)
        return d;

    return base - 1;
}
