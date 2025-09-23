// https://rosettacode.org/wiki/Sort_an_array_of_composite_structures
// {{works with|Zig|0.15.1}}
const std = @import("std");

const Entry = struct {
    name: []const u8,
    value: f64,

    fn init(name: []const u8, value: f64) Entry {
        return .{ .name = name, .value = value };
    }

    fn lessThan(_: void, a: Entry, b: Entry) bool {
        return std.mem.order(u8, a.name, b.name) == std.math.Order.lt;
    }
};

pub fn main() void {
    var elements = [_]Entry{
        .init("Krypton", 83.798),   .init("Beryllium", 9.012182), .init("Silicon", 28.0855),
        .init("Cobalt", 58.933195), .init("Selenium", 78.96),     .init("Germanium", 72.64),
    };

    // Several sort algorithms are also available in std.sort
    std.mem.sortUnstable(Entry, &elements, {}, Entry.lessThan);

    for (elements) |e|
        std.debug.print("{s:<9} {d}\n", .{ e.name, e.value });
}
