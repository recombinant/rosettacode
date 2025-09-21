// https://rosettacode.org/wiki/The_ISAAC_cipher
// {{works with|Zig|0.15.1}}

// Links with the (tweaked) original C source code
//   zig run The_ISAAC_cipher.zig The_ISAAC_cipher.c -lc -I.
const std = @import("std");
const c = @cImport({
    @cInclude("The_ISAAC_cipher.h");
});

/// This is a near equivalent of the strcpy(), returning a slice of dest
/// containing the characters copied.
fn copy(dest: []u8, src: [*c]const u8) []const u8 {
    const span = std.mem.span(src); // slice from null terminated C string
    const slice = dest[0..span.len];
    @memcpy(slice, span);
    return slice; // pointer and length
}

pub fn main() !void {
    // input: message and key
    const msg = "a Top Secret secret";
    const key = "this is my secret key";
    // Encrypt: Vernam XOR
    c.iSeed(key, 1);
    const vctx_slice = blk: {
        // fill with zeroes to ensure [*:0] sentinel as vctx_slice pointer will be passed to C
        var vctx: [c.MAXMSG]u8 = std.mem.zeroes([c.MAXMSG]u8);
        const result = c.Vernam(msg);
        break :blk copy(&vctx, result); // return slice from block expression
    };
    // Encrypt: Caesar
    const cctx_slice = blk: {
        // fill with zeroes to ensure [*:0] sentinel as cctx_slice pointer will be passed to C
        var cctx: [c.MAXMSG]u8 = std.mem.zeroes([c.MAXMSG]u8);
        const result = c.CaesarStr(c.mEncipher, msg, c.MOD, c.START);
        break :blk copy(&cctx, result);
    };
    // Decrypt: Vernam XOR
    c.iSeed(key, 1);
    const vptx_slice = blk: {
        var vptx: [c.MAXMSG]u8 = undefined; // not used by C, no sentinel required
        const result = c.Vernam(vctx_slice.ptr);
        break :blk copy(&vptx, result);
    };
    // Decrypt: Caesar
    const cptx_slice = blk: {
        var cptx: [c.MAXMSG]u8 = undefined; // not used by C, no sentinel required
        const result = c.CaesarStr(c.mDecipher, cctx_slice.ptr, c.MOD, c.START);
        break :blk copy(&cptx, result);
    };
    // Program output
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Message: {s}\n", .{msg});
    try stdout.print("Key    : {s}\n", .{key});
    try stdout.print("XOR    : ", .{});
    // Output Vernam ciphertext as a string of hex digits
    for (vctx_slice) |ch| try stdout.print("{X:0>2}", .{ch});
    try stdout.writeByte('\n');
    // Output Vernam decrypted plaintext
    try stdout.print("XOR dcr: {s}\n", .{vptx_slice});
    // Caesar
    try stdout.print("MOD    : ", .{});
    // Output Caesar ciphertext as a string of hex digits
    for (cctx_slice) |ch| try stdout.print("{X:0>2}", .{ch});
    try stdout.writeByte('\n');
    // Output Caesar decrypted plaintext
    try stdout.print("MOD dcr: {s}\n", .{cptx_slice});

    try stdout.flush();
}
// Output:
// Message: a Top Secret secret
// Key    : this is my secret key
// XOR    : 1C0636190B1260233B35125F1E1D0E2F4C5422
// XOR dcr: a Top Secret secret
// MOD    : 734270227D36772A783B4F2A5F206266236978
// MOD dcr: a Top Secret secret
