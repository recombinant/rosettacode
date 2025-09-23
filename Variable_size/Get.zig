// https://rosettacode.org/wiki/Variable_size/Get
// {{works with|Zig|0.15.1}}
const std = @import("std");

const print = std.debug.print;

pub fn main() void {
    print("comptime_int   = {d} bytes\n", .{@sizeOf(comptime_int)});
    print("comptime_int   = {d} bytes\n", .{@sizeOf(@TypeOf(2))});
    print("comptime_float = {d} bytes\n", .{@sizeOf(comptime_float)});
    print("comptime_float = {d} bytes\n", .{@sizeOf(@TypeOf(3.14))});

    inline for ([_]type{ bool, u1, i1, u8, i8 }) |T|
        print("{s:<5}= {d} byte\n", .{ @typeName(T), @sizeOf(T) });
    inline for ([_]type{ u64, c_int, f16, f32, f64, f80, f128 }) |T|
        print("{s:<5}= {d} bytes\n", .{ @typeName(T), @sizeOf(T) });

    for (0..1) |i|
        print("\nusize  = {d} bytes\n", .{@sizeOf(@TypeOf(i))});

    print("\nThree different examples of struct {{ b1: bool, x: i32, b2: bool, y: i32 }}\n", .{});
    print("       struct = {d} bytes\n", .{@sizeOf(struct { b1: bool, x: i32, b2: bool, y: i32 })});
    print("extern struct = {d} bytes\n", .{@sizeOf(extern struct { b1: bool, x: i32, b2: bool, y: i32 })});
    print("packed struct = {d} bytes\n", .{@sizeOf(packed struct { b1: bool, x: i32, b2: bool, y: i32 })});
}
