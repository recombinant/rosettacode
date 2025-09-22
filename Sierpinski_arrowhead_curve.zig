// https://rosettacode.org/wiki/Sierpinski_arrowhead_curve
// {{works with|Zig|0.15.1}}
// {{trans|C++}}
const std = @import("std");

const sqrt3_2: f32 = @sqrt(3.0) * 0.5;
const Point = struct { x: f32, y: f32 };

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var file = try std.fs.cwd().createFile("sierpinski_arrowhead.svg", .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;
    var file_writer = file.writer(&buffer);
    const w = &file_writer.interface;

    try writeSierpinskiArrowhead(allocator, 600, 8, w);

    try w.flush();
}

fn writeSierpinskiArrowhead(allocator: std.mem.Allocator, size: usize, iterations: u16, w: *std.Io.Writer) !void {
    try w.print("<svg xmlns='http://www.w3.org/2000/svg' width='{d}' height='{d}'>", .{ size, size });
    try w.writeAll("<rect width='100%' height='100%' fill='white'/>");
    try w.writeAll("<path stroke='black' fill='none' d='");
    const margin = 20;
    const side: f32 = @as(f32, @floatFromInt(size)) - 2 * margin;
    const x: f32 = margin;
    const y = 0.5 * @as(f32, @floatFromInt(size)) + 0.5 * sqrt3_2 * side;
    var points = try allocator.alloc(Point, 2);
    defer allocator.free(points);
    points[0] = Point{ .x = x, .y = y };
    points[1] = Point{ .x = x + side, .y = y };
    for (0..iterations) |_| {
        var slice = try sierpinskiArrowheadNext(allocator, points);
        std.mem.swap([]Point, &slice, &points);
        allocator.free(slice);
    }
    var buffer1: [10]u8 = undefined;
    var buffer2: [10]u8 = undefined;
    // L instruction is not required as it is implied by the M
    try w.writeByte('M');
    for (points) |point| {
        try w.print("{s} {s} ", .{
            try toString(&buffer1, point.x),
            try toString(&buffer2, point.y),
        });
    }
    try w.writeAll("'/></svg>");
}

fn sierpinskiArrowheadNext(allocator: std.mem.Allocator, points: []Point) ![]Point {
    var output = try allocator.alloc(Point, 3 * (points.len - 1) + 1);

    var j: usize = 0;
    for (0..points.len - 1) |i| {
        const x0 = points[i].x;
        const y0 = points[i].y;
        const x1 = points[i + 1].x;
        const y1 = points[i + 1].y;
        const dx = x1 - x0;
        output[j] = Point{ .x = x0, .y = y0 };
        if (y0 == y1) {
            const d = @abs(dx * sqrt3_2 / 2);
            output[j + 1] = Point{ .x = x0 + dx / 4, .y = y0 - d };
            output[j + 2] = Point{ .x = x1 - dx / 4, .y = y0 - d };
        } else if (y1 < y0) {
            output[j + 1] = Point{ .x = x1, .y = y0 };
            output[j + 2] = Point{ .x = x1 + dx / 2, .y = (y0 + y1) / 2 };
        } else {
            output[j + 1] = Point{ .x = x0 - dx / 2, .y = (y0 + y1) / 2 };
            output[j + 2] = Point{ .x = x0, .y = y1 };
        }
        j += 3;
    }
    output[j] = points[points.len - 1];
    return output;
}

/// Reduce the size of the svg file by limiting
/// the precision of floating point and removing trailing zeros.
fn toString(buffer: []u8, value: f32) ![]const u8 {
    // One decimal place is good enough.
    const output = try std.fmt.bufPrint(buffer, "{d:.1}", .{value});
    var end = output.len - 1;
    if (output[end] == '0') {
        end -= 1;
        if (output[end] == '.')
            end -= 1;
    }
    return output[0 .. end + 1];
}
