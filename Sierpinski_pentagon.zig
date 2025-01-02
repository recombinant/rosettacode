// https://rosettacode.org/wiki/Sierpinski_pentagon
// Translation of D
const std = @import("std");

const ORDER = 5; // minimum 1

/// Run the generation of a P(5) sierpinksi pentagon
pub fn main() !void {
    std.debug.assert(ORDER != 0);

    const size = 500;
    var turtle = Turtle.init(size / 2, size, 0);

    const writer = std.io.getStdOut().writer();
    // Write the header to an SVG file for the image
    try writer.writeAll("<?xml version=\"1.0\" standalone=\"no\"?>\n");
    try writer.writeAll("<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\"\n");
    try writer.writeAll("    \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">\n");
    try writer.print("<svg height=\"{}\" width=\"{}\" style=\"fill:blue\" transform=\"translate({},{}) rotate(-36)\"\n", .{ size, size, size / 2, size / 2 });
    try writer.writeAll("    version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\">\n");

    // Begin rendering, scaling the initial turtle so that it
    // stays in the inner pentagon
    try sierpinski(ORDER, &turtle, size * part_ratio, writer);

    // Write the close tag when the interior points have been written
    try writer.writeAll("</svg>\n");
}

const part_ratio = 2.0 * @cos(std.math.degreesToRadians(72));
const side_ratio = 1.0 / (part_ratio + 2.0);

/// Use the provided turtle to draw a pentagon of the specified size
fn pentagon(turtle: *Turtle, size: f64, writer: anytype) !void {
    turtle.right(std.math.degreesToRadians(36));
    try turtle.begin_fill(writer);
    for (0..5) |_| {
        try turtle.forward(size, writer);
        turtle.right(std.math.degreesToRadians(72));
    }
    try turtle.end_fill(writer);
}

/// Draw a sierpinski pentagon of the desired order
fn sierpinski(order: u16, turtle: *Turtle, size: f64, writer: anytype) !void {
    turtle.theta = 0.0; // heading

    const new_size = size * side_ratio;
    const new_order = order - 1;

    if (new_order != 0) {
        const small = size * side_ratio / part_ratio;

        // create four more turtles
        for ([4]f64{ small, size, size, small }) |dist| {
            turtle.right(std.math.degreesToRadians(36));

            var spawn = Turtle.init(turtle.pos.x, turtle.pos.y, turtle.theta);
            try spawn.forward(dist, writer);

            // recurse for each spawned turtle
            try sierpinski(new_order, &spawn, new_size, writer);
        }
        // recurse for the original turtle
        try sierpinski(new_order, turtle, new_size, writer);
        // // prettify output by separating pentagons in SVG
        // try writer.writeByte('\n');
    } else {
        // The bottom has been reached for this turtle
        try pentagon(turtle, size, writer);
    }
}

/// Define a position
const Point = struct {
    x: f64,
    y: f64,

    // refer to std.fmt.format documentation
    /// When a point is written, do it in the form "x,y " to three decimal places
    pub fn format(self: *const Point, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("{d:.3},{d:.3} ", .{ self.x, self.y });
    }
};

/// Mock turtle implementation sufficient to handle "drawing" the pentagons
const Turtle = struct {
    pos: Point,
    theta: f64, // heading
    tracing: bool = false,

    fn init(x: f64, y: f64, theta: f64) Turtle {
        return Turtle{
            .pos = Point{ .x = x, .y = y },
            .theta = theta,
        };
    }
    /// Move the turtle through space
    fn forward(self: *Turtle, dist: f64, writer: anytype) !void {
        self.pos.x += dist * std.math.cos(self.theta);
        self.pos.y += dist * std.math.sin(self.theta);

        if (self.tracing)
            try writer.print("{}", .{self.pos});
    }
    /// Turn the turtle
    fn right(self: *Turtle, angle: f64) void {
        self.theta -= angle;
    }
    /// Start exporting the points of the polygon
    fn begin_fill(self: *Turtle, writer: anytype) !void {
        try writer.writeAll("<polygon points=\"");
        self.tracing = true;
    }
    /// Stop exporting the points of the polygon
    fn end_fill(self: *Turtle, writer: anytype) !void {
        try writer.writeAll("\"/>\n");
        self.tracing = false;
    }
};
