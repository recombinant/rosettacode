// https://rosettacode.org/wiki/Draw_a_rotating_cube
// {{works with|Zig|0.15.1}}
// {{libheader|raylib}}
const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("rlgl.h");
});

pub fn main() !void {
    const screen_width = 640;
    const screen_height = 360;

    var dark_mode = true;
    var show_grid = true; // show the cube standing on a grid

    const cube_side = 1;
    const size: rl.Vector3 = .{ .x = cube_side, .y = cube_side, .z = cube_side };
    const position: rl.Vector3 = .{ .x = 0, .y = 0, .z = 0 };
    const x_rot = 45;
    const y_center: f32 = @sqrt(3.0) * cube_side / 2.0;
    const z_rot = std.math.radiansToDegrees(std.math.atan(@as(f32, std.math.sqrt1_2)));

    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE | rl.FLAG_VSYNC_HINT);
    rl.InitWindow(screen_width, screen_height, "Draw a Rotating Cube");
    defer rl.CloseWindow();

    var camera = rl.Camera{
        .position = .{ .x = 3, .y = 3, .z = 3 },
        .target = .{ .x = 0, .y = y_center, .z = 0 }, // Center of cube
        .up = .{ .x = 0, .y = 1, .z = 0 },
        .fovy = 45, // Camera field-of-view Y
        .projection = rl.CAMERA_PERSPECTIVE,
    };

    rl.SetTargetFPS(60);

    while (!rl.WindowShouldClose()) {
        if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) show_grid = !show_grid;
        if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_RIGHT)) dark_mode = !dark_mode;

        rl.UpdateCamera(&camera, rl.CAMERA_ORBITAL);

        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(if (dark_mode) rl.BLACK else rl.RAYWHITE);
        {
            rl.BeginMode3D(camera);
            defer rl.EndMode3D();
            {
                rl.rlPushMatrix();
                defer rl.rlPopMatrix();
                rl.rlTranslatef(0, y_center, 0);
                rl.rlRotatef(z_rot, 0, 0, 1);
                rl.rlRotatef(x_rot, 1, 0, 0);
                rl.DrawCubeWiresV(position, size, if (dark_mode) rl.LIME else rl.BLACK);
            }
            if (show_grid) rl.DrawGrid(12, 0.75);
        }
    }
}
