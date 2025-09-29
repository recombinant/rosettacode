// https://rosettacode.org/wiki/Animate_a_pendulum
// {{works with|Zig|0.15.1}}
// {{libheader|raylib}}
const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

pub fn main() void {
    rl.SetConfigFlags(rl.FLAG_VSYNC_HINT);
    rl.InitWindow(640, 320, "Pendulum");
    defer rl.CloseWindow();

    // Simulation constants.
    const g = 9.81; // Gravity (should be positive).
    const length = 5.0; // Pendulum length.
    const theta0 = std.math.pi / 3.0; // Initial angle for which omega = 0.

    const e = g * length * (1 - @cos(theta0)); // Total energy = potential energy when starting.

    // Simulation variables.
    var theta: f32 = theta0; // Current angle.
    var omega: f32 = 0; // Angular velocity = derivative of theta.
    var accel: f32 = -g / length * @sin(theta0); // Angular acceleration = derivative of omega.

    rl.SetTargetFPS(60);

    while (!rl.WindowShouldClose()) // Detect window close button or ESC key
    {
        const half_width = @as(f32, @floatFromInt(rl.GetScreenWidth())) / 2;
        const pivot = rl.Vector2{ .x = half_width, .y = 0 };

        // Compute the position of the mass.
        const mass = rl.Vector2{
            .x = 300 * @sin(theta) + pivot.x,
            .y = 300 * @cos(theta),
        };

        {
            rl.BeginDrawing();
            defer rl.EndDrawing();

            rl.ClearBackground(rl.RAYWHITE);

            rl.DrawLineV(pivot, mass, rl.GRAY);
            rl.DrawCircleV(mass, 20, rl.GRAY);
        }

        // Update theta and omega.
        const dt = rl.GetFrameTime();
        theta += (omega + dt * accel / 2) * dt;
        omega += accel * dt;

        // If, due to computation errors, potential energy is greater than total energy,
        // reset theta to ±theta0 and omega to 0.
        if (length * g * (1 - @cos(theta)) >= e) {
            theta = std.math.sign(theta) * theta0;
            omega = 0;
        }
        accel = -g / length * @sin(theta);
    }
}
