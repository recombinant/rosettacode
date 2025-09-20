// https://rosettacode.org/wiki/Digital_root
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    // try stdout.print("{}\n", .{@as(u64, 1) / @as(u64, 10)});
    const numbers = [_]u64{ 627615, 39390, 588225, 393900588225 };

    for (numbers) |n| {
        const p, const d = calcDigitalRoot2(n, 10);
        try stdout.print("{}: pers {}, root {}\n", .{ n, p, d });
    }
    try stdout.writeByte('\n');

    for (numbers) |n|
        try stdout.print("{}: root {}\n", .{ n, calcDigitalRoot(n, 10) });

    try stdout.flush();
}

/// Calculate the additive persistence and the digital root.
fn calcDigitalRoot2(n_: u64, base: u8) struct { u64, u64 } {
    var n = n_;
    var d: u64 = undefined;
    var p: u64 = 0;

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
fn calcDigitalRoot(n: u64, base: u8) u64 {
    if (n == 0)
        return 0;

    const d: u64 = n % (base - 1);
    if (d != 0)
        return d;

    return base - 1;
}
