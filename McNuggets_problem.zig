// https://rosettacode.org/wiki/McNuggets_problem
// {{works with|Zig|0.16.0}}
// {{trans|C}}

// No allocation required.
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    const max = mcnuggets(100);

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Maximum non-McNuggets number is {}\n", .{max});

    try stdout.flush();
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
