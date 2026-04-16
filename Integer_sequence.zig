// https://rosettacode.org/wiki/Integer_sequence
// {{works with|Zig|0.16.0}}

// copied from rosettacode
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    // --------------------------------------------------- allocators
    // This arena is reset repeatedly. Used for ephemerals in the big integer loop.
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const arena_allocator: Allocator = arena.allocator();

    // This allocator is used for items outside the big integer loop.
    const gpa: Allocator = init.gpa;

    // --------------------------------------------------------------
    // Using an integer primitive
    var i: u5 = 0;
    while (true) : (i += 1) {
        try stdout.print("{}", .{i});
        if (i == std.math.maxInt(@TypeOf(i)))
            break;
        try stdout.writeAll(", ");
    }
    try stdout.writeByte('\n');
    try stdout.writeByte('\n');
    try stdout.flush();

    // --------------------------------------------------------------
    // Using a big integer
    const Int = std.math.big.int.Managed;

    var number: Int = try .init(gpa);
    var r: Int = try .init(gpa);
    var one: Int = try .initSet(gpa, 1);
    defer number.deinit();
    defer r.deinit();
    defer one.deinit();

    // The loop is infinite, but the program can be stopped with Ctrl-C.
    while (true) {
        _ = arena.reset(.retain_capacity);
        const s = try number.toString(arena_allocator, 10, .lower);
        try stdout.print("{s}, ", .{s});
        try r.add(&number, &one);
        std.mem.swap(Int, &r, &number);
    }

    try stdout.flush();
}
