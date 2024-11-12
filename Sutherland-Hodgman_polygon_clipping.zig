// https://rosettacode.org/wiki/Sutherland-Hodgman_polygon_clipping
const std = @import("std");
const mem = std.mem;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const subject_points = [_]Point{
        .{ .x = 50, .y = 150 },  .{ .x = 200, .y = 50 },  .{ .x = 350, .y = 150 }, .{ .x = 350, .y = 300 },
        .{ .x = 250, .y = 300 }, .{ .x = 200, .y = 250 }, .{ .x = 150, .y = 350 }, .{ .x = 100, .y = 250 },
        .{ .x = 100, .y = 200 },
    };
    const clipping_points = [_]Point{
        .{ .x = 100, .y = 100 }, .{ .x = 300, .y = 100 }, .{ .x = 300, .y = 300 }, .{ .x = 100, .y = 300 },
    };

    const clipped = try clip(allocator, &subject_points, &clipping_points);
    defer allocator.free(clipped);

    // for (clipped) |point|
    //     std.debug.print("{d} {d}\n", .{ point.x, point.y });

    const writer = std.io.getStdOut().writer();

    try writer.print("<svg xmlns='http://www.w3.org/2000/svg' width='{d}' height='{d}'>\n", .{ 380, 380 });
    try writer.writeAll("<rect width='100%' height='100%' fill='ghostwhite'/>\n");

    try writer.writeAll("<path stroke='lightgreen' fill='none' d='");
    try writer.writeByte('M'); // L instruction is not required as it is implied by the M
    for (subject_points) |point|
        try writer.print("{d} {d} ", .{ point.x, point.y });
    try writer.print("{d} {d}\n", .{ subject_points[0].x, subject_points[0].y });
    try writer.writeAll("'/>\n");

    try writer.writeAll("<path stroke='lightsalmon' fill='none' d='");
    try writer.writeByte('M');
    for (clipping_points) |point|
        try writer.print("{d} {d} ", .{ point.x, point.y });
    try writer.print("{d} {d}\n", .{ clipping_points[0].x, clipping_points[0].y });
    try writer.writeAll("'/>\n");

    try writer.writeAll("<path stroke='black' stroke-width='2' fill='none' d='");
    try writer.writeByte('M');
    for (clipped) |point|
        try writer.print("{d} {d} ", .{ point.x, point.y });
    try writer.print("{d} {d}\n", .{ clipped[0].x, clipped[0].y });

    try writer.writeAll("'/>\n</svg>\n");
}

const Point = struct {
    x: f64,
    y: f64,

    fn sub(self: *const Point, other: Point) Point {
        return Point{ .x = self.x - other.x, .y = self.y - other.y };
    }

    fn cross(self: *const Point, other: Point) f64 {
        return self.x * other.y - self.y * other.x;
    }

    fn inside(self: *const Point, edge: Edge) bool {
        return (edge.q.x - edge.p.x) * (self.y - edge.p.y) > (edge.q.y - edge.p.y) * (self.x - edge.p.x);
    }
};

const Edge = struct {
    p: Point,
    q: Point,

    fn computeIntersection(self: Edge, p1: Point, p2: Point) Point {
        const dc = p1.sub(p2);
        const dp = self.p.sub(self.q);
        const n1 = p1.cross(p2);
        const n2 = self.p.cross(self.q);
        const n3 = 1 / dc.cross(dp);
        return .{ .x = (n1 * dp.x - n2 * dc.x) * n3, .y = (n1 * dp.y - n2 * dc.y) * n3 };
    }
};

const Polygon = []Edge;
const PointArray = std.ArrayList(Point);

fn createPolygon(allocator: mem.Allocator, vertices: []const Point) !Polygon {
    const polygon = try allocator.alloc(Edge, vertices.len);
    const len = vertices.len;
    for (polygon, 0..) |*edge, i|
        edge.* = .{
            .p = vertices[i],
            .q = vertices[(i + 1) % len],
        };
    return polygon;
}

fn clip(allocator: mem.Allocator, subject_vertices: []const Point, clip_vertices: []const Point) ![]Point {
    std.debug.assert(subject_vertices.len > 1);
    std.debug.assert(clip_vertices.len > 1);

    const clip_polygon = try createPolygon(allocator, clip_vertices);
    defer allocator.free(clip_polygon);

    var output_list = try PointArray.initCapacity(allocator, subject_vertices.len);
    try output_list.appendSlice(subject_vertices);

    for (clip_polygon) |clip_edge| {
        const input_list = try output_list.toOwnedSlice();
        defer allocator.free(input_list);

        for (0..input_list.len) |i| {
            const current_point = input_list[i];
            const prev_point = input_list[(i + input_list.len - 1) % input_list.len];

            const intersecting_point = clip_edge.computeIntersection(prev_point, current_point);

            if (current_point.inside(clip_edge)) {
                if (!prev_point.inside(clip_edge))
                    try output_list.append(intersecting_point);
                try output_list.append(current_point);
            } else if (prev_point.inside(clip_edge))
                try output_list.append(intersecting_point);
        }
    }
    return try output_list.toOwnedSlice();
}
