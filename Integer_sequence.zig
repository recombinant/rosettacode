// https://rosettacode.org/wiki/Integer_sequence
// copied from rosettacode
const std = @import("std");

pub fn main() !void {
    const writer = std.io.getStdOut().writer();

    // Using an integer primitive

    var i: u5 = 0;
    while (true) : (i += 1) {
        try writer.print("{}", .{i});
        if (i == std.math.maxInt(@TypeOf(i)))
            break;
        try writer.writeAll(", ");
    }
    try writer.writeByte('\n');

    // Using a big integer

    // --------------------------------------------------- allocators
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator1 = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator2 = arena.allocator();
    // --------------------------------------------------------------
    const Int = std.math.big.int.Managed;

    var number = try Int.init(allocator1);
    var r = try Int.init(allocator1);
    var one = try Int.initSet(allocator1, 1);
    defer number.deinit();
    defer r.deinit();
    defer one.deinit();

    while (true) {
        _ = arena.reset(.retain_capacity);
        const s = try number.toString(allocator2, 10, .lower);
        try writer.print("{s}, ", .{s});
        try r.add(&number, &one);
        std.mem.swap(Int, &r, &number);
    }
}
