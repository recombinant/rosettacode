// https://rosettacode.org/wiki/Check_if_a_polygon_overlaps_with_a_rectangle
// Translation of C
// There is no runtime heap allocation - everything happens on
// the stack - hence variable declarations in the main() routine
// where their array size is known at compile time.
const std = @import("std");

const print = std.debug.print;

pub fn main() void {
    // 1st shape. Polygon.
    const points1 = [_]Point{
        Point.init(0, 0), Point.init(0, 2), Point.init(1, 4),
        Point.init(2, 2), Point.init(2, 0),
    };
    var vertices1: [points1.len]Vector = undefined;
    var axes1: [points1.len]Vector = undefined;
    const poly1 = Polygon.init(&points1, &vertices1, &axes1);
    // ----------------------------------------------------------
    // 2nd shape. First rectangle.
    const rect2 = Rectangle.init(4, 0, 2, 2);
    var points2: [4]Point = undefined;
    var vertices2: [points2.len]Vector = undefined;
    var axes2: [points2.len]Vector = undefined;
    const rect2_as_points = pointsFromRect(rect2, &points2);
    const rect2_as_polygon = Polygon.init(rect2_as_points, &vertices2, &axes2);
    // ----------------------------------------------------------
    // 3rd shape. Second rectangle.
    const rect3 = Rectangle.init(1, 0, 8, 2);
    var points3: [4]Point = undefined;
    var vertices3: [points3.len]Vector = undefined;
    var axes3: [points3.len]Vector = undefined;
    const rect3_as_points = pointsFromRect(rect3, &points3);
    const rect3_as_polygon = Polygon.init(rect3_as_points, &vertices3, &axes3);
    // ----------------------------------------------------------
    print("poly1  = {any}\n", .{poly1});
    print("rect2 = {{{d}, {d}, {d}, {d}}} => {any}\n", .{ rect2.x, rect2.y, rect2.w, rect2.h, rect2_as_polygon });
    print("rect3 = {{{d}, {d}, {d}, {d}}} => {any}\n", .{ rect3.x, rect3.y, rect3.w, rect3.h, rect3_as_polygon });

    print("poly1 and rect2 overlap? {}\n", .{poly1.overlaps(rect2_as_polygon)});
    print("poly1 and rect3 overlap? {}\n", .{poly1.overlaps(rect3_as_polygon)});
}

fn pointsFromRect(r: Rectangle, points: []Point) []Point {
    points[0] = Point.init(r.x, r.y);
    points[1] = Point.init(r.x, r.y + r.h);
    points[2] = Point.init(r.x + r.w, r.y + r.h);
    points[3] = Point.init(r.x + r.w, r.y);
    return points[0..4];
}
const Rectangle = struct {
    x: f64,
    y: f64,
    w: f64,
    h: f64,
    fn init(x: f64, y: f64, w: f64, h: f64) Rectangle {
        return Rectangle{ .x = x, .y = y, .w = w, .h = h };
    }
};
const Polygon = struct {
    vertices: []Vector,
    axes: []Vector,
    fn init(points: []const Point, vertices: []Vector, axes: []Vector) Polygon {
        std.debug.assert(vertices.len == points.len);
        std.debug.assert(axes.len == points.len);
        for (points, vertices) |p, *v|
            v.* = Vector{ .x = p.x, .y = p.y };
        return Polygon{
            .vertices = vertices,
            .axes = computeAxes(axes, vertices),
        };
    }
    fn overlaps(self: Polygon, other: Polygon) bool {
        for ([_][]Vector{ self.axes, other.axes }) |axes|
            for (axes) |axis| {
                const projection1 = self.projectionOnAxis(axis);
                const projection2 = other.projectionOnAxis(axis);
                if (!projection1.overlaps(projection2))
                    return false;
            };
        return true;
    }
    fn projectionOnAxis(self: Polygon, axis: Vector) Projection {
        var min: f64 = std.math.floatMax(f64);
        var max: f64 = -std.math.floatMax(f64);

        for (self.vertices) |vertex| {
            const p = axis.scalarProduct(vertex);
            if (p < min) min = p;
            if (p > max) max = p;
        }
        return Projection{ .min = min, .max = max };
    }
    fn computeAxes(axes: []Vector, vertices: []const Vector) []Vector {
        std.debug.assert(axes.len == vertices.len);
        for (axes, vertices, 1..) |*axis, vertex1, i| {
            const vertex2 = vertices[i % vertices.len];
            const edge = vertex1.edgeWith(vertex2);
            axis.* = edge.perpendicular();
        }
        return axes;
    }
    pub fn format(self: Polygon, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.writeAll("[ ");
        for (self.vertices) |vertex|
            try writer.print("{}", .{vertex});
        try writer.writeByte(']');
    }
};
const Vector = struct {
    x: f64,
    y: f64,
    fn scalarProduct(self: Vector, other: Vector) f64 {
        return self.x * other.x + self.y * other.y;
    }
    fn edgeWith(self: Vector, other: Vector) Vector {
        return Vector{ .x = self.x - other.x, .y = self.y - other.y };
    }
    fn perpendicular(self: Vector) Vector {
        return Vector{ .x = -self.y, .y = self.x };
    }
    pub fn format(self: Vector, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("({d}, {d}) ", .{ self.x, self.y });
    }
};
const Projection = struct {
    min: f64,
    max: f64,
    fn overlaps(self: Projection, other: Projection) bool {
        if (self.max < other.min) return false;
        if (other.max < self.min) return false;
        return true;
    }
};
const Point = struct {
    x: f64,
    y: f64,
    fn init(x: f64, y: f64) Point {
        return Point{ .x = x, .y = y };
    }
};
