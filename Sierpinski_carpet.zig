// https://rosettacode.org/wiki/Sierpinski_carpet
// {{works with|Zig|0.16.0}}
// {{trans|C++}}

// BCT = Binary-Coded Ternary: pairs of bits form one digit [0,1,2] (0b11 is invalid digit)

const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const arena: *std.heap.ArenaAllocator = init.arena;
    const io: Io = init.io;
    const args = init.minimal.args;

    // parse N from first argument, if no argument, use 3 as default value
    const n = blk: {
        const slice = try args.toSlice(arena.allocator());
        if (slice.len == 1)
            break :blk 3;
        break :blk try std.fmt.parseInt(u4, slice[1], 10);
    };

    // check for valid N (0..9) - 16 requires 33 bits for BCT form 1<<(n*2) => hard limit
    if (n > 9) { // but N=9 already produces 370MB output
        var stderr_writer = Io.File.stderr().writer(io, &.{}); // unbuffered
        const stderr = &stderr_writer.interface;
        try stderr.print("N out of range (use 0..9): {d}\n", .{n});
        return error.NOutOfRange;
    }

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    // 3**n in BCT form (initial value for loops)
    const size_bct: u32 = std.math.shl(u32, 1, n * 2);
    // draw the carpet, two nested loops counting down in BCT form of values
    var y = size_bct;
    while (y != 0) { // all lines loop
        y = decrementBCT(y); // --Y (in BCT)
        var x = size_bct;
        while (x != 0) { // line loop
            x = decrementBCT(x); // --X (in BCT)
            // check if x has ternary digit "1" at same position(s) as y -> output space (hole)
            try stdout.writeByte(if (x & y & bct_low_bits != 0) ' ' else '#');
        }
        try stdout.writeByte('\n');
    }
    try stdout.flush(); // cannot defer because of try
}

const bct_low_bits: u32 = 0x55555555;

fn decrementBCT(v_: u32) u32 {
    const v = v_ - 1; // either valid BCT (v-1), or block of bottom 0b00 digits becomes invalid 0b11
    return v ^ (v & (v >> 1) & bct_low_bits); // fix all 0b11 to 0b10 (digit "2")
}
