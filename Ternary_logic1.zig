// https://rosettacode.org/wiki/Ternary_logic
// {{works with|Zig|0.17.0}}
// {{trans|C}}

// translation of C's "Implementing logic using lookup tables" solution
const std = @import("std");
const Io = std.Io;

const Trit = enum {
    TRITTRUE, // equivalent to integer value 0
    TRITMAYBE, // equivalent to integer value 1
    TRITFALSE, // equivalent to integer value 2

    fn asString(value: Trit) []const u8 {
        return switch (value) {
            .TRITTRUE => "T",
            .TRITMAYBE => "?",
            .TRITFALSE => "F",
        };
    }

    // We can trivially find the result of the operation by passing
    // the trinary values as indices into the lookup tables' arrays.
    const not: [3]Trit = .{ .TRITFALSE, .TRITMAYBE, .TRITTRUE };
    const @"and": [3][3]Trit = .{
        .{ .TRITTRUE, .TRITMAYBE, .TRITFALSE },
        .{ .TRITMAYBE, .TRITMAYBE, .TRITFALSE },
        .{ .TRITFALSE, .TRITFALSE, .TRITFALSE },
    };
    const @"or": [3][3]Trit = .{
        .{ .TRITTRUE, .TRITTRUE, .TRITTRUE },
        .{ .TRITTRUE, .TRITMAYBE, .TRITMAYBE },
        .{ .TRITTRUE, .TRITMAYBE, .TRITFALSE },
    };
    const then: [3][3]Trit = .{
        .{ .TRITTRUE, .TRITMAYBE, .TRITFALSE },
        .{ .TRITTRUE, .TRITMAYBE, .TRITMAYBE },
        .{ .TRITTRUE, .TRITTRUE, .TRITTRUE },
    };
    const equiv: [3][3]Trit = .{
        .{ .TRITTRUE, .TRITMAYBE, .TRITFALSE },
        .{ .TRITMAYBE, .TRITMAYBE, .TRITMAYBE },
        .{ .TRITFALSE, .TRITMAYBE, .TRITTRUE },
    };
};

fn demoBinaryOp(operator: [3][3]Trit, op_name: []const u8, w: *Io.Writer) !void {
    try w.writeByte('\n');

    const info = comptime @typeInfo(Trit).@"enum";
    inline for (info.field_values) |value1| {
        inline for (info.field_values) |value2| {
            try w.print("{s} {s} {s}: {s}\n", .{
                @as(Trit, @fromBackingInt(value1)).asString(),
                op_name,
                @as(Trit, @fromBackingInt(value2)).asString(),
                operator[value1][value2].asString(),
            });
        }
    }
}

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;
    // ------------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    // --------------------------------------------------------------

    // Demo unary operator 'not'
    inline for (@typeInfo(Trit).@"enum".field_values) |idx| {
        const value: Trit = @fromBackingInt(idx);
        try stdout.print(
            "Not {s}: {s}\n",
            .{ value.asString(), Trit.not[idx].asString() },
        );
    }
    try demoBinaryOp(Trit.@"and", "And", stdout);
    try demoBinaryOp(Trit.@"or", "Or", stdout);
    try demoBinaryOp(Trit.then, "Then", stdout);
    try demoBinaryOp(Trit.equiv, "Equiv", stdout);

    try stdout.flush();
}
