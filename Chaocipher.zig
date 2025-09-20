// https://rosettacode.org/wiki/Chaocipher
// {{works with|Zig|0.15.1}}
// {{trans|Nim (Another Implementation)}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const plain_text = "WELLDONEISBETTERTHANWELLSAID";
    try stdout.print("The original plaintext is: {s}\n", .{plain_text});

    var buffer: [plain_text.len]u8 = undefined;
    try stdout.print("\nThe left and right alphabets after each permutation during encryption are:\n\n", .{});

    const cipher_text = try chao(plain_text, &buffer, .encrypt, true, stdout);
    try stdout.print("\nThe ciphertext is: {s}\n", .{cipher_text});

    const plain_text2 = try chao(cipher_text, &buffer, .decrypt, false, stdout);
    try stdout.print("\nThe recovered plaintext is: {s}\n", .{plain_text2});

    try stdout.flush();
}

const ChaoError = error{
    OnlyAsciiAlphabetic,
};

const ChaoMode = enum {
    encrypt,
    decrypt,
};

fn chao(text_in: []const u8, text_out: []u8, mode: ChaoMode, verbose: bool, writer: *std.Io.Writer) ![]const u8 {
    var left = "HXUCZVAMDSLKPEFJRIGTWOBNYQ".*;
    var right = "PTLNBQDEOYSFAVZKGJRIHWXUMC".*;

    for (text_in) |c|
        if (!std.ascii.isAlphabetic(c))
            return ChaoError.OnlyAsciiAlphabetic;

    for (text_in, text_out, 0..) |in, *out, i| {
        if (verbose)
            try writer.print("{s}  {s}\n", .{ left, right });

        var index: usize = undefined;
        switch (mode) {
            .encrypt => {
                index = std.mem.indexOfScalar(u8, &right, in).?;
                out.* = left[index];
            },
            .decrypt => {
                index = std.mem.indexOfScalar(u8, &left, in).?;
                out.* = right[index];
            },
        }
        // permute is expensive
        // no need to permute on last pass
        if (i == text_in.len - 1)
            break;

        // permute left
        std.mem.rotate(u8, &left, index);
        std.mem.rotate(u8, left[1..14], 1);

        // permute right
        std.mem.rotate(u8, &right, index + 1);
        std.mem.rotate(u8, right[2..14], 1);
    }
    return text_out;
}
