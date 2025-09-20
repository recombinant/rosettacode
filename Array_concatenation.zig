// https://rosettacode.org/wiki/Array_concatenation
// {{works with|Zig|0.15.1}}

// from https://github.com/tiehuis/zig-rosetta
const std = @import("std");

fn runtimeAppend(allocator: std.mem.Allocator) !void {
    var a: std.ArrayList(u8) = .empty;
    defer a.deinit(allocator);
    try a.appendSlice(allocator, &[_]u8{ 0, 1, 2, 3, 4 });

    var b: std.ArrayList(u8) = .empty;
    defer b.deinit(allocator);
    try b.appendSlice(allocator, &[_]u8{ 10, 11, 12, 13 });

    try a.appendSlice(allocator, b.items);
    std.debug.assert(std.mem.eql(u8, a.items, &[_]u8{ 0, 1, 2, 3, 4, 10, 11, 12, 13 }));
}

fn comptimeAppend() void {
    const a = [_]u8{ 0, 1, 2, 3, 4 };
    const b = [_]u8{ 10, 11, 12, 13 };

    const c = a ++ b;
    std.debug.assert(std.mem.eql(u8, &c, &[_]u8{ 0, 1, 2, 3, 4, 10, 11, 12, 13 }));
}

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try runtimeAppend(allocator);
    comptimeAppend();
}
