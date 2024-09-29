// https://rosettacode.org/wiki/Validate_International_Securities_Identification_Number
const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

pub fn main() !void {
    const tests = [_][]const u8{
        "US0378331005",  "US0373831005", "U50378331005",
        "US03378331005", "AU0000XVGZA3", "AU0000VXGZA3",
        "FR0000988040",
    };
    for (tests) |isin| {
        validateISIN(isin) catch |err| {
            const msg: []const u8 = switch (err) {
                ValidationError.WrongLength => "wrong length",
                ValidationError.InvalidCountryCode => "invalid country code",
                ValidationError.InvalidChecksumCharacter => "invalid checksum character",
                ValidationError.InvalidCodeCharacter => "invalid character in code",
                ValidationError.ChecksumError => "checksum error",
            };
            print("{s} is not valid - {s}\n", .{ isin, msg });
            continue;
        };
        print("{s} is valid\n", .{isin});
    }
}

fn luhn(s: []const u8) bool {
    const m = [_]u16{ 0, 2, 4, 6, 8, 1, 3, 5, 7, 9 };
    var sum: u16 = 0;
    var odd = true;
    var i = s.len;
    while (i != 0) {
        i -= 1;
        const digit = s[i] & 0x0f;
        sum += if (odd) digit else m[digit];
        odd = !odd;
    }
    return sum % 10 == 0;
}

const ValidationError = error{
    WrongLength,
    InvalidCountryCode,
    InvalidChecksumCharacter,
    InvalidCodeCharacter,
    ChecksumError,
};

/// Returns an error is the ISIN is not valid
fn validateISIN(s: []const u8) ValidationError!void {
    if (s.len != 12)
        return ValidationError.WrongLength;
    if (!std.ascii.isUpper(s[0]) or !std.ascii.isUpper(s[1]))
        return ValidationError.InvalidCountryCode;
    if (!std.ascii.isDigit(s[11]))
        return ValidationError.InvalidChecksumCharacter;

    // buffer with enough space to hold two characters per `s` character
    var buffer: [12 * 2]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    var array_list = std.ArrayList(u8).initCapacity(allocator, buffer.len) catch unreachable;
    // defer array_list.deinit(); // not required - buffer is on stack
    var writer = array_list.writer();

    for (s) |ch| {
        switch (ch) {
            '0'...'9' => array_list.append(ch) catch unreachable,
            'A'...'Z' => writer.print("{d}", .{ch - 'A' + 10}) catch unreachable,
            else => return ValidationError.InvalidCodeCharacter,
        }
    }

    if (!luhn(array_list.items))
        return ValidationError.ChecksumError;
}

test "validate ISIN" {
    try validateISIN("US0378331005");
    try testing.expectError(ValidationError.ChecksumError, validateISIN("US0373831005"));
    try testing.expectError(ValidationError.InvalidCountryCode, validateISIN("U50378331005"));
    try testing.expectError(ValidationError.WrongLength, validateISIN("US03378331005"));
    try validateISIN("AU0000XVGZA3");
    try validateISIN("AU0000VXGZA3");
    try validateISIN("FR0000988040");
}
