// https://rosettacode.org/wiki/Sailors,_coconuts_and_a_monkey_problem
// {{works with|Zig|0.16.0}}
// {{trans|Kotlin}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    //
    var coconuts: u32 = 11;
    var ns: u32 = 2;
    outer: while (ns <= 9) : (ns += 1) {
        var hidden = try gpa.alloc(u32, ns);
        defer gpa.free(hidden);
        coconuts = (coconuts / ns) * ns + 1;
        while (true) {
            var nc = coconuts;
            for (1..ns + 1) |s| {
                if (nc % ns == 1) {
                    hidden[s - 1] = nc / ns;
                    nc -= hidden[s - 1] + 1;
                    if (s == ns and nc % ns == 0) {
                        print("{} sailors require a minimum of {} coconuts\n", .{ ns, coconuts });
                        for (1..ns + 1) |t| print("\tSailor {} hides {}\n", .{ t, hidden[t - 1] });
                        print("\tThe monkey gets {}\n", .{ns});
                        print("\tFinally, each sailor takes {}\n\n", .{nc / ns});
                        continue :outer;
                    }
                } else break;
            }
            coconuts += ns;
        }
    }
}
