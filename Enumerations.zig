// https://rosettacode.org/wiki/Enumerations
// {{works with|Zig|0.17.0}}
const std = @import("std");

pub fn main() void {
    const FruitTag = enum {
        apple,
        banana,
        cherry,
    };
    const info_fruit = @typeInfo(FruitTag).@"enum";
    inline for (info_fruit.field_names, info_fruit.field_values) |field_name, field_value|
        std.debug.print("{s:6}: {}\n", .{ field_name, field_value });

    std.debug.print("\nBanana:\n", .{});
    const fruit = FruitTag.banana;
    std.debug.print(" Enum Type: {}\n", .{@TypeOf(fruit)});
    std.debug.print("       Tag: {}\n", .{fruit});
    std.debug.print("  Tag Type: {}\n", .{@typeInfo(@TypeOf(fruit)).@"enum".tag_type});
    std.debug.print("  Tag Name: {t}\n", .{fruit});
    std.debug.print(" Tag Value: {}\n", .{@backingInt(fruit)});

    const ApeTag = enum(u8) {
        gorilla = 0,
        chimpanzee = 3,
        orangutan = 5,
    };
    std.debug.print("\n-----------------\n", .{});
    const info_ape = @typeInfo(ApeTag).@"enum";
    inline for (info_ape.field_names, info_ape.field_values) |field_name, field_value|
        std.debug.print("{s:10}: {}\n", .{ field_name, field_value });

    const ape = ApeTag.chimpanzee;
    std.debug.print("\nChimpanzee:\n", .{});
    std.debug.print(" Enum Type: {}\n", .{@TypeOf(ape)});
    std.debug.print("       Tag: {}\n", .{ape});
    std.debug.print("  Tag Type: {}\n", .{@typeInfo(@TypeOf(ape)).@"enum".tag_type});
    std.debug.print("  Tag Name: {t}\n", .{ape});
    std.debug.print(" Tag Value: {}\n", .{@backingInt(ape)});
}
