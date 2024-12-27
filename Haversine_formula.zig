// https://rosettacode.org/wiki/Haversine_formula
// Translation of R

// When a Zig struct type can be inferred then anonymous structs .{} can be
// used for initialisation. This can be seen on the lines where the constants
// bna and lax are instantiated.

// A Zig struct can have methods, the same as an enum and or a union. They are
// only namespaced functions that can be called with dot syntax.

const std = @import("std");

pub fn main() !void {
    // Coordinates are found here:
    //     http://www.airport-data.com/airport/BNA/
    //     http://www.airport-data.com/airport/LAX/

    const bna = LatLong{
        .lat = .{ .d = 36, .m = 7, .s = 28.10 },
        .long = .{ .d = 86, .m = 40, .s = 41.50 },
    };

    const lax = LatLong{
        .lat = .{ .d = 33, .m = 56, .s = 32.98 },
        .long = .{ .d = 118, .m = 24, .s = 29.05 },
    };

    const distance = calcGreatCircleDistance(bna, lax);

    std.debug.print("Output: {d:.3} km\n", .{distance});

    // Output: 2886.326609 km
}

const LatLong = struct { lat: DMS, long: DMS };

/// degrees, minutes, decimal seconds
const DMS = struct {
    d: f64,
    m: f64,
    s: f64,

    fn toRadians(self: DMS) f64 {
        return (self.d + self.m / 60 + self.s / 3600) * std.math.pi / 180;
    }
};

// Volumetric mean radius is 6371 km, see http://nssdc.gsfc.nasa.gov/planetary/factsheet/earthfact.html
// The diameter is thus 12742 km
fn calcGreatCircleDistance(lat_long1: LatLong, lat_long2: LatLong) f64 {
    const lat1 = lat_long1.lat.toRadians();
    const lat2 = lat_long2.lat.toRadians();
    const long1 = lat_long1.long.toRadians();
    const long2 = lat_long2.long.toRadians();

    const a = @sin(0.5 * (lat2 - lat1));
    const b = @sin(0.5 * (long2 - long1));

    return 12742 * std.math.asin(@sqrt(a * a + @cos(lat1) * @cos(lat2) * b * b));
}
