// https://rosettacode.org/wiki/Bifid_cipher
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var gpa: std.heap.DebugAllocator(.{}) = .init;
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
    try stdout.flush();
}

const Bifid = struct {
    polybius: *const [25:0]u8,

    fn encrypt(self: *const Bifid, allocator: std.mem.Allocator, message: []const u8) ![]const u8 {
        var encrypted: std.ArrayList(u8) = try .initCapacity(allocator, message.len);

        var converted = blk: {
            var x: std.ArrayList(u5) = try .initCapacity(allocator, 2 * message.len);
            var y: std.ArrayList(u5) = try .initCapacity(allocator, message.len);
            defer y.deinit(allocator);
            for (message) |c| {
                const up = std.ascii.toUpper(c);
                const possible_idx = std.mem.indexOfScalar(u8, self.polybius, if (up == 'J') 'I' else up);
                if (possible_idx) |idx| {
                    try x.append(allocator, @as(u5, @truncate(@divTrunc(idx, 5))));
                    try y.append(allocator, @as(u5, @truncate(@rem(idx, 5))));
                }
            }
            try x.appendSlice(allocator, y.items);
            break :blk x;
        };
        defer converted.deinit(allocator);

        std.mem.reverse(u5, converted.items); // to use pop()
        while (converted.items.len != 0) {
            const row = converted.pop().?;
            const col = converted.pop().?;
            const c = self.polybius[col + row * 5];
            try encrypted.append(allocator, c);
        }
        return try encrypted.toOwnedSlice(allocator);
    }

    fn decrypt(self: *const Bifid, allocator: std.mem.Allocator, message: []const u8) ![]const u8 {
        var decrypted: std.ArrayList(u8) = try .initCapacity(allocator, message.len);

        var collected: std.ArrayList(u5) = try .initCapacity(allocator, 2 * message.len);
        for (message) |c| {
            const idx = std.mem.indexOfScalar(u8, self.polybius, std.ascii.toUpper(c)).?;
            try collected.append(allocator, @as(u5, @truncate(@divTrunc(idx, 5))));
            try collected.append(allocator, @as(u5, @truncate(@rem(idx, 5))));
        }
        const slice = try collected.toOwnedSlice(allocator);
        defer allocator.free(slice);
        const rows = slice[0 .. slice.len / 2];
        const cols = slice[slice.len / 2 ..];

        for (rows, cols) |row, col|
            try decrypted.append(allocator, self.polybius[col + row * 5]);

        return try decrypted.toOwnedSlice(allocator);
    }
};
