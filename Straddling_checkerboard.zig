// https://rosettacode.org/wiki/Straddling_checkerboard
// {{works with|Zig|0.16.0}}

// The output compares to the Kotlin & Wren output
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout: *Io.Writer = &stdout_writer.interface;

    var enc_buffer: [100]u8 = undefined;
    var dec_buffer: [100]u8 = undefined;

    const cb = CheckerBoard.init();

    const messages = [_][]const u8{
        "Attack at dawn",
        "One night-it was on the twentieth of March, 1888-I was returning",
        "In the winter 1965/we were hungry/just barely alive",
        "you have put on 7.5 pounds since I saw you.",
        "The checkerboard cake recipe specifies 3 large eggs and 2.25 cups of flour.",
    };

    for (messages) |msg| {
        const enc = try cb.encipher(&enc_buffer, msg);
        const dec = try cb.decipher(&dec_buffer, enc);

        try stdout.print("Message   : {s}\n", .{msg});
        try stdout.print("Encrypted : {s}\n", .{enc});
        try stdout.print("Decrypted : {s}\n", .{dec});
        try stdout.writeByte('\n');
    }
    try stdout.flush();
}

const CheckerBoard = struct {
    const board: [3]*const [10:0]u8 = .{ "ET AON RIS", "BCDFGHJKLM", "PQ/UVWXYZ." };
    const rows: [3]u8 = .{ 0, 2, 6 };
    const escape = 62;
    const key = "0452"; // for securing/desecuring
    encode: [128]?u8 = std.mem.zeroes([128]?u8),
    decode: [128]?u8 = std.mem.zeroes([128]?u8),

    fn init() CheckerBoard {
        var cb: CheckerBoard = .{};

        // Create lookups for board.
        for (board, rows) |letters, row| {
            for (letters, 0..) |ch_, col| {
                if (ch_ == ' ')
                    continue;
                const ch = std.ascii.toUpper(ch_);
                cb.encode[ch] = @intCast(row * 10 + col);
                cb.decode[row * 10 + col] = ch;
            }
        }
        return cb;
    }
    fn encipher(self: CheckerBoard, output: []u8, msg: []const u8) ![]const u8 {
        var w: Io.Writer = .fixed(output);

        // encipherment
        for (msg) |ch| {
            if (ch == '/') // escape character
                continue;
            if (std.ascii.isDigit(ch)) {
                try w.print("{d}{d}", .{ escape, ch - '0' });
                continue;
            }
            if (self.encode[std.ascii.toUpper(ch)]) |encoded|
                try w.print("{d}", .{encoded});
        }
        // secure with the key
        for (w.buffer[0..w.end], 0..) |*c, i|
            c.* = (c.* - '0' + key[i % key.len] - '0') % 10 + '0';

        return w.buffered();
    }
    fn decipher(self: CheckerBoard, output: []u8, msg: []const u8) ![]const u8 {
        var w: Io.Writer = .fixed(output);
        var escaped = false;
        var pair0: ?usize = null;

        for (msg, 0..) |ch_, i| {
            // unsecure
            const ch = (10 + ch_ - key[i % key.len]) % 10 + '0';
            // decipherment
            if (escaped) {
                escaped = false;
                try w.writeByte(ch);
                continue;
            }
            const digit = ch - '0';
            if (pair0) |digit0| {
                pair0 = null;
                const idx = digit0 + digit;
                if (idx == escape) {
                    escaped = true;
                    continue;
                }
                try w.print("{c}", .{self.decode[idx].?});
                continue;
            }
            if (std.mem.indexOfScalar(u8, &rows, digit)) |idx| {
                if (idx != 0) {
                    pair0 = digit * 10; // First digit of pair
                    continue;
                }
            }
            try w.print("{c}", .{self.decode[digit].?});
        }
        return w.buffered();
    }
};
