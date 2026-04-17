// https://rosettacode.org/wiki/O%27Halloran_numbers
// {{works with|Zig|0.16.0}}
// {{trans|C++}}
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    const maximum_area = 1_000;
    const half_maximum_area = maximum_area / 2;

    var ohalloran_numbers: std.StaticBitSet(half_maximum_area) = .initFull();
    for (0..3) |i|
        ohalloran_numbers.unset(i);

    for (1..maximum_area) |length|
        for (1..half_maximum_area) |width|
            for (1..half_maximum_area) |height| {
                const half_area = length * width + length * height + width * height;
                if (half_area < half_maximum_area)
                    ohalloran_numbers.unset(half_area);
            };

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print(
        "{} even integer values larger than 6 and less than 1000 which cannot be the surface area of an integer cuboid:\n",
        .{ohalloran_numbers.count()},
    );
    for (3..half_maximum_area) |i|
        if (ohalloran_numbers.isSet(i))
            try stdout.print("{} ", .{i * 2});
    try stdout.writeByte('\n');

    try stdout.flush();
}
