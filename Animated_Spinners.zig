// https://rosettacode.org/wiki/Animated_Spinners
// {{works with|Zig|0.15.1}}
// {{trans|C}}
// {{libheader|raylib}}

// includes stretch goal
const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

const WINDOW_SIZE = 800;
const WINDOW_RADIUS = WINDOW_SIZE / 2;

const SPINNER_RADIUS = 100;
const SPINNER_OFFSET = SPINNER_RADIUS * 1.5;

// Structure to represent a spinner
const Spinner = struct {
    pos: rl.Vector2,
    angle: f32,
    color: rl.Color,
};

// Calculate the end point of the spinner line
fn calcEndPos(pos: rl.Vector2, angle: f32) rl.Vector2 {
    return .{
        .x = pos.x + SPINNER_RADIUS * @cos(std.math.degreesToRadians(angle)),
        .y = pos.y + SPINNER_RADIUS * @sin(std.math.degreesToRadians(angle)),
    };
}

pub fn main() !void {
    // Default rotation speed
    var speed: f32 = 5;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    // Allow overriding speed via command line argument
    var iter = try std.process.ArgIterator.initWithAllocator(arena.allocator());
    _ = iter.next(); // executable
    if (iter.next()) |arg|
        speed = try std.fmt.parseFloat(f32, arg);

    rl.SetConfigFlags(rl.FLAG_MSAA_4X_HINT);
    rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Spinnnn");
    defer rl.CloseWindow();

    const center: rl.Vector2 = .{ .x = WINDOW_SIZE / 2, .y = WINDOW_SIZE / 2 };
    var spinners: [5]Spinner = .{
        .{ .pos = center, .angle = 50, .color = rl.GREEN },
        .{ .pos = .{ .x = center.x - SPINNER_OFFSET, .y = center.y + SPINNER_OFFSET }, .angle = 50, .color = rl.RED },
        .{ .pos = .{ .x = center.x + SPINNER_OFFSET, .y = center.y + SPINNER_OFFSET }, .angle = 50, .color = rl.WHITE },
        .{ .pos = .{ .x = center.x - SPINNER_OFFSET, .y = center.y - SPINNER_OFFSET }, .angle = 50, .color = rl.YELLOW },
        .{ .pos = .{ .x = center.x + SPINNER_OFFSET, .y = center.y - SPINNER_OFFSET }, .angle = 50, .color = rl.ORANGE },
    };

    // Main loop
    while (!rl.WindowShouldClose()) {
        // Use deltatime to keep speed consistent regardless of framerate
        const dt = rl.GetFrameTime();
        const mouse = rl.GetMousePosition();
        var m_offset = rl.Vector2Zero();
        // If the mouse is within the window radius, calculate
        // it's offset relative to the center
        if (rl.Vector2Distance(mouse, center) < WINDOW_RADIUS)
            m_offset = rl.Vector2Scale(rl.Vector2Subtract(mouse, center), 0.1);

        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.DARKGRAY);
        rl.DrawCircle(WINDOW_RADIUS, WINDOW_RADIUS, WINDOW_RADIUS, rl.BLACK);
        for (&spinners) |*s| {
            const pos = rl.Vector2Add(s.pos, m_offset); // Apply offset
            rl.DrawLineEx(pos, calcEndPos(pos, s.angle), 2, s.color);
            s.angle += dt * 100 * speed;
            if (s.angle > 360) s.angle = 0;
        }
    }
}
