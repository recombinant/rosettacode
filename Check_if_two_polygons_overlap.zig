// https://rosettacode.org/wiki/Check_if_two_polygons_overlap
// {{works with|Zig|0.15.1}}
// {{trans|Java}}
// An implementation of the Separating Axis Theorem algorithm for convex polygons.
const std = @import("std");

pub fn main() !void {
    // ----------------------------------------------------------
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ----------------------------------------------------------
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ----------------------------------------------------------
    //
    const polygon1: Polygon = try .init(allocator, &[_]Point{
        .init(0.0, 0.0), .init(0.0, 2.0), .init(1.0, 4.0),
        .init(2.0, 2.0), .init(2.0, 0.0),
    });
    defer polygon1.deinit(allocator);
    const polygon2: Polygon = try .init(allocator, &[_]Point{
        .init(4.0, 0.0), .init(4.0, 2.0), .init(5.0, 4.0),
        .init(6.0, 2.0), .init(6.0, 0.0),
    });
    defer polygon2.deinit(allocator);
    const polygon3: Polygon = try .init(allocator, &[_]Point{
        .init(1.0, 0.0), .init(1.0, 2.0), .init(5.0, 4.0),
        .init(9.0, 2.0), .init(9.0, 0.0),
    });
    defer polygon3.deinit(allocator);

    try stdout.print("polygon1 = {any}\n", .{polygon1});
    try stdout.print("polygon2 = {any}\n", .{polygon2});
    try stdout.print("polygon3 = {any}\n", .{polygon3});
    try stdout.writeByte('\n');
    try stdout.print("polygon1 and polygon2 overlap? {}\n", .{polygon1.overlaps(polygon2)});
    try stdout.print("polygon1 and polygon3 overlap? {}\n", .{polygon1.overlaps(polygon3)});
    try stdout.print("polygon2 and polygon3 overlap? {}\n", .{polygon2.overlaps(polygon3)});

    try stdout.flush();
}

const Polygon = struct {
    vertices: []Vector,
    axes: []Vector,
    fn init(allocator: std.mem.Allocator, points: []const Point) !Polygon {
        const vertices = try allocator.alloc(Vector, points.len);
        for (points, vertices) |p, *v|
            v.* = Vector{ .x = p.x, .y = p.y };
        return Polygon{
            .vertices = vertices,
            .axes = try computeAxes(allocator, vertices),
        };
    }
    fn deinit(self: Polygon, allocator: std.mem.Allocator) void {
        allocator.free(self.vertices);
        allocator.free(self.axes);
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
    fn computeAxes(allocator: std.mem.Allocator, vertices: []Vector) ![]Vector {
        const axes = try allocator.alloc(Vector, vertices.len);
        for (axes, vertices, 1..) |*axis, vertex1, i| {
            const vertex2 = vertices[i % vertices.len];
            const edge = vertex1.edgeWith(vertex2);
            axis.* = edge.perpendicular();
        }
        return axes;
    }
    pub fn format(self: Polygon, w: *std.Io.Writer) std.Io.Writer.Error!void {
        try w.writeAll("[ ");
        for (self.vertices) |vertex|
            try w.print("{f}", .{vertex});
        try w.writeByte(']');
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
    pub fn format(self: Vector, w: *std.Io.Writer) std.Io.Writer.Error!void {
        try w.print("({d}, {d}) ", .{ self.x, self.y });
    }
};

const Projection = struct {
    min: f64,
    max: f64,
    fn overlaps(self: Projection, other: Projection) bool {
        return !(self.max < other.min or other.max < self.min);
    }
};

const Point = struct {
    x: f64,
    y: f64,
    fn init(x: f64, y: f64) Point {
        return .{ .x = x, .y = y };
    }
};
