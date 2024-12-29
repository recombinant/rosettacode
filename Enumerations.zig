// https://rosettacode.org/wiki/Enumerations
const std = @import("std");

pub fn main() void {
    const FruitTag = enum {
        apple,
        banana,
        cherry,
    };
    inline for (std.meta.fields(FruitTag)) |field|
        std.debug.print("{s:6}: {}\n", .{ field.name, field.value });

    std.debug.print("\nBanana:\n", .{});
    const fruit = FruitTag.banana;
    std.debug.print(" Enum Type: {}\n", .{@TypeOf(fruit)});
    std.debug.print("       Tag: {}\n", .{fruit});
    std.debug.print("  Tag Type: {}\n", .{@typeInfo(@TypeOf(fruit)).@"enum".tag_type});
    std.debug.print("  Tag Name: {s}\n", .{@tagName(fruit)});
    std.debug.print(" Tag Value: {}\n", .{@intFromEnum(fruit)});

    const ApeTag = enum(u8) {
        gorilla = 0,
        chimpanzee = 3,
        orangutan = 5,
    };
    std.debug.print("\n-----------------\n", .{});
    inline for (std.meta.fields(ApeTag)) |field|
        std.debug.print("{s:10}: {}\n", .{ field.name, field.value });

    const ape = ApeTag.chimpanzee;
    std.debug.print("\nChimpanzee:\n", .{});
    std.debug.print(" Enum Type: {}\n", .{@TypeOf(ape)});
    std.debug.print("       Tag: {}\n", .{ape});
    std.debug.print("  Tag Type: {}\n", .{@typeInfo(@TypeOf(ape)).@"enum".tag_type});
    std.debug.print("  Tag Name: {s}\n", .{@tagName(ape)});
    std.debug.print(" Tag Value: {}\n", .{@intFromEnum(ape)});
}
