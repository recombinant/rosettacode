// https://rosettacode.org/wiki/Bifid_cipher
const std = @import("std");
const ascii = std.ascii;
const mem = std.mem;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const poly1: *const [25:0]u8 = "ABCDEFGHIKLMNOPQRSTUVWXYZ";
    const poly2: *const [25:0]u8 = "BGWKZQPNDSIOAXEFCLUMTHYVR";
    const poly3: *const [25:0]u8 = "PLAYFIREXMBCDGHKNOQSTUVWZ";
    const polys = [_]*const [25:0]u8{ poly1, poly2, poly2, poly3 };
    const msg1: []const u8 = "ATTACKATDAWN";
    const msg2: []const u8 = "FLEEATONCE";
    const msg3: []const u8 = "The invasion will start on the first of January";
    const msgs = [_][]const u8{ msg1, msg2, msg1, msg3 };
    for (0..polys.len) |i| {
        const bifid = Bifid{ .polybius = polys[i] };
        const encrypted = try bifid.encrypt(allocator, msgs[i]);
        const decrypted = try bifid.decrypt(allocator, encrypted);
        defer allocator.free(encrypted);
        defer allocator.free(decrypted);
        try stdout.print("Message   : {s}\n", .{msgs[i]});
        try stdout.print("Encrypted : {s}\n", .{encrypted});
        try stdout.print("Decrypted : {s}\n", .{decrypted});
        if (i != polys.len - 1) try stdout.writeByte('\n');
    }
}

const Bifid = struct {
    polybius: *const [25:0]u8,

    fn encrypt(self: *const Bifid, allocator: mem.Allocator, message: []const u8) ![]const u8 {
        var encrypted = try std.ArrayList(u8).initCapacity(allocator, message.len);

        var converted = blk: {
            var x = try std.ArrayList(u5).initCapacity(allocator, 2 * message.len);
            var y = try std.ArrayList(u5).initCapacity(allocator, message.len);
            defer y.deinit();
            for (message) |c| {
                const up = ascii.toUpper(c);
                const possible_idx = mem.indexOfScalar(u8, self.polybius, if (up == 'J') 'I' else up);
                if (possible_idx) |idx| {
                    try x.append(@as(u5, @truncate(@divTrunc(idx, 5))));
                    try y.append(@as(u5, @truncate(@rem(idx, 5))));
                }
            }
            try x.appendSlice(y.items);
            break :blk x;
        };
        defer converted.deinit();

        mem.reverse(u5, converted.items); // to use pop()
        while (converted.items.len != 0) {
            const row = converted.pop();
            const col = converted.pop();
            const c = self.polybius[col + row * 5];
            try encrypted.append(c);
        }
        return try encrypted.toOwnedSlice();
    }

    fn decrypt(self: *const Bifid, allocator: mem.Allocator, message: []const u8) ![]const u8 {
        var decrypted = try std.ArrayList(u8).initCapacity(allocator, message.len);

        var collected = try std.ArrayList(u5).initCapacity(allocator, 2 * message.len);
        for (message) |c| {
            const idx = mem.indexOfScalar(u8, self.polybius, ascii.toUpper(c)).?;
            try collected.append(@as(u5, @truncate(@divTrunc(idx, 5))));
            try collected.append(@as(u5, @truncate(@rem(idx, 5))));
        }
        const slice = try collected.toOwnedSlice();
        defer allocator.free(slice);
        const rows = slice[0 .. slice.len / 2];
        const cols = slice[slice.len / 2 ..];

        for (rows, cols) |row, col|
            try decrypted.append(self.polybius[col + row * 5]);

        return try decrypted.toOwnedSlice();
    }
};
