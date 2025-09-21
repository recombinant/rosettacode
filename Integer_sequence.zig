// https://rosettacode.org/wiki/Integer_sequence
// {{works with|Zig|0.15.1}}

// copied from rosettacode
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    // Using an integer primitive

    var i: u5 = 0;
    while (true) : (i += 1) {
        try stdout.print("{}", .{i});
        if (i == std.math.maxInt(@TypeOf(i)))
            break;
        try stdout.writeAll(", ");
    }
    try stdout.writeByte('\n');

    // Using a big integer

    // --------------------------------------------------- allocators
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator1 = gpa.allocator();
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator2 = arena.allocator();
    // --------------------------------------------------------------
    const Int = std.math.big.int.Managed;

    var number: Int = try .init(allocator1);
    var r: Int = try .init(allocator1);
    var one: Int = try .initSet(allocator1, 1);
    defer number.deinit();
    defer r.deinit();
    defer one.deinit();

    while (true) {
        _ = arena.reset(.retain_capacity);
        const s = try number.toString(allocator2, 10, .lower);
        try stdout.print("{s}, ", .{s});
        try r.add(&number, &one);
        std.mem.swap(Int, &r, &number);
    }

    try stdout.flush();
}
