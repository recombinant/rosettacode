// https://rosettacode.org/wiki/Array_concatenation
// from https://github.com/tiehuis/zig-rosetta
const std = @import("std");
const heap = std.heap;
const mem = std.mem;
const assert = std.debug.assert;

fn runtimeAppend(allocator: mem.Allocator) !void {
    var a = std.ArrayList(u8).init(allocator);
    defer a.deinit();
    try a.appendSlice(&[_]u8{ 0, 1, 2, 3, 4 });

    var b = std.ArrayList(u8).init(allocator);
    defer b.deinit();
    try b.appendSlice(&[_]u8{ 10, 11, 12, 13 });

    try a.appendSlice(b.items);
    assert(mem.eql(u8, a.items, &[_]u8{ 0, 1, 2, 3, 4, 10, 11, 12, 13 }));
}

fn comptimeAppend() void {
    const a = [_]u8{ 0, 1, 2, 3, 4 };
    const b = [_]u8{ 10, 11, 12, 13 };

    const c = a ++ b;
    assert(mem.eql(u8, &c, &[_]u8{ 0, 1, 2, 3, 4, 10, 11, 12, 13 }));
}

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try runtimeAppend(allocator);
    comptimeAppend();
}
