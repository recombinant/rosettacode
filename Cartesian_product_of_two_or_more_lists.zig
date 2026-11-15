// https://rosettacode.org/wiki/Cartesian_product_of_two_or_more_lists
// {{works with|Zig|0.17.1}}
// {{trans|Crow}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const Writer = Io.Writer;

/// The n-ary examples are read from the task's own notation.
pub fn main(init: std.process.Init) !void {
    const allocator: Allocator = init.gpa;
    const io: Io = init.io;
    // --------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_file.interface;
    // ----------------------------------------------------------
    try showProduct(allocator, u8, &.{ 1, 2 }, &.{ 3, 4 }, stdout);
    try showProduct(allocator, u8, &.{ 3, 4 }, &.{ 1, 2 }, stdout);
    try showProduct(allocator, u8, &.{ 1, 2 }, &.{}, stdout);
    try showProduct(allocator, u8, &.{}, &.{ 1, 2 }, stdout);

    try stdout.writeByte('\n');

    try stdout.writeAll("The n-ary product:\n");
    try showNaryProduct(allocator, "{1776, 1789} × {7, 12} × {4, 14, 23} × {0, 1}", u16, stdout);
    try showNaryProduct(allocator, "{1, 2, 3} × {30} × {500, 100}", u16, stdout);
    try showNaryProduct(allocator, "{1, 2, 3} × {} × {500, 100}", u16, stdout);
    // ----------------------------------------------------------
    try stdout.flush();
}

fn showProduct(allocator: Allocator, T: type, xs: []const T, ys: []const T, w: *Writer) !void {
    try writeEnclosed(T, xs, '{', '}', w); // left
    try w.writeAll(" × ");
    try writeEnclosed(T, ys, '{', '}', w); // right

    try w.writeAll(" = ");

    const pairs_wrapper: Jagged2DArrayWrapper(T) = try calcProduct(allocator, T, xs, ys);
    defer pairs_wrapper.deinit(allocator);
    const pairs = pairs_wrapper.array;

    try writeTuples(T, pairs, w);

    try w.writeByte('\n');
}
fn showNaryProduct(allocator: Allocator, text: []const u8, T: type, w: *Writer) !void {
    const lists_wrapper: Jagged2DArrayWrapper(T) = try parseSets(allocator, text, T);
    defer lists_wrapper.deinit(allocator);

    const lists = lists_wrapper.array;
    if (lists.len != 0) {
        try writeEnclosed(T, lists[0], '{', '}', w);
        for (lists[1..]) |xs| {
            try w.writeAll(" × ");
            try writeEnclosed(T, xs, '{', '}', w);
        }
    }
    try w.writeAll(" = ");

    const tuples_wrapper: Jagged2DArrayWrapper(T) = try calcNaryProduct(allocator, T, lists);
    defer tuples_wrapper.deinit(allocator);
    const tuples = tuples_wrapper.array;

    try writeTuples(T, tuples, w);

    try w.writeByte('\n');
}

// can also be used as regular 2D array...
fn Jagged2DArrayWrapper(T: type) type {
    return struct {
        array: [][]T,
        pool: []T,
        const Self = @This();

        // initialise as a regular array (not jagged)
        fn init(allocator: Allocator, m: usize, n: usize) !Self {
            var pool = try allocator.alloc(T, m * n);
            errdefer allocator.free(pool);

            var offset: usize = 0;
            const array = try allocator.alloc([]T, m);
            for (array) |*row| {
                row.* = pool[offset .. offset + n];
                offset += n;
            }
            return .{
                .array = array,
                .pool = pool,
            };
        }
        fn deinit(self: Self, allocator: Allocator) void {
            allocator.free(self.array);
            allocator.free(self.pool);
        }
    };
}

/// Caller owns result memory and must call result's deinit()
fn calcProduct(allocator: Allocator, T: type, xs: []const T, ys: []const T) !Jagged2DArrayWrapper(T) {
    const wrapper: Jagged2DArrayWrapper(T) = try .init(allocator, xs.len * ys.len, 2);
    const pairs = wrapper.array;
    for (pairs, 0..) |*pair, i| {
        pair.*[0] = xs[i / xs.len];
        pair.*[1] = ys[i % ys.len];
    }
    return wrapper;
}

/// the i-th tuple: its item from list k is digit k of i, in the radix of the
/// lists' lengths (a digit's place is the product of the later lengths)
fn fillTupleAt(T: type, tuple: []T, lists: []const []const T, i: usize) void {
    std.debug.assert(tuple.len == lists.len);
    for (tuple, lists, 0..lists.len) |*value, row, k| {
        var place: usize = 1;
        for (lists[k + 1 ..]) |xs|
            place *= xs.len;
        value.* = row[(i / place) % row.len];
    }
}

/// Caller owns result memory and must call result's deinit()
fn calcNaryProduct(allocator: Allocator, T: type, lists: []const []const T) !Jagged2DArrayWrapper(T) {
    var length: usize = 1;
    for (lists) |xs|
        length *= xs.len;
    const width = lists.len;

    const wrapper: Jagged2DArrayWrapper(T) = try .init(allocator, length, width);
    const tuples = wrapper.array;
    for (tuples, 0..) |tuple, i|
        fillTupleAt(T, tuple, lists, i);

    return wrapper;
}

/// Parse well-formed text in task's own notation.
/// '{1, 2} × {} × {3}' as its lists (slices): [[1, 2], [], [3]]
///
/// Caller owns result memory and must call result's deinit()
fn parseSets(allocator: Allocator, text: []const u8, T: type) !Jagged2DArrayWrapper(T) {
    if (text.len == 0)
        return error.EmptyText;

    // initial parse of text to get values for JaggedArray2DWrapper creation
    const array_length = std.mem.countScalar(u8, text, '{');
    const pool_length = blk: {
        var count: usize = 0;
        var it = std.mem.splitSequence(u8, text, "} × {");
        while (it.next()) |part| {
            const inner = std.mem.trim(u8, part, "}{");
            if (inner.len == 0)
                continue;
            count += std.mem.countScalar(u8, inner, ',') + 1;
        }
        break :blk count;
    };

    const array: [][]T = try allocator.alloc([]T, array_length);
    errdefer allocator.free(array);
    const pool: []T = try allocator.alloc(T, pool_length);

    var idx: usize = 0;
    var offset: usize = 0;
    var it1 = std.mem.splitSequence(u8, text, "} × {");
    while (it1.next()) |part| {
        const inner = std.mem.trim(u8, part, "}{");

        var count: usize = 0;
        if (inner.len != 0)
            count = std.mem.countScalar(u8, inner, ',') + 1;

        const slice = pool[offset .. offset + count];
        array[idx] = slice;

        if (count != 0) {
            var i: usize = 0;
            var it2 = std.mem.splitSequence(u8, inner, ", ");
            while (it2.next()) |number| : (i += 1) {
                slice[i] = switch (@typeInfo(T)) {
                    .int => try std.fmt.parseInt(T, number, 10),
                    .float => try std.fmt.parseFloat(T, number),
                    else => @compileError("parseSets() expected float or integer argument, found " ++ @typeName(T)),
                };
            }
        }
        offset += count;
        idx += 1;
    }
    return .{ .array = array, .pool = pool };
}

fn writeEnclosed(T: type, items: []const T, open: u8, close: u8, w: *Writer) !void {
    try w.writeByte(open);
    switch (items.len) {
        0 => {},
        else => {
            try w.print("{}", .{items[0]});
            for (items[1..]) |x|
                try w.print(", {}", .{x});
        },
    }
    try w.writeByte(close);
}

/// tuples' texts as a set, four to a line when there are more than four
fn writeTuples(T: type, tuples: []const []const T, w: *Writer) !void {
    try w.writeByte('{');
    switch (tuples.len) {
        0 => {},
        1...4 => {
            try writeEnclosed(T, tuples[0], '(', ')', w);
            for (tuples[1..]) |tuple| {
                try w.writeAll(", ");
                try writeEnclosed(T, tuple, '(', ')', w);
            }
        },
        else => {
            for (tuples, 0..) |tuple, i| {
                if (i % 4 == 0)
                    try w.writeAll("\n    ")
                else
                    try w.writeAll(", ");
                try writeEnclosed(T, tuple, '(', ')', w);
            }
            try w.writeByte('\n');
        },
    }
    try w.writeByte('}');
}

const testing = std.testing;

test "parseSets (empty)" {
    const allocator = testing.allocator;
    try testing.expectError(error.EmptyText, parseSets(allocator, "", u8));
}

test "parseSets (well-formed)" {
    const allocator = testing.allocator;

    const result0 = try parseSets(allocator, "{}", u16);
    try testing.expectEqual(1, result0.array.len);
    try testing.expectEqual(0, result0.pool.len);
    result0.deinit(allocator);

    const result1 = try parseSets(allocator, "{} × {}", u16);
    defer result1.deinit(allocator);
    try testing.expectEqual(2, result1.array.len);
    try testing.expectEqual(0, result1.pool.len);

    const result2 = try parseSets(allocator, "{1}", u16);
    defer result2.deinit(allocator);
    try testing.expectEqual(1, result2.array.len);
    try testing.expectEqual(1, result2.pool.len);

    const result3 = try parseSets(allocator, "{1, 2, 3}", u16);
    defer result3.deinit(allocator);
    try testing.expectEqual(1, result3.array.len);
    try testing.expectEqual(3, result3.pool.len);

    const result4 = try parseSets(allocator, "{1, 2, 3} × {}", u16);
    defer result4.deinit(allocator);
    try testing.expectEqual(2, result4.array.len);
    try testing.expectEqual(3, result4.pool.len);

    const result5 = try parseSets(allocator, "{1, 2, 3} × {6, 7}", u16);
    defer result5.deinit(allocator);
    try testing.expectEqual(2, result5.array.len);
    try testing.expectEqual(5, result5.pool.len);
    try testing.expectEqual(7, result5.array[1][1]);
    try testing.expectEqual(7, result5.pool[4]);

    const result6 = try parseSets(allocator, "{} × {1}", u16);
    try testing.expectEqual(2, result6.array.len);
    try testing.expectEqual(1, result6.pool.len);
    defer result6.deinit(allocator);

    const result7 = try parseSets(allocator, "{} × {1, 2, 3, 4} × {}", u16);
    defer result7.deinit(allocator);
    try testing.expectEqual(3, result7.array.len);
    try testing.expectEqual(4, result7.pool.len);
}
