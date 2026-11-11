// https://rosettacode.org/wiki/Geohash
// {{works with|Zig|0.17.1}}
// {{trans|Rust}}
// copied from rosettacode and tweaked
const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Writer = std.Io.Writer;

pub fn main(init: std.process.Init) !void {
    const allocator: Allocator = init.gpa;
    // --------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file = std.Io.File.stdout().writer(init.io, &stdout_buffer);
    const stdout = &stdout_file.interface;
    // ----------------------------------------------------------
    const locations: []const Location = &.{
        .init(51.433718, -0.214126),
        .init(51.433718, -0.214126),
        .init(57.64911, 10.40744),
        .init(57.64911, 10.40744),
    };
    const precisions: []const u32 = &.{ 2, 9, 11, 21 };

    var test_results: ArrayList([]const u8) = .empty;
    defer {
        for (test_results.items) |result|
            allocator.free(result);
        test_results.deinit(allocator);
    }

    for (locations, precisions) |location, precision| {
        var aw: Writer.Allocating = .init(allocator);
        try encodeGeohash(location, precision, &aw.writer);
        const geohash = try aw.toOwnedSlice(); // obviates aw.deinit();
        try test_results.append(allocator, geohash);
        try stdout.print("geohash for {f} with precision {:2} => {s}\n", .{ location, precision, geohash });
    }
    try stdout.writeByte('\n');

    for (test_results.items) |test_result| {
        var aw: Writer.Allocating = .init(allocator);
        defer aw.deinit();
        try decodeGeohash(test_result, &aw.writer);
        try stdout.print("{s:<21} => {s}\n", .{ test_result, aw.written() });
    }
    // ----------------------------------------------------------
    try stdout.flush();
}

const GEO_BASE_32 = "0123456789bcdefghjkmnpqrstuvwxyz";

const Range = struct {
    lower: f64,
    upper: f64,

    fn init(lower: f64, upper: f64) Range {
        return .{ .lower = lower, .upper = upper };
    }
    fn midRange(self: *const Range) f64 {
        return (self.lower + self.upper) / 2;
    }
    fn absError(self: *const Range) f64 {
        return @abs(self.lower - self.upper);
    }
};
const Location = struct {
    latitude: f64,
    longitude: f64,

    fn init(latitude: f64, longitude: f64) Location {
        return .{ .latitude = latitude, .longitude = longitude };
    }
    pub fn format(self: Location, w: *Writer) !void {
        const sector_sn = if (self.latitude < 0.0) " S" else " N";
        const sector_we = if (self.longitude < 0.0) " W" else " E";
        try w.print("({d}{s}, {d}{s})", .{ self.latitude, sector_sn, self.longitude, sector_we });
    }
};
fn encodeGeohash(location: Location, precision: u32, w: *Writer) Writer.Error!void {
    var latitude_range: Range = .init(-90.0, 90.0);
    var longitude_range: Range = .init(-180.0, 180.0);

    var char_count: u32 = 0;
    var geohash_value: u32 = 0;
    var bit_count: u32 = 0;
    var even = true;

    while (char_count < precision) {
        const value = if (even) location.longitude else location.latitude;
        const range = if (even) longitude_range else latitude_range;
        const mid_range = range.midRange();

        if (value > mid_range) {
            geohash_value = (geohash_value << 1) + 1;
            if (even)
                longitude_range = .init(mid_range, longitude_range.upper)
            else
                latitude_range = .init(mid_range, latitude_range.upper);
        } else {
            geohash_value <<= 1;
            if (even)
                longitude_range = .init(longitude_range.lower, mid_range)
            else
                latitude_range = .init(latitude_range.lower, mid_range);
        }

        even = !even;
        if (bit_count < 4) {
            bit_count += 1;
        } else {
            bit_count = 0;
            try w.writeByte(GEO_BASE_32[geohash_value]);
            char_count += 1;

            geohash_value = 0;
        }
    }
    return;
}
fn decodeGeohash(geohash: []const u8, w: *Writer) Writer.Error!void {
    // Simple check for valid geohash
    if (std.mem.findNone(u8, geohash, GEO_BASE_32) != null) @panic("Invalid geohash");

    var latitude_range: Range = .init(-90.0, 90.0);
    var longitude_range: Range = .init(-180.0, 180.0);
    var even = true;

    for (geohash) |ch| {
        const position = std.mem.findScalar(u8, GEO_BASE_32, ch).?;
        // --------------------------------------------------
        // Calculate the bit twiddling baggage at compile time.
        const bits = comptime std.math.log2_int(usize, GEO_BASE_32.len);
        const T = @Int(.unsigned, bits);
        var bit_mask: T = comptime @as(T, 1) << @intCast(bits - 1); // Start with the most significant bit
        std.debug.assert(bits == 5);
        std.debug.assert(T == u5);
        std.debug.assert(bit_mask == 0b10000);
        // --------------------------------------------------
        // Convert position using 5-bit binary
        for (0..bits) |_| {
            const mid_range = if (even) longitude_range.midRange() else latitude_range.midRange();

            const bit_set = (position & bit_mask) != 0;

            if (!bit_set) {
                if (even)
                    longitude_range = .init(longitude_range.lower, mid_range)
                else
                    latitude_range = .init(latitude_range.lower, mid_range);
            } else {
                if (even)
                    longitude_range = .init(mid_range, longitude_range.upper)
                else
                    latitude_range = .init(mid_range, latitude_range.upper);
            }
            even = !even;
            bit_mask >>= 1;
        }
    }
    const latitude_error = latitude_range.absError();
    const longitude_error = longitude_range.absError();
    const max_error = @max(latitude_error, longitude_error);
    const mid_latitude = latitude_range.midRange();
    const mid_longitude = longitude_range.midRange();
    const sector_sn: u8 = if (mid_latitude < 0.0) 'S' else 'N';
    const sector_we: u8 = if (mid_longitude < 0.0) 'W' else 'E';

    try w.print("({d:.15} {c}, {d:.15} {c}) ± {d:.15}", .{
        mid_latitude,
        sector_sn,
        mid_longitude,
        sector_we,
        max_error,
    });
}
