// http://rosettacode.org/wiki/Experimental_Verification_of_the_NKTg_Law_in_Earth_Orbit_Based_on_NASA’s_2025_Earth_Dataset
// {{works with|Zig|0.16.0}}
// {{trans|Rust}}
const std = @import("std");
const Io = std.Io;

const DM_DT: f64 = -1.8; // kg/s

const OrbitalData = struct {
    date: []const u8,
    x: f64,
    v: f64,
    m: f64,
};

const ResultRow = struct {
    date: []const u8,
    p: f64,
    nktg1: f64,
    nktg2: f64,
    v_sim: f64,
    v_nasa: f64,
    err: f64,

    const write = writeResultRow;
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;

    // Simulated NKTg 2025 dataset
    const sim_2025 = [_]OrbitalData{
        .{ .date = "1/1/2025", .x = 1.471012e11, .v = 3.0276e4, .m = 5.97219e24 },
        .{ .date = "4/1/2025", .x = 1.494953e11, .v = 2.9791e4, .m = 5.97218999999998e24 },
        .{ .date = "7/1/2025", .x = 1.520965e11, .v = 2.9282e4, .m = 5.97218999999997e24 },
        .{ .date = "10/1/2025", .x = 1.496328e11, .v = 2.9764e4, .m = 5.97218999999995e24 },
        .{ .date = "12/31/2025", .x = 1.471025e11, .v = 3.0276e4, .m = 5.97218999999994e24 },
    };

    // NASA observed velocities
    const nasa_2025 = [_]struct { []const u8, f64 }{
        .{ "1/1/2025", 3.0287e4 },
        .{ "4/1/2025", 2.9791e4 },
        .{ "7/1/2025", 2.9291e4 },
        .{ "10/1/2025", 2.9778e4 },
        .{ "12/31/2025", 3.0286e4 },
    };

    try stdout.writeAll("\nExperimental Verification of NKTg Law (Earth 2025)\n");

    try stdout.print("{s:<12} {s:>14} {s:>14} {s:>14} {s:>12} {s:>12} {s:>10}\n", .{ "Date", "Momentum(p)", "NKTg1", "NKTg2", "v_sim", "v_NASA", "Error" });

    try stdout.splatByteAll('-', 95);
    try stdout.writeByte('\n');

    for (sim_2025, 0..) |data, i| {
        const p = momentum(data.m, data.v);
        const n1 = nktg1(data.x, p);
        const n2 = nktg2(p);

        const v_nasa = nasa_2025[i][1];
        const err = calcRelativeError(data.v, v_nasa);

        const row = ResultRow{
            .date = data.date,
            .p = p,
            .nktg1 = n1,
            .nktg2 = n2,
            .v_sim = data.v,
            .v_nasa = v_nasa,
            .err = err,
        };

        try row.write(stdout);
    }

    try stdout.flush();
}

fn writeResultRow(row: *const ResultRow, w: *Io.Writer) !void {
    try w.print(
        "{s:<12} {e:>14.3} {e:>14.3} {e:>14.3} {e:>12.3} {e:>12.3} {:>9.4}%\n",
        .{
            row.date,
            row.p,
            row.nktg1,
            row.nktg2,
            row.v_sim,
            row.v_nasa,
            row.err,
        },
    );
}

fn momentum(m: f64, v: f64) f64 {
    return m * v;
}

fn nktg1(x: f64, p: f64) f64 {
    return x * p;
}

fn nktg2(p: f64) f64 {
    return DM_DT * p;
}

fn calcRelativeError(sim: f64, nasa: f64) f64 {
    return ((sim - nasa) / nasa) * 100.0;
}
