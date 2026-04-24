// https://rosettacode.org/wiki/Constrained_random_points_on_a_circle
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const rl = @import("raylib");

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    const screen_width = 480;
    const screen_height = 480;

    const center_x: c_int = screen_width / 2;
    const center_y: c_int = screen_height / 2;
    const factor: c_int = (@min(screen_height, screen_width) - 30) / (15 * 2);

    rl.InitWindow(screen_width, screen_height, "constrained random points on a circle");
    defer rl.CloseWindow();

    rl.SetTargetFPS(30);
    // -------------------------------------------- random number
    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        Io.random(io, std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random = prng.random();
    // ----------------------------------------------------------
    const possible_points = try initPoints(gpa);
    defer gpa.free(possible_points);

    var start = true;
    while (!rl.WindowShouldClose()) // Detect window close button or ESC key
    {
        // ------------------------------------------------------
        rl.BeginDrawing();
        defer rl.EndDrawing();
        rl.ClearBackground(rl.RAYWHITE);
        // ----------------------------------------------- update
        if (rl.IsKeyDown(rl.KEY_SPACE) or start) {
            start = false;
            random.shuffle(Point, possible_points);
        }
        // ------------------------------------------------- draw
        for (possible_points[0..100]) |p|
            rl.DrawCircle(center_x + p.x * factor, center_y + p.y * factor, 10, rl.GRAY);
        // ------------------------------------------------------
    }
}

const Point = struct {
    x: c_int,
    y: c_int,
};

fn initPoints(allocator: Allocator) ![]Point {
    const lo = 10 * 10;
    const hi = 15 * 15;
    var points: std.ArrayList(Point) = .empty;
    var x: c_int = -15;
    while (x <= 15) : (x += 1) {
        var y: c_int = -15;
        while (y <= 15) : (y += 1) {
            const hypot = x * x + y * y;
            if (lo <= hypot and hypot <= hi)
                try points.append(allocator, Point{ .x = x, .y = y });
        }
    }
    return points.toOwnedSlice(allocator);
}
