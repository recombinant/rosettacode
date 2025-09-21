// https://rosettacode.org/wiki/Visualize_a_tree
// {{works with|Zig|0.15.1}}
// {{trans|Go}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const tree = &[_]Node{
        .init("root", &[_]usize{ 1, 2, 3 }),
        .init("ei", &[_]usize{ 4, 5 }),
        .init("bee", &[_]usize{}),
        .init("si", &[_]usize{}),
        .init("dee", &[_]usize{}),
        .init("y", &[_]usize{6}),
        .init("eff", &[_]usize{}),
    };

    try visualize(tree, stdout);

    try stdout.flush();
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

fn visualize(t: Tree, w: *std.Io.Writer) !void {
    if (t.len == 0)
        try w.writeAll("<empty>")
    else
        try printN(t, 0, "", w);
}

fn printN(t: Tree, n: usize, pre: []const u8, w: *std.Io.Writer) !void {
    const ch = t[n].children;
    if (ch.len == 0) {
        try w.print("╴ {s}\n", .{t[n].label});
        return;
    }
    try w.print("┐ {s}\n", .{t[n].label});
    const last = ch.len - 1;
    var buffer: [128]u8 = undefined;
    var array: std.ArrayList(u8) = .initBuffer(&buffer);
    for (ch[0..last]) |child| {
        try w.writeAll(pre);
        try w.writeAll("├─");
        array.clearRetainingCapacity();
        try array.appendSliceBounded(pre);
        try array.appendSliceBounded("│ ");
        try printN(t, child, array.items, w);
    }
    try w.writeAll(pre);
    try w.writeAll("└─");
    array.clearRetainingCapacity();
    try array.appendSliceBounded(pre);
    try array.appendSliceBounded("  ");
    try printN(t, ch[last], array.items, w);
}
