// https://rosettacode.org/wiki/Draw_a_sphere
// {{works with|Zig|0.15.1}}
// {{trans|Factor}}
// {{libheader|raylib}}
const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

pub fn main() !void {
    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE | rl.FLAG_VSYNC_HINT);
    rl.InitWindow(600, 480, "Draw a Sphere");
    defer rl.CloseWindow();

    const camera = rl.Camera3D{
        .position = .{ .x = 4.5, .y = 4.5, .z = 4.5 },
        .target = .{ .x = 0, .y = 0, .z = 0 },
        .up = .{ .x = 0, .y = 1, .z = 0 },
        .fovy = 45.0,
        .projection = rl.CAMERA_PERSPECTIVE,
    };

    rl.SetTargetFPS(10);

    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.BLACK);

        {
            rl.BeginMode3D(camera);
            defer rl.EndMode3D();

            rl.DrawSphereWires(.{ .x = 0, .y = 0, .z = 0 }, 2, 20, 20, rl.LIME);
        }
    }
}
