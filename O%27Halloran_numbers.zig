// https://rosettacode.org/wiki/O%27Halloran_numbers
// Translation of C++
const std = @import("std");

pub fn main() !void {
    const maximum_area = 1_000;
    const half_maximum_area = maximum_area / 2;

    var ohalloran_numbers = std.StaticBitSet(half_maximum_area).initFull();
    for (0..3) |i|
        ohalloran_numbers.unset(i);

    for (1..maximum_area) |length|
        for (1..half_maximum_area) |width|
            for (1..half_maximum_area) |height| {
                const half_area = length * width + length * height + width * height;
                if (half_area < half_maximum_area)
                    ohalloran_numbers.unset(half_area);
            };

    const stdout = std.io.getStdOut().writer();
    try stdout.print(
        "{} even integer values larger than 6 and less than 1000 which cannot be the surface area of an integer cuboid:\n",
        .{ohalloran_numbers.count()},
    );
    for (3..half_maximum_area) |i|
        if (ohalloran_numbers.isSet(i))
            try stdout.print("{} ", .{i * 2});
    try stdout.writeByte('\n');
}
