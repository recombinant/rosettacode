// https://rosettacode.org/wiki/Ternary_logic
// {{works with|Zig|0.16.0}}
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

fn demoBinaryOp(operator: [3][3]Trit, name: []const u8, w: *Io.Writer) !void {
    try w.writeByte('\n');

    inline for (@typeInfo(Trit).@"enum".fields) |field1| {
        const value1: Trit = @enumFromInt(field1.value);
        inline for (@typeInfo(Trit).@"enum".fields) |field2| {
            const value2: Trit = @enumFromInt(field2.value);

            const idx1 = @intFromEnum(value1); // to show @intFromEnum()
            const idx2 = @intFromEnum(value2);

            try w.print("{s} {s} {s}: {s}\n", .{
                value1.asString(),
                name,
                value2.asString(),
                operator[idx1][idx2].asString(),
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
    inline for (@typeInfo(Trit).@"enum".fields) |field| {
        const idx = field.value;
        const value: Trit = @enumFromInt(field.value);
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
