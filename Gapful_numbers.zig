// https://rosettacode.org/wiki/Gapful_numbers

pub fn main() !void {
    try printGaps(100, 30);
    try printGaps(1_000_000, 15);
    try printGaps(1_000_000_000, 15);
}

fn gapful(comptime T: type, n: T) bool {
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("T must be an unsigned int type");

    var m = n;
    while (m >= 10)
        m /= 10;
    return n % ((n % 10) + 10 * (m % 10)) == 0;
}

fn printGaps(start: u64, count_limit: usize) !void {
    const writer = @import("std").io.getStdOut().writer();

    var i = start;
    var count: @TypeOf(count_limit) = 0;

    try writer.print("\nFirst {d} Gapful numbers >= {d} :\n", .{ count_limit, start });

    while (count < count_limit) {
        if (gapful(@TypeOf(i), i)) {
            count += 1;
            try writer.print("{d:>3} : {d}\n", .{ count, i });
        }
        i += 1;
    }

    try writer.writeAll("\n");
}
