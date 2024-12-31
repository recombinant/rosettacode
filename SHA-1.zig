// https://rosettacode.org/wiki/SHA-1
const std = @import("std");
const Sha1 = std.crypto.hash.Sha1;

pub fn main() void {
    var digest: [Sha1.digest_length]u8 = undefined;

    const s1 = "Rosetta code";
    Sha1.hash(s1, digest[0..], .{});

    std.debug.print("    String : {s}\n", .{s1});
    std.debug.print("SHA-1 Hash : {s}\n", .{std.fmt.bytesToHex(digest, .lower)});

    std.debug.print("\n", .{});

    const s2 = "Rosetta Code";
    Sha1.hash(s2, digest[0..], .{});

    std.debug.print("    String : {s}\n", .{s2});
    std.debug.print("SHA-1 Hash : {s}\n", .{std.fmt.bytesToHex(digest, .lower)});
}
