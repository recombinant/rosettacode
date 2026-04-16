// https://rosettacode.org/wiki/Ternary_logic
// {{works with|Zig|0.16.0}}
// {{trans|C}}

// translation of C's "Using functions" solution
const std = @import("std");
const Io = std.Io;

const Trit = enum(i2) {
    F = -1,
    @"?" = 0,
    T = 1,

    fn not(a: Trit) Trit {
        return @enumFromInt(-@intFromEnum(a));
    }
    fn @"and"(a: Trit, b: Trit) Trit {
        return if (@intFromEnum(a) < @intFromEnum(b)) a else b;
    }
    fn @"or"(a: Trit, b: Trit) Trit {
        return if (@intFromEnum(a) > @intFromEnum(b)) a else b;
    }
    fn eq(a: Trit, b: Trit) Trit {
        return @enumFromInt(@intFromEnum(a) * @intFromEnum(b));
    }
    fn imply(a: Trit, b: Trit) Trit {
        return if (-@intFromEnum(a) > @intFromEnum(b)) @enumFromInt(-@intFromEnum(a)) else b;
    }
};

fn showOp(f: *const fn (Trit, Trit) Trit, name: []const u8, w: *Io.Writer) !void {
    try w.print("\n[{s}]\n    F ? T\n  -------", .{name});

    // for all the combinations of values
    inline for (@typeInfo(Trit).@"enum".fields) |field_a| {
        try w.print("\n{s} |", .{field_a.name});

        inline for (@typeInfo(Trit).@"enum".fields) |field_b| {
            try w.print(" {t}", .{f(@enumFromInt(field_a.value), @enumFromInt(field_b.value))});
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
    inline for (@typeInfo(Trit).@"enum".fields) |field| {
        try stdout.print("{s} | {t}\n", .{ field.name, Trit.not(@enumFromInt(field.value)) });
    }
    // and, or, eq & imply
    try showOp(Trit.@"and", "And", stdout);
    try showOp(Trit.@"or", "Or", stdout);
    try showOp(Trit.eq, "Equiv", stdout);
    try showOp(Trit.imply, "Imply", stdout);

    try stdout.flush();
}
