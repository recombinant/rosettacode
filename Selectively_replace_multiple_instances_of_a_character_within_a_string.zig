// https://rosettacode.org/wiki/Selectively_replace_multiple_instances_of_a_character_within_a_string
// {{works with|Zig|0.16.0}}
// {{trans|C}}
const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;

    const string = "abracadabra";

    const replaced = try gpa.dupe(u8, string);
    defer gpa.free(replaced);

    // Null terminated replacement character arrays
    var a_rep: [*c]const u8 = "ABaCD";
    var b_rep: [*c]const u8 = "E";
    var r_rep: [*c]const u8 = "rF";

    for (replaced) |*ch| {
        // Use C-style pointer arithmetic
        const ptr: *[*c]const u8 = switch (ch.*) {
            'a' => &a_rep,
            'b' => &b_rep,
            'r' => &r_rep,
            else => continue,
        };
        if (ptr.*.* != 0) {
            ch.* = ptr.*.*;
            ptr.* += 1;
        }
    }
    std.debug.print("{s}\n", .{replaced});
}
