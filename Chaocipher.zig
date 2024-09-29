// https://rosettacode.org/wiki/Chaocipher
// Translation of Nim (Another Implementation)
const std = @import("std");
const ascii = std.ascii;
const mem = std.mem;

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const plain_text = "WELLDONEISBETTERTHANWELLSAID";
    try stdout.print("The original plaintext is: {s}\n", .{plain_text});

    var buffer: [plain_text.len]u8 = undefined;
    try stdout.print("\nThe left and right alphabets after each permutation during encryption are:\n\n", .{});

    const cipher_text = try chao(plain_text, &buffer, .encrypt, true, stdout);
    try stdout.print("\nThe ciphertext is: {s}\n", .{cipher_text});

    const plain_text2 = try chao(cipher_text, &buffer, .decrypt, false, stdout);
    try stdout.print("\nThe recovered plaintext is: {s}\n", .{plain_text2});

    try bw.flush();
}

const ChaoError = error{
    OnlyAsciiAlphabetic,
};

const ChaoMode = enum {
    encrypt,
    decrypt,
};

fn chao(text_in: []const u8, text_out: []u8, mode: ChaoMode, verbose: bool, writer: anytype) ![]const u8 {
    var left = "HXUCZVAMDSLKPEFJRIGTWOBNYQ".*;
    var right = "PTLNBQDEOYSFAVZKGJRIHWXUMC".*;

    for (text_in) |c|
        if (!ascii.isAlphabetic(c))
            return ChaoError.OnlyAsciiAlphabetic;

    for (text_in, text_out, 0..) |in, *out, i| {
        if (verbose)
            try writer.print("{s}  {s}\n", .{ left, right });

        var index: usize = undefined;
        switch (mode) {
            .encrypt => {
                index = mem.indexOfScalar(u8, &right, in).?;
                out.* = left[index];
            },
            .decrypt => {
                index = mem.indexOfScalar(u8, &left, in).?;
                out.* = right[index];
            },
        }
        // permute is expensive
        // no need to permute on last pass
        if (i == text_in.len - 1)
            break;

        // permute left
        mem.rotate(u8, &left, index);
        mem.rotate(u8, left[1..14], 1);

        // permute right
        mem.rotate(u8, &right, index + 1);
        mem.rotate(u8, right[2..14], 1);
    }
    return text_out;
}
