// https://rosettacode.org/wiki/Ternary_logic
// {{works with|Zig|0.17.0}}
// {{trans|C}}

// translation of C's "Using functions" solution
const std = @import("std");
const Io = std.Io;

const Trit = enum(i2) {
    F = -1,
    @"?" = 0,
    T = 1,

    fn not(a: Trit) Trit {
        return @fromBackingInt(-@backingInt(a));
    }
    fn @"and"(a: Trit, b: Trit) Trit {
        return if (@backingInt(a) < @backingInt(b)) a else b;
    }
    fn @"or"(a: Trit, b: Trit) Trit {
        return if (@backingInt(a) > @backingInt(b)) a else b;
    }
    fn eq(a: Trit, b: Trit) Trit {
        return @fromBackingInt(@backingInt(a) * @backingInt(b));
    }
    fn imply(a: Trit, b: Trit) Trit {
        return if (-@backingInt(a) > @backingInt(b)) @fromBackingInt(-@backingInt(a)) else b;
    }
};

fn showOp(f: *const fn (Trit, Trit) Trit, name: []const u8, w: *Io.Writer) !void {
    try w.print("\n[{s}]\n    F ? T\n  -------", .{name});

    const info = comptime @typeInfo(Trit).@"enum";
    // for all the combinations of values
    inline for (info.field_names, info.field_values) |name_a, value_a| {
        try w.print("\n{s} |", .{name_a});

        inline for (info.field_values) |value_b| {
            try w.print(" {t}", .{f(@fromBackingInt(value_a), @fromBackingInt(value_b))});
        }
    }
    try w.writeByte('\n');
}

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;
    // ------------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    // --------------------------------------------------------------
    // not
    try stdout.writeAll("[Not]\n");

    const info = comptime @typeInfo(Trit).@"enum";
    inline for (info.field_names, info.field_values) |name, value| {
        try stdout.print("{s} | {t}\n", .{ name, Trit.not(@fromBackingInt(value)) });
    }
    // and, or, eq & imply
    try showOp(Trit.@"and", "And", stdout);
    try showOp(Trit.@"or", "Or", stdout);
    try showOp(Trit.eq, "Equiv", stdout);
    try showOp(Trit.imply, "Imply", stdout);

    try stdout.flush();
}
