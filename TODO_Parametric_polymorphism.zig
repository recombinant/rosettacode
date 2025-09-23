// https://rosettacode.org/wiki/Parametric_polymorphism
const std = @import("std");

const Container = Tree(u16);

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll("Initial tree:\n");
    var tree: Container = .init(5);
    var node1: Container = .init(3);
    var node2: Container = .init(11);
    tree.left = &node1;
    tree.right = &node2;
    try tree.print(stdout);

    try stdout.writeAll("\nTree after applying a function to each node:\n");
    tree.map(MulAddContext{ 2, 7 }, mulAdd);
    try tree.print(stdout);

    try stdout.flush();
}

const MulAddContext = struct { u16, u16 };
fn mulAdd(muladd: MulAddContext, node: *Container) void {
    const multiplier, const addend = muladd;
    node.value *= multiplier;
    node.value += addend;
}

fn Tree(T: type) type {
    return struct {
        const Self = @This();
        value: T,
        left: ?*Self,
        right: ?*Self,

        fn init(value: T) Self {
            return .{ .value = value, .left = null, .right = null };
        }

        /// Apply function "mapFn" to each element of the tree.
        fn map(self: *Self, context: anytype, comptime mapFn: fn (@TypeOf(context), *Self) void) void {
            mapFn(context, self);
            if (self.left) |node| node.map(context, mapFn);
            if (self.right) |node| node.map(context, mapFn);
        }
        fn print(self: *const Self, writer: *std.Io.Writer) !void {
            try self.print_(0, writer); // with zero indent
        }
        fn print_(self: *const Self, indent: usize, writer: *std.Io.Writer) !void {
            _ = try writer.splatByte(' ', indent);
            try writer.print(" value: {}\n", .{self.value});
            for ([2]?*Self{ self.left, self.right }) |optional_node| {
                if (optional_node) |node|
                    try node.print_(indent + 2, writer)
                else {
                    _ = try writer.splatByte(' ', indent + 2);
                    try writer.writeAll(" null\n");
                }
            }
        }
    };
}
