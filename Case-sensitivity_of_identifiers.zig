// https://rosettacode.org/wiki/Case-sensitivity_of_identifiers
// from https://github.com/tiehuis/zig-rosetta
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    const dog = "Bejamin";
    const Dog = "Samba";
    const DOG = "Bernie";

    print("The three dogs named {s}, {s}, and {s}\n", .{ dog, Dog, DOG });
}
