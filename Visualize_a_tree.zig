// https://rosettacode.org/wiki/Visualize_a_tree
// {{works with|Zig|0.16.0}}
// {{trans|Go}}
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    const tree = &[_]Node{
        .init("root", &.{ 1, 2, 3 }),
        .init("ei", &.{ 4, 5 }),
        .init("bee", &.{}),
        .init("si", &.{}),
        .init("dee", &.{}),
        .init("y", &.{6}),
        .init("eff", &.{}),
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

fn visualize(t: Tree, w: *Io.Writer) !void {
    if (t.len == 0)
        try w.writeAll("<empty>")
    else
        try printN(t, 0, "", w);
}

fn printN(t: Tree, n: usize, pre: []const u8, w: *Io.Writer) !void {
    const ch = t[n].children;
    if (ch.len == 0) {
        try w.print("╴ {s}\n", .{t[n].label});
        return;
    }
    try w.print("┐ {s}\n", .{t[n].label});
    const last = ch.len - 1;
    var buffer: [128]u8 = undefined;
    var bw: Io.Writer = .fixed(&buffer);
    for (ch[0..last]) |child| {
        try w.writeAll(pre);
        try w.writeAll("├─");
        _ = bw.consumeAll();
        try bw.writeAll(pre);
        try bw.writeAll("│ ");
        try printN(t, child, bw.buffered(), w);
    }
    try w.writeAll(pre);
    try w.writeAll("└─");
    _ = bw.consumeAll();
    try bw.writeAll(pre);
    try bw.writeAll("  ");
    try printN(t, ch[last], bw.buffered(), w);
}
