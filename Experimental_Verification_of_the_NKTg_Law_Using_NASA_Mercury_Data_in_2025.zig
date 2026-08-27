// https://rosettacode.org/wiki/Experimental_Verification_of_the_NKTg_Law_Using_NASA_Mercury_Data_in_2025
// {{works with|Zig|0.16.0}}
// {{trans|Rust}}
const std = @import("std");
const Io = std.Io;

const MercuryData = struct {
    date: []const u8,
    x: f64, // position (m)
    v: f64, // velocity (m/s)
    m: f64, // mass (kg)
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;

    // ================================
    // 1. NASA 2024 Reference Data
    // ================================
    const reference_2024: MercuryData = .{
        .date = "31/12/2024",
        .x = 4.64e10,
        .v = 5.81e4,
        .m = 3.30e23,
    };

    const p_ref = reference_2024.m * reference_2024.v;
    const nktg1_constant = reference_2024.x * p_ref;

    try stdout.print("NKTg₁ reference constant: {e:.3}\n", .{nktg1_constant});
    try stdout.writeAll("========================================\n\n");

    // ================================
    // 2. NASA 2025 Real Data
    // ================================
    const nasa_2025: [5]MercuryData = .{
        .{ .date = "01/01/2025", .x = 5.16e10, .v = 5.34e4, .m = 3.30e23 },
        .{ .date = "01/04/2025", .x = 6.97e10, .v = 3.89e4, .m = 3.30e23 },
        .{ .date = "01/07/2025", .x = 5.49e10, .v = 5.04e4, .m = 3.30e23 },
        .{ .date = "01/10/2025", .x = 6.83e10, .v = 3.98e4, .m = 3.30e23 },
        .{ .date = "31/12/2025", .x = 4.61e10, .v = 5.89e4, .m = 3.30e23 },
    };

    // Mass variation rate (MESSENGER data)
    const dm_dt = -0.5; // kg/s

    try stdout.writeAll("Date           v_NKTg      tv_NASA Rel.Error(%)      NKTg₂\n");
    try stdout.writeAll("-----------------------------------------------------------\n");

    for (nasa_2025) |data| {

        // Interpolated velocity from constant NKTg1
        const v_nktg = nktg1_constant / (data.x * data.m);

        // Relative error
        const rel_error = ((v_nktg - data.v) / data.v) * 100.0;

        // Momentum
        const p = data.m * v_nktg;

        // NKTg2 calculation
        const nktg2 = dm_dt * p;

        try stdout.print("{s:<10} {e:>10.3} {e:>10.3} {:>14.4} {e:>10.3}\n", .{
            data.date,
            v_nktg,
            data.v,
            rel_error,
            nktg2,
        });
    }

    try stdout.writeAll("\n========================================\n");
    try stdout.writeAll("Interpretation:\n");
    try stdout.writeAll("NKTg₁ maintained as constant.\n");
    try stdout.writeAll("NKTg₂ negative → mass variation resists motion.\n");

    try stdout.flush();
}
