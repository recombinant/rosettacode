// https://rosettacode.org/wiki/Juggler_sequence
// {{works with|Zig|0.15.1}}
// {{trans|Go}}
const std = @import("std");

const Int = std.math.big.int.Managed;

pub fn main() !void {
    // --------------------------------------------------- allocators
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();
    // --------------------------------------------------------------
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    {
        try stdout.writeAll("n    l[n]  i[n]  h[n]\n");
        try stdout.writeAll("-----------------------------------\n");
        var n: u8 = 20;
        while (n < 40) : (n += 1) {
            const count, const max_count, var max = try juggler(allocator, n);
            const s = try max.toString(arena_allocator, 10, .lower);
            try stdout.print("{d}    {d:2}   {d:2}    {s}\n", .{ n, count, max_count, s });
            try stdout.flush();
            _ = arena.reset(.retain_capacity);
            max.deinit();
        }
    }
    try stdout.writeByte('\n');
    {
        const nums = [_]u32{
            113, 173, 193, 2183, 11229, 15065, 15845, 30817,
            // TODO: when Zig bit integers are faster...
            // // Zig 0.14 big integer implementation is too slow
            // // to calculate these numbers compared to GMP.
            // 48443, 275485, 1267909, 2264915, 5812827, 7110201,
            // 56261531, 92502777, 172376627, 604398963,
        };
        try stdout.writeAll("      n        l[n]   i[n]   d[n]\n");
        try stdout.writeAll("-------------------------------------\n");
        for (nums) |n| {
            const count, const max_count, var max = try juggler(allocator, n);
            const s = try max.toString(arena_allocator, 10, .lower);
            try stdout.print("{d:11}    {d:3}    {d:3}    {d}\n", .{ n, count, max_count, s.len });
            try stdout.flush();
            _ = arena.reset(.retain_capacity);
            max.deinit();
        }
    }
    try stdout.flush();
}
fn juggler(allocator: std.mem.Allocator, n: anytype) !struct { usize, usize, Int } {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("juggler() expected unsigned integer argument, found " ++ @typeName(T));

    var count: usize = 0;
    var max_count: usize = 0;

    var one: Int = try .initSet(allocator, 1);
    defer one.deinit();
    var two: Int = try .initSet(allocator, 2);
    defer two.deinit();

    var a: Int = try .initSet(allocator, n);
    var max: Int = try .initSet(allocator, n);
    var q: Int = try .init(allocator);
    var r: Int = try .init(allocator);
    var rma1: Int = try .init(allocator);
    var rma2: Int = try .init(allocator);
    defer a.deinit();
    defer q.deinit();
    defer r.deinit();
    defer rma1.deinit();
    defer rma2.deinit();

    while (!a.eql(one)) {
        try Int.divTrunc(&q, &r, &a, &two);

        if (r.eqlZero()) {
            try Int.sqrt(&rma1, &a);
            try a.copy(rma1.toConst());
        } else {
            try Int.sqr(&rma1, &a);
            try Int.mul(&rma2, &rma1, &a);
            try Int.sqrt(&a, &rma2);
        }
        count += 1;
        if (a.order(max) == .gt) {
            try max.copy(a.toConst());
            max_count = count;
        }
    }
    return .{ count, max_count, max };
}
