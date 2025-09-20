// https://rosettacode.org/wiki/Air_mass
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll("Angle     0 m              13700 m\n");
    try stdout.writeAll("------------------------------------\n");
    var z: f64 = 0;
    while (z <= 90) : (z += 5)
        try stdout.print(
            "{d:2}      {d:11.8}      {d:11.8}\n",
            .{ z, calcAirmass(0.0, z), calcAirmass(13700.0, z) },
        );

    try stdout.flush();
}

const RE = 6371000; // Earth radius in meters
const DD = 0.001; // integrate in this fraction of the distance already covered
const FIN = 10000000; // integrate only to a height of 10000km, effectively infinity

/// a = altitude of observer
/// z = zenith angle (in degrees)
fn calcAirmass(a: f64, z: f64) f64 {
    return calcColumnDensity(a, z) / calcColumnDensity(a, 0.0);
}

/// integrates density along the line of sight
/// a = altitude of observer
/// z = zenith angle (in degrees)
fn calcColumnDensity(a: f64, z: f64) f64 {
    var sum: f64 = 0.0;
    var d: f64 = 0.0;
    while (d < FIN) {
        // adaptive step size to avoid it taking forever
        var delta = DD * d;
        if (delta < DD)
            delta = DD;
        sum += rho(calcHeight(a, z, d + 0.5 * delta)) * delta;
        d += delta;
    }
    return sum;
}

/// returns height above sea level
/// a = altitude of observer
/// z = zenith angle (in degrees)
/// d = distance along line of sight
fn calcHeight(a: f64, z: f64, d: f64) f64 {
    const aa = RE + a;
    const hh = @sqrt(aa * aa + d * d - 2.0 * d * aa * @cos(std.math.degreesToRadians(180 - z)));
    return hh - RE;
}

/// the density of air as a function of 'height' above sea level
fn rho(height: f64) f64 {
    return @exp(-height / 8500.0);
}
