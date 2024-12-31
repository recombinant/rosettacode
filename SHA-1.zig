// https://rosettacode.org/wiki/SHA-1
const std = @import("std");
const Sha1 = std.crypto.hash.Sha1;

pub fn main() void {
    const s = "Rosetta Code";
    var digest: [Sha1.digest_length]u8 = undefined;
    Sha1.hash(s, digest[0..], .{});

    std.debug.print("    String : {s}\n", .{s});
    std.debug.print("SHA-1 Hash : {s}\n", .{std.fmt.bytesToHex(digest, .lower)});
}
