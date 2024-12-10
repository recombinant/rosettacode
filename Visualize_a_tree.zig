// https://rosettacode.org/wiki/Visualize_a_tree
// Translation of Go
const std = @import("std");

pub fn main() !void {
    const writer = std.io.getStdOut().writer();

    const tree = &[_]Node{
        Node.init("root", &[_]usize{ 1, 2, 3 }),
        Node.init("ei", &[_]usize{ 4, 5 }),
        Node.init("bee", &[_]usize{}),
        Node.init("si", &[_]usize{}),
        Node.init("dee", &[_]usize{}),
        Node.init("y", &[_]usize{6}),
        Node.init("eff", &[_]usize{}),
    };

    try visualize(tree, writer);
}

const Tree = []const Node;

const Node = struct {
    label: []const u8,
    children: []const usize, // indexes into tree
    fn init(label: []const u8, children: []const usize) Node {
        return Node{
            .label = label,
            .children = children,
        };
    }
};

fn visualize(t: Tree, writer: anytype) !void {
    if (t.len == 0)
        try writer.writeAll("<empty>")
    else
        try printN(t, 0, "", writer);
}

fn printN(t: Tree, n: usize, pre: []const u8, writer: anytype) !void {
    const ch = t[n].children;
    if (ch.len == 0) {
        try writer.print("╴ {s}\n", .{t[n].label});
        return;
    }
    try writer.print("┐ {s}\n", .{t[n].label});
    const last = ch.len - 1;
    var buffer = try std.BoundedArray(u8, 128).init(0);
    for (ch[0..last]) |child| {
        try writer.writeAll(pre);
        try writer.writeAll("├─");
        buffer.clear();
        try buffer.appendSlice(pre);
        try buffer.appendSlice("│ ");
        try printN(t, child, buffer.constSlice(), writer);
    }
    try writer.writeAll(pre);
    try writer.writeAll("└─");
    buffer.clear();
    try buffer.appendSlice(pre);
    try buffer.appendSlice("  ");
    try printN(t, ch[last], buffer.constSlice(), writer);
}
