// https://rosettacode.org/wiki/SHA-256
// {{works with|Zig|0.15.1}}
const std = @import("std");
const Sha256 = std.crypto.hash.sha2.Sha256;

pub fn main() void {
    var digest: [Sha256.digest_length]u8 = undefined;

    const s = "Rosetta code";
    Sha256.hash(s, digest[0..], .{});

    std.debug.print("      String : {s}\n", .{s});
    std.debug.print("SHA-256 Hash : {s}\n", .{std.fmt.bytesToHex(digest, .lower)});
}
