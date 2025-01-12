// https://rosettacode.org/wiki/McNuggets_problem
// Translation of C
// No allocation required.
const std = @import("std");
pub fn main() !void {
    const max = mcnuggets(100);

    const writer = std.io.getStdOut().writer();
    try writer.print("Maximum non-McNuggets number is {}\n", .{max});
}

fn mcnuggets(limit: usize) usize {
    var max: usize = 0;
    var i: usize = 0;

    loopstart: while (i < limit) {
        var sixes: usize = 0;
        while (sixes * 6 <= i) : (sixes += 1) {
            if (sixes * 6 == i) {
                i += 1;
                continue :loopstart;
            }

            var nines: usize = 0;
            while (nines * 9 <= i) : (nines += 1) {
                if (sixes * 6 + nines * 9 == i) {
                    i += 1;
                    continue :loopstart;
                }

                var twenties: usize = 0;
                while (twenties * 20 <= i) : (twenties += 1)
                    if (sixes * 6 + nines * 9 + twenties * 20 == i) {
                        i += 1;
                        continue :loopstart;
                    };
            }
        }
        max = i;
        i += 1;
    }
    return max;
}
