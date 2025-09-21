// https://rosettacode.org/wiki/Sailors,_coconuts_and_a_monkey_problem
// {{works with|Zig|0.15.1}}
// {{trans|Kotlin}}
const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    //
    var coconuts: u32 = 11;
    var ns: u32 = 2;
    outer: while (ns <= 9) : (ns += 1) {
        var hidden = try allocator.alloc(u32, ns);
        defer allocator.free(hidden);
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
