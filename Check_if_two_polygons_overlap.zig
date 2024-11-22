// https://rosettacode.org/wiki/Check_if_two_polygons_overlap
// Tranlation of Java
// An implementation of the Separating Axis Theorem algorithm for convex polygons.
const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    //
    // for short lived allocations
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const ephemeral_allocator = arena.allocator();
    //
    const polygon1 = try Polygon.init(allocator, &[_]Point{
        Point.init(0.0, 0.0), Point.init(0.0, 2.0), Point.init(1.0, 4.0),
        Point.init(2.0, 2.0), Point.init(2.0, 0.0),
    });
    defer polygon1.deinit(allocator);
    const polygon2 = try Polygon.init(allocator, &[_]Point{
        Point.init(4.0, 0.0), Point.init(4.0, 2.0), Point.init(5.0, 4.0),
        Point.init(6.0, 2.0), Point.init(6.0, 0.0),
    });
    defer polygon2.deinit(allocator);
    const polygon3 = try Polygon.init(allocator, &[_]Point{
        Point.init(1.0, 0.0), Point.init(1.0, 2.0), Point.init(5.0, 4.0),
        Point.init(9.0, 2.0), Point.init(9.0, 0.0),
    });
    defer polygon3.deinit(allocator);

    print("polygon1 = {any}\n", .{polygon1});
    print("polygon2 = {any}\n", .{polygon2});
    print("polygon3 = {any}\n", .{polygon3});
    print("\n", .{});
    print("polygon1 and polygon2 overlap? {}\n", .{try polygon1.overlaps(ephemeral_allocator, polygon2)});
    print("polygon1 and polygon3 overlap? {}\n", .{try polygon1.overlaps(ephemeral_allocator, polygon3)});
    print("polygon2 and polygon3 overlap? {}\n", .{try polygon2.overlaps(ephemeral_allocator, polygon3)});
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
    fn overlaps(self: Polygon, allocator: std.mem.Allocator, other: Polygon) !bool {
        const allAxes = try std.mem.concat(allocator, Vector, &[2][]const Vector{ self.axes, other.axes });
        defer allocator.free(allAxes);

        for (allAxes) |axis| {
            const projection1 = self.projectionOnAxis(axis);
            const projection2 = other.projectionOnAxis(axis);
            if (!projection1.overlaps(projection2))
                return false;
        }
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
        return !(self.max < other.min or other.max < self.min);
    }
};

const Point = struct {
    x: f64,
    y: f64,
    fn init(x: f64, y: f64) Point {
        return Point{ .x = x, .y = y };
    }
};
